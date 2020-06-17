/**
 * Copyright 2017-2020, bZeroX, LLC. All Rights Reserved.
 * Licensed under the Apache License, Version 2.0.
 */

pragma solidity 0.5.17;
pragma experimental ABIEncoderV2;

import "./AdvancedToken.sol";
import "./ProtocolLike.sol";
import "./FeedsLike.sol";


contract LegacyBZxObjects {
    struct LoanOrder {
        address loanTokenAddress;
        address interestTokenAddress;
        address collateralTokenAddress;
        address oracleAddress;
        uint256 loanTokenAmount;
        uint256 interestAmount;
        uint256 initialMarginAmount;
        uint256 maintenanceMarginAmount;
        uint256 maxDurationUnixTimestampSec;
        bytes32 loanOrderHash;
    }

    struct LoanPosition {
        address trader;
        address collateralTokenAddressFilled;
        address positionTokenAddressFilled;
        uint256 loanTokenAmountFilled;
        uint256 loanTokenAmountUsed;
        uint256 collateralTokenAmountFilled;
        uint256 positionTokenAmountFilled;
        uint256 loanStartUnixTimestampSec;
        uint256 loanEndUnixTimestampSec;
        bool active;
        uint256 positionId;
    }
}

interface LegacyBZxLike {
    function payInterestForOracle(
        address oracleAddress,
        address interestTokenAddress)
        external
        returns (uint256);

    function getLenderInterestForOracle(
        address lender,
        address oracleAddress,
        address interestTokenAddress)
        external
        view
        returns (
            uint256 interestPaid,
            uint256 interestPaidDate,
            uint256 interestOwedPerDay,
            uint256 interestUnPaid);
}

contract LoanTokenLogicStandard is AdvancedToken {
    using SafeMath for uint256;

    address internal target_;

    uint256 public constant VERSION = 5;
    address internal constant arbitraryCaller = 0x000F400e6818158D541C3EBE45FE3AA0d47372FF;

    function()
        external
    {
        revert("fallback not allowed");
    }


    /* Public functions */

    function mint(
        address receiver,
        uint256 depositAmount)
        external
        nonReentrant
        returns (uint256 mintAmount)
    {
        return _mintToken(
            receiver,
            depositAmount
        );
    }

    function burn(
        address receiver,
        uint256 burnAmount)
        external
        nonReentrant
        returns (uint256 loanAmountPaid)
    {
        loanAmountPaid = _burnToken(
            burnAmount
        );

        if (loanAmountPaid != 0) {
            _safeTransfer(loanTokenAddress, receiver, loanAmountPaid, "5");
        }
    }

    function flashBorrow(
        uint256 borrowAmount,
        address borrower,
        address target,
        string calldata signature,
        bytes calldata data)
        external
        payable
        nonReentrant
        returns (bytes memory)
    {
        _checkPause();

        _settleInterest();

        // save before balances
        uint256 beforeEtherBalance = address(this).balance.sub(msg.value);
        uint256 beforeAssetsBalance = _underlyingBalance()
            .add(totalAssetBorrows());

        // lock totalAssetSupply for duration of flash loan
        burntTokenReserved = beforeAssetsBalance;

        // transfer assets to calling contract
        if (borrowAmount != 0) {
            _safeTransfer(loanTokenAddress, borrower, borrowAmount, "39");
        }

        bytes memory callData;
        if (bytes(signature).length == 0) {
            callData = data;
        } else {
            callData = abi.encodePacked(bytes4(keccak256(bytes(signature))), data);
        }

        // arbitrary call
        (bool success, bytes memory returnData) = arbitraryCaller.call.value(msg.value)(
            abi.encodeWithSelector(
                0xde064e0d, // sendCall(address,bytes)
                target,
                callData
            )
        );
        require(success, "call failed");

        // unlock totalAssetSupply
        burntTokenReserved = 0;

        // verifies return of flash loan
        require(
            address(this).balance >= beforeEtherBalance &&
            _underlyingBalance()
                .add(totalAssetBorrows()) >= beforeAssetsBalance,
            "40"
        );

        return returnData;
    }

    // ***** NOTE: Reentrancy is allowed here to allow flashloan use cases *****
    function borrow(
        bytes32 loanId,                 // 0 if new loan
        uint256 withdrawAmount,
        uint256 initialLoanDuration,    // duration in seconds
        uint256 collateralTokenSent,    // if 0, loanId must be provided; any ETH sent must equal this value
        address collateralTokenAddress, // if address(0), this means ETH and ETH must be sent with the call or loanId must be provided
        address borrower,
        address receiver,
        bytes memory /*loanDataBytes*/) // arbitrary order data (for future use)
        public
        payable
        returns (uint256, uint256) // returns new principal and new collateral added to loan
    {
        require(withdrawAmount != 0, "6");

        _checkPause();

        require(msg.value == 0 || msg.value == collateralTokenSent, "7");
        require(collateralTokenSent != 0 || loanId != 0, "8");
        require(collateralTokenAddress != address(0) || msg.value != 0 || loanId != 0, "9");

        if (collateralTokenAddress == address(0)) {
            collateralTokenAddress = wethToken;
        }
        require(collateralTokenAddress != loanTokenAddress, "10");

        _settleInterest();

        uint256[5] memory sentAmounts;

        sentAmounts[1] = withdrawAmount;

        // interestRate, interestInitialAmount, borrowAmount (newBorrowAmount)
        (sentAmounts[0], sentAmounts[2], sentAmounts[1]) = _getInterestRateAndBorrowAmount(
            sentAmounts[1],
            _totalAssetSupplies(0), // interest is settled above
            initialLoanDuration
        );

        return _borrowOrTrade(
            loanId,
            withdrawAmount,
            2 * 10**18, // leverageAmount (translates to 150% margin for a Torque loan)
            collateralTokenAddress,
            [
                address(this), // lender
                borrower,
                receiver,
                address(0) // manager
            ],
            [
                sentAmounts[0],         // interestRate
                sentAmounts[1],
                sentAmounts[2],         // interestInitialAmount
                0,                      // loanTokenSent
                collateralTokenSent
            ],
            ""                          // loanDataBytes
        );
    }

    // Called to borrow and immediately get into a positions
    // ***** NOTE: Reentrancy is allowed here to allow flashloan use cases *****
    function marginTrade(
        bytes32 loanId,                 // 0 if new loan
        uint256 leverageAmount,
        uint256 loanTokenSent,
        uint256 collateralTokenSent,
        address collateralTokenAddress,
        address trader,
        bytes memory loanDataBytes)     // arbitrary order data
        public
        payable
        returns (uint256, uint256) // returns new principal and new collateral added to trade
    {
        _checkPause();

        if (collateralTokenAddress == address(0)) {
            collateralTokenAddress = wethToken;
        }
        require(collateralTokenAddress != loanTokenAddress, "11");

        uint256 totalDeposit = _totalDeposit(
            collateralTokenAddress,
            collateralTokenSent,
            loanTokenSent
        );
        require(totalDeposit != 0, "12");

        address[4] memory sentAddresses;
        uint256[5] memory sentAmounts;

        sentAddresses[0] = address(this); // lender
        sentAddresses[1] = trader;
        sentAddresses[2] = trader;
        //sentAddresses[3] = address(0); // manager

        //sentAmounts[0] = 0; // interestRate (found later)
        sentAmounts[1] = totalDeposit; // total amount of deposit
        //sentAmounts[2] = 0; // interestInitialAmount (interest is calculated based on fixed-term loan)
        sentAmounts[3] = loanTokenSent;
        sentAmounts[4] = collateralTokenSent;

        _settleInterest();

        (sentAmounts[1], sentAmounts[0]) = _getMarginBorrowAmountAndRate( // borrowAmount, interestRate
            leverageAmount,
            sentAmounts[1] // depositAmount
        );

        return _borrowOrTrade(
            loanId,
            0, // withdrawAmount
            leverageAmount,
            collateralTokenAddress,
            sentAddresses,
            sentAmounts,
            loanDataBytes
        );
    }

    function transfer(
        address _to,
        uint256 _value)
        external
        returns (bool)
    {
        return _internalTransferFrom(
            msg.sender,
            _to,
            _value,
            uint256(-1)
        );
    }

    function transferFrom(
        address _from,
        address _to,
        uint256 _value)
        external
        returns (bool)
    {
        return _internalTransferFrom(
            _from,
            _to,
            _value,
            ProtocolLike(bZxContract).isLoanPool(msg.sender) ?
                uint256(-1) :
                allowed[_from][msg.sender]
        );
    }

    function _internalTransferFrom(
        address _from,
        address _to,
        uint256 _value,
        uint256 _allowanceAmount)
        internal
        returns (bool)
    {
        if (_allowanceAmount != uint256(-1)) {
            require(_value <= _allowanceAmount, "14");
            allowed[_from][msg.sender] = _allowanceAmount.sub(_value);
        }

        uint256 _balancesFrom = balances[_from];
        uint256 _balancesTo = balances[_to];

        require(_value <= _balancesFrom &&
            _to != address(0),
            "14"
        );

        uint256 _balancesFromNew = _balancesFrom
            .sub(_value);
        balances[_from] = _balancesFromNew;

        uint256 _balancesToNew = _balancesTo
            .add(_value);
        balances[_to] = _balancesToNew;

        // handle checkpoint update
        uint256 _currentPrice = tokenPrice();

        _updateCheckpoints(
            _from,
            _balancesFrom,
            _balancesFromNew,
            _currentPrice
        );
        _updateCheckpoints(
            _to,
            _balancesTo,
            _balancesToNew,
            _currentPrice
        );

        emit Transfer(_from, _to, _value);
        return true;
    }

    event Debug(
        bytes32 slot,
        uint256 one,
        uint256 two
    );

    function _updateCheckpoints(
        address _user,
        uint256 _oldBalance,
        uint256 _newBalance,
        uint256 _currentPrice)
        internal
    {
        // keccak256("iToken_ProfitSoFar")
        bytes32 slot = keccak256(
            abi.encodePacked(_user, uint256(0x37aa2b7d583612f016e4a4de4292cb015139b3d7762663d06a53964912ea2fb6))
        );

        uint256 _currentProfit;
        if (_oldBalance != 0 && _newBalance != 0) {
            _currentProfit = _profitOf(
                slot,
                _oldBalance,
                _currentPrice,
                checkpointPrices_[_user]
            );
        } else if (_newBalance == 0) {
            _currentPrice = 0;
        }

        assembly {
            sstore(slot, _currentProfit)
        }

        checkpointPrices_[_user] = _currentPrice;

        emit Debug(
            slot,
            _currentProfit,
            _currentPrice
        );
    }

    /* Public View functions */

    function profitOf(
        address user)
        public
        view
        returns (uint256)
    {
        // keccak256("iToken_ProfitSoFar")
        bytes32 slot = keccak256(
            abi.encodePacked(user, uint256(0x37aa2b7d583612f016e4a4de4292cb015139b3d7762663d06a53964912ea2fb6))
        );

        return _profitOf(
            slot,
            balances[user],
            tokenPrice(),
            checkpointPrices_[user]
        );
    }

    function _profitOf(
        bytes32 slot,
        uint256 _balance,
        uint256 _currentPrice,
        uint256 _checkpointPrice)
        internal
        view
        returns (uint256)
    {
        if (_checkpointPrice == 0) {
            return 0;
        }

        uint256 profitSoFar;
        uint256 profitDiff;

        assembly {
            profitSoFar := sload(slot)
        }

        if (_currentPrice > _checkpointPrice) {
            profitDiff = _balance
                .mul(_currentPrice - _checkpointPrice)
                .div(10**18);
            profitSoFar = profitSoFar
                .add(profitDiff);
        } else {
            profitDiff = _balance
                .mul(_checkpointPrice - _currentPrice)
                .div(10**18);
            if (profitSoFar > profitDiff) {
                profitSoFar = profitSoFar - profitDiff;
            } else {
                profitSoFar = 0;
            }
        }

        return profitSoFar;
    }

    function tokenPrice()
        public
        view
        returns (uint256 price)
    {
        uint256 interestUnPaid;
        if (lastSettleTime_ != block.timestamp) {
            (,interestUnPaid) = _getAllInterest();
        }

        return _tokenPrice(_totalAssetSupplies(interestUnPaid));
    }

    function checkpointPrice(
        address _user)
        public
        view
        returns (uint256 price)
    {
        return checkpointPrices_[_user];
    }

    function marketLiquidity()
        public
        view
        returns (uint256)
    {
        uint256 totalSupply = _totalAssetSupplies(0);
        uint256 totalBorrow = totalAssetBorrows();
        if (totalSupply > totalBorrow) {
            return totalSupply.sub(totalBorrow);
        }
    }

    function avgBorrowInterestRate()
        public
        view
        returns (uint256)
    {
        return _avgBorrowInterestRate(totalAssetBorrows());
    }

    // the minimum rate the next base protocol borrower will receive for variable-rate loans
    function borrowInterestRate()
        public
        view
        returns (uint256)
    {
        return _nextBorrowInterestRate(
            0,              // borrowAmount
            false           // useFixedInterestModel
        );
    }

    function nextBorrowInterestRate(
        uint256 borrowAmount)
        public
        view
        returns (uint256)
    {
        return _nextBorrowInterestRate(
            borrowAmount,
            false           // useFixedInterestModel
        );
    }

    function nextBorrowInterestRateWithOption(
        uint256 borrowAmount,
        bool useFixedInterestModel)
        public
        view
        returns (uint256)
    {
        return _nextBorrowInterestRate(
            borrowAmount,
            useFixedInterestModel
        );
    }

    // interest that lenders are currently receiving when supplying to the pool
    function supplyInterestRate()
        public
        view
        returns (uint256)
    {
        return totalSupplyInterestRate(_totalAssetSupplies(0));
    }

    function nextSupplyInterestRate(
        uint256 supplyAmount)
        public
        view
        returns (uint256)
    {
        return totalSupplyInterestRate(_totalAssetSupplies(0).add(supplyAmount));
    }

    function totalSupplyInterestRate(
        uint256 assetSupply)
        public
        view
        returns (uint256)
    {
        uint256 assetBorrow = totalAssetBorrows();
        if (assetBorrow != 0) {
            return _supplyInterestRate(
                assetBorrow,
                assetSupply
            );
        }
    }

    function totalAssetBorrows()
        public
        view
        returns (uint256)
    {
        return ProtocolLike(bZxContract).getTotalPrincipal(
            address(this),
            loanTokenAddress
        ).add(totalAssetBorrow);
    }

    function totalAssetSupply()
        public
        view
        returns (uint256)
    {
        return totalAssetSupplies();
    }

    function totalAssetSupplies()
        public
        view
        returns (uint256)
    {
        uint256 interestUnPaid;
        if (lastSettleTime_ != block.timestamp) {
            (,interestUnPaid) = _getAllInterest();
        }

        return _totalAssetSupplies(interestUnPaid);
    }

    function getMaxEscrowAmount(
        uint256 leverageAmount)
        public
        view
        returns (uint256)
    {
        uint256 initialMargin = SafeMath.div(10**38, leverageAmount);
        return marketLiquidity()
            .mul(initialMargin)
            .div(_adjustValue(
                10**20, // maximum possible interest (100%)
                2419200, // 28 day duration for margin trades
                initialMargin));
    }

    // returns the user's balance of underlying token
    function assetBalanceOf(
        address _owner)
        public
        view
        returns (uint256)
    {
        return balanceOf(_owner)
            .mul(tokenPrice())
            .div(10**18);
    }

    function getEstimatedMarginDetails(
        uint256 leverageAmount,
        uint256 loanTokenSent,
        uint256 collateralTokenSent,
        address collateralTokenAddress)     // address(0) means ETH
        public
        view
        returns (uint256 principal, uint256 collateral, uint256 interestRate)
    {
        if (collateralTokenAddress == address(0)) {
            collateralTokenAddress = wethToken;
        }

        uint256 totalDeposit = _totalDeposit(
            collateralTokenAddress,
            collateralTokenSent,
            loanTokenSent
        );

        (principal, interestRate) = _getMarginBorrowAmountAndRate(
            leverageAmount,
            totalDeposit
        );
        if (principal > _underlyingBalance()) {
            return (0, 0, 0);
        }

        loanTokenSent = loanTokenSent
            .add(principal);

        collateral = ProtocolLike(bZxContract).getEstimatedMarginExposure(
            loanTokenAddress,
            collateralTokenAddress,
            loanTokenSent,
            collateralTokenSent,
            interestRate,
            principal
        );
    }

    function getDepositAmountForBorrow(
        uint256 borrowAmount,
        uint256 initialLoanDuration,        // duration in seconds
        address collateralTokenAddress)     // address(0) means ETH
        public
        view
        returns (uint256 depositAmount)
    {
        if (borrowAmount != 0) {
            // adjust value since interest is also borrowed
            borrowAmount = borrowAmount
                .mul(_getTargetNextRateMultiplierValue(initialLoanDuration))
                .div(10**22);

            if (borrowAmount <= _underlyingBalance()) {
                return ProtocolLike(bZxContract).getRequiredCollateral(
                    loanTokenAddress,
                    collateralTokenAddress != address(0) ? collateralTokenAddress : wethToken,
                    borrowAmount,
                    50 * 10**18, // initialMargin
                    true // isTorqueLoan
                ).add(10); // some dust to compensate for rounding errors
            }
        }
    }

    function getBorrowAmountForDeposit(
        uint256 depositAmount,
        uint256 initialLoanDuration,        // duration in seconds
        address collateralTokenAddress)     // address(0) means ETH
        public
        view
        returns (uint256 borrowAmount)
    {
        if (depositAmount != 0) {
            borrowAmount = ProtocolLike(bZxContract).getBorrowAmount(
                loanTokenAddress,
                collateralTokenAddress != address(0) ? collateralTokenAddress : wethToken,
                depositAmount,
                50 * 10**18, // initialMargin,
                true // isTorqueLoan
            );

            // adjust value since interest is also borrowed
            borrowAmount = borrowAmount
                .mul(10**22)
                .div(_getTargetNextRateMultiplierValue(initialLoanDuration));

            if (borrowAmount > _underlyingBalance()) {
                borrowAmount = 0;
            }
        }
    }


    /* Internal functions */

    function _mintToken(
        address receiver,
        uint256 depositAmount)
        internal
        returns (uint256 mintAmount)
    {
        require (depositAmount != 0, "17");

        _settleInterest();

        uint256 currentPrice = _tokenPrice(_totalAssetSupplies(0));
        mintAmount = depositAmount
            .mul(10**18)
            .div(currentPrice);

        if (msg.value == 0) {
            _safeTransferFrom(loanTokenAddress, msg.sender, address(this), depositAmount, "18");
        } else {
            IWeth(wethToken).deposit.value(depositAmount)();
        }

        uint256 oldBalance = balances[receiver];
        _updateCheckpoints(
            receiver,
            oldBalance,
            _mint(receiver, mintAmount, depositAmount, currentPrice), // newBalance
            currentPrice
        );
    }

    function _burnToken(
        uint256 burnAmount)
        internal
        returns (uint256 loanAmountPaid)
    {
        require(burnAmount != 0, "19");

        if (burnAmount > balanceOf(msg.sender)) {
            burnAmount = balanceOf(msg.sender);
        }

        _settleInterest();

        uint256 currentPrice = _tokenPrice(_totalAssetSupplies(0));

        uint256 loanAmountOwed = burnAmount
            .mul(currentPrice)
            .div(10**18);
        uint256 loanAmountAvailableInContract = _underlyingBalance();

        loanAmountPaid = loanAmountOwed;
        require(loanAmountPaid <= loanAmountAvailableInContract, "37");

        uint256 oldBalance = balances[msg.sender];
        _updateCheckpoints(
            msg.sender,
            oldBalance,
            _burn(msg.sender, burnAmount, loanAmountPaid, currentPrice), // newBalance
            currentPrice
        );
    }

    function _settleInterest()
        internal
    {
        if (lastSettleTime_ != block.timestamp) {
            ProtocolLike(bZxContract).withdrawAccruedInterest(
                loanTokenAddress
            );

            // legacy interest handling
            _getLegacyProtocol().payInterestForOracle(
                bZxOracle,
                loanTokenAddress
            );

            lastSettleTime_ = block.timestamp;
        }
    }

    function _totalDeposit(
        address collateralTokenAddress,
        uint256 collateralTokenSent,
        uint256 loanTokenSent)
        internal
        view
        returns (uint256 totalDeposit)
    {
        totalDeposit = loanTokenSent;
        if (collateralTokenSent != 0) {
            (uint256 sourceToDestRate, uint256 sourceToDestPrecision) = FeedsLike(ProtocolLike(bZxContract).priceFeeds()).queryRate(
                collateralTokenAddress,
                loanTokenAddress
            );
            if (sourceToDestPrecision != 0) {
                totalDeposit = collateralTokenSent
                    .mul(sourceToDestRate)
                    .div(sourceToDestPrecision)
                    .add(totalDeposit);
            }
        }
    }

    function _getTargetNextRateMultiplierValue(
        uint256 initialLoanDuration)
        internal
        view
        returns (uint256)
    {
        uint256 thisBaseRate;
        uint256 thisRateMultiplier;
        //keccak256("iToken_FixedInterestBaseRate")
        //keccak256("iToken_FixedInterestRateMultiplier")
        assembly {
            thisBaseRate := sload(0x185a40c6b6d3f849f72c71ea950323d21149c27a9d90f7dc5e5ea2d332edcf7f)
            thisRateMultiplier := sload(0x9ff54bc0049f5eab56ca7cd14591be3f7ed6355b856d01e3770305c74a004ea2)
        }

        return thisRateMultiplier
            .mul(80 ether)
            .div(10**20)
            .add(thisBaseRate)
            .mul(initialLoanDuration)
            .div(315360) // 365 * 86400 / 100
            .add(10**22);
    }

    function _getInterestRateAndBorrowAmount(
        uint256 borrowAmount,
        uint256 assetSupply,
        uint256 initialLoanDuration) // duration in seconds
        internal
        view
        returns (uint256 interestRate, uint256 interestInitialAmount, uint256 newBorrowAmount)
    {
        interestRate = _nextBorrowInterestRate2(
            borrowAmount,
            assetSupply,
            true // useFixedInterestModel
        );

        // newBorrowAmount = borrowAmount * 10^18 / (10^18 - interestRate * 7884000 * 10^18 / 31536000 / 10^20)
        newBorrowAmount = borrowAmount
            .mul(10**18)
            .div(
                SafeMath.sub(10**18,
                    interestRate
                        .mul(initialLoanDuration)
                        .mul(10**18)
                        .div(31536000 * 10**20) // 365 * 86400 * 10**20
                )
            );

        interestInitialAmount = newBorrowAmount
            .sub(borrowAmount);
    }

    // returns newPrincipal
    function _borrowOrTrade(
        bytes32 loanId,
        uint256 withdrawAmount,
        uint256 leverageAmount,
        address collateralTokenAddress,
        address[4] memory sentAddresses,
        uint256[5] memory sentAmounts,
        bytes memory loanDataBytes)
        internal
        returns (uint256, uint256)
    {
        _checkPause();

        require (sentAmounts[1] <= _underlyingBalance() && // newPrincipal
            sentAddresses[1] != address(0), // borrower
            "24"
        );

	    if (sentAddresses[2] == address(0)) {
            sentAddresses[2] = sentAddresses[1]; // receiver = borrower
        }

        // handle transfers prior to adding newPrincipal to loanTokenSent
        _verifyTransfers(
            collateralTokenAddress,
            sentAddresses,
            sentAmounts,
            withdrawAmount
        );

        // adding the loan token portion from the lender to loanTokenSent
        sentAmounts[3] = sentAmounts[3]
            .add(sentAmounts[1]); // newPrincipal

        if (withdrawAmount != 0) {
            // withdrawAmount already sent to the borrower, so we aren't sending it to the protocol
            sentAmounts[3] = sentAmounts[3]
                .sub(withdrawAmount);
        }

        uint256 msgValue;
        if (msg.value != 0) {
            msgValue = address(this).balance;
            if (msgValue > msg.value) {
                msgValue = msg.value;
            }
        }

        bytes32 loanParamsId = loanOrderHashes[uint256(keccak256(abi.encodePacked(
            collateralTokenAddress,
            withdrawAmount != 0 ? // isTorqueLoan
                true :
                false
        )))];

        // converting to initialMargin
        leverageAmount = SafeMath.div(10**38, leverageAmount);

        (sentAmounts[1], sentAmounts[4]) = ProtocolLike(bZxContract).borrowOrTradeFromPool.value(msgValue)( // newPrincipal, newCollateral
            loanParamsId,
            loanId,
            withdrawAmount != 0 ? // isTorqueLoan
                true :
                false,
            leverageAmount, // initialMargin
            sentAddresses,
            sentAmounts,
            loanDataBytes
        );
        require (sentAmounts[1] != 0, "25");

        return (sentAmounts[1], sentAmounts[4]); // newPrincipal, newCollateral
    }

    // sentAddresses[0]: lender
    // sentAddresses[1]: borrower
    // sentAddresses[2]: receiver
    // sentAddresses[3]: manager
    // sentAmounts[0]: interestRate
    // sentAmounts[1]: newPrincipal
    // sentAmounts[2]: interestInitialAmount
    // sentAmounts[3]: loanTokenSent
    // sentAmounts[4]: collateralTokenSent
    function _verifyTransfers(
        address collateralTokenAddress,
        address[4] memory sentAddresses,
        uint256[5] memory sentAmounts,
        uint256 withdrawalAmount)
        internal
    {
        address _wethToken = wethToken;
        address _loanTokenAddress = loanTokenAddress;
        address receiver = sentAddresses[2];
        uint256 newPrincipal = sentAmounts[1];
        uint256 loanTokenSent = sentAmounts[3];
        uint256 collateralTokenSent = sentAmounts[4];

        require(_loanTokenAddress != collateralTokenAddress, "26");

        if (withdrawalAmount != 0) { // withdrawOnOpen == true
            _safeTransfer(_loanTokenAddress, receiver, withdrawalAmount, "");
            if (newPrincipal > withdrawalAmount) {
                _safeTransfer(_loanTokenAddress, bZxContract, newPrincipal - withdrawalAmount, "");
            }
        } else {
            _safeTransfer(_loanTokenAddress, bZxContract, newPrincipal, "27");
        }

        if (collateralTokenSent != 0) {
            if (collateralTokenAddress == _wethToken && msg.value != 0 && msg.value >= collateralTokenSent) {
                IWeth(_wethToken).deposit.value(collateralTokenSent)();
                _safeTransfer(collateralTokenAddress, bZxContract, collateralTokenSent, "28");
            } else {
                _safeTransferFrom(collateralTokenAddress, msg.sender, bZxContract, collateralTokenSent, "28");
            }
        }

        if (loanTokenSent != 0) {
            _safeTransferFrom(_loanTokenAddress, msg.sender, bZxContract, loanTokenSent, "29");
        }
    }

    function _safeTransfer(
        address token,
        address to,
        uint256 amount,
        string memory errorMsg)
        internal
    {
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(IERC20(token).transfer.selector, to, amount),
            errorMsg
        );
    }

    function _safeTransferFrom(
        address token,
        address from,
        address to,
        uint256 amount,
        string memory errorMsg)
        internal
    {
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(IERC20(token).transferFrom.selector, from, to, amount),
            errorMsg
        );
    }

    function _callOptionalReturn(
        address token,
        bytes memory data,
        string memory errorMsg)
        internal
    {
        (bool success, bytes memory returndata) = token.call(data);
        require(success, errorMsg);

        if (returndata.length != 0) {
            require(abi.decode(returndata, (bool)), errorMsg);
        }
    }

    function _underlyingBalance()
        internal
        view
        returns (uint256)
    {
        return IERC20(loanTokenAddress).balanceOf(address(this));
    }

    /* Internal View functions */

    function _tokenPrice(
        uint256 assetSupply)
        internal
        view
        returns (uint256)
    {
        uint256 totalTokenSupply = totalSupply_;

        return totalTokenSupply != 0 ?
            assetSupply
                .mul(10**18)
                .div(totalTokenSupply) : initialPrice;
    }

    function _avgBorrowInterestRate(
        uint256 assetBorrow)
        internal
        view
        returns (uint256)
    {
        if (assetBorrow != 0) {
            (uint256 interestOwedPerDay,) = _getAllInterest();
            return interestOwedPerDay
                .mul(10**20)
                .div(assetBorrow)
                .mul(365);
        }
    }

    // next supply interest adjustment
    function _supplyInterestRate(
        uint256 assetBorrow,
        uint256 assetSupply)
        public
        view
        returns (uint256)
    {
        if (assetBorrow != 0 && assetSupply >= assetBorrow) {
            return _avgBorrowInterestRate(assetBorrow)
                .mul(_utilizationRate(assetBorrow, assetSupply))
                .mul(spreadMultiplier)
                .div(10**40);
        }
    }

    function _nextBorrowInterestRate(
        uint256 borrowAmount,
        bool useFixedInterestModel)
        internal
        view
        returns (uint256)
    {
        uint256 interestUnPaid;
        if (borrowAmount != 0) {
            if (lastSettleTime_ != block.timestamp) {
                (,interestUnPaid) = _getAllInterest();
            }

            uint256 balance = _underlyingBalance()
                .add(interestUnPaid);
            if (borrowAmount > balance) {
                borrowAmount = balance;
            }
        }

        return _nextBorrowInterestRate2(
            borrowAmount,
            _totalAssetSupplies(interestUnPaid),
            useFixedInterestModel
        );
    }

    function _nextBorrowInterestRate2(
        uint256 newBorrowAmount,
        uint256 assetSupply,
        bool /*useFixedInterestModel*/) // kept for legacy reasons since calling functions have the param (now always assumed "true")
        internal
        view
        returns (uint256 nextRate)
    {
        uint256 utilRate = _utilizationRate(
            totalAssetBorrows().add(newBorrowAmount),
            assetSupply
        );

        uint256 minRate;
        uint256 maxRate;
        uint256 thisBaseRate;
        uint256 thisRateMultiplier;

        /*if (useFixedInterestModel) {
            if (utilRate < 80 ether) {
                // target 80% utilization when loan is fixed-rate and utilization is under 80%
                utilRate = 80 ether;
            }

            //keccak256("iToken_FixedInterestBaseRate")
            //keccak256("iToken_FixedInterestRateMultiplier")
            assembly {
                thisBaseRate := sload(0x185a40c6b6d3f849f72c71ea950323d21149c27a9d90f7dc5e5ea2d332edcf7f)
                thisRateMultiplier := sload(0x9ff54bc0049f5eab56ca7cd14591be3f7ed6355b856d01e3770305c74a004ea2)
            }
        } else if (utilRate < 50 ether) {
            thisBaseRate = _getLowUtilBaseRate();

            //keccak256("iToken_LowUtilRateMultiplier")
            assembly {
                thisRateMultiplier := sload(0x2b4858b1bc9e2d14afab03340ce5f6c81b703c86a0c570653ae586534e095fb1)
            }
        } else {
            thisBaseRate = baseRate;
            thisRateMultiplier = rateMultiplier;
        }*/

        if (utilRate < 80 ether) {
            // target 80% utilization when loan is fixed-rate and utilization is under 80%
            utilRate = 80 ether;
        }
        //keccak256("iToken_FixedInterestBaseRate")
        //keccak256("iToken_FixedInterestRateMultiplier")
        assembly {
            thisBaseRate := sload(0x185a40c6b6d3f849f72c71ea950323d21149c27a9d90f7dc5e5ea2d332edcf7f)
            thisRateMultiplier := sload(0x9ff54bc0049f5eab56ca7cd14591be3f7ed6355b856d01e3770305c74a004ea2)
        }

        if (utilRate > 90 ether) {
            // scale rate proportionally up to 100%

            utilRate = utilRate.sub(90 ether);
            if (utilRate > 10 ether)
                utilRate = 10 ether;

            maxRate = thisRateMultiplier
                .add(thisBaseRate)
                .mul(90)
                .div(100);

            nextRate = utilRate
                .mul(SafeMath.sub(100 ether, maxRate))
                .div(10 ether)
                .add(maxRate);
        } else {
            nextRate = utilRate
                .mul(thisRateMultiplier)
                .div(10**20)
                .add(thisBaseRate);

            minRate = thisBaseRate;
            maxRate = thisRateMultiplier
                .add(thisBaseRate);

            if (nextRate < minRate)
                nextRate = minRate;
            else if (nextRate > maxRate)
                nextRate = maxRate;
        }
    }

    function _getAllInterest()
        internal
        view
        returns (
            uint256 interestOwedPerDay,
            uint256 interestUnPaid)
    {
        // interestPaid, interestPaidDate, interestOwedPerDay, interestUnPaid, principalTotal
        (,,interestOwedPerDay,interestUnPaid,) = ProtocolLike(bZxContract).getLenderInterestData(
            address(this),
            loanTokenAddress
        );

        // legacy interest handling
        (,,uint256 interestOwedPerDayExtra, uint256 interestUnPaidExtra) = _getLegacyProtocol().getLenderInterestForOracle(
            address(this),
            bZxOracle,
            loanTokenAddress
        );
        interestOwedPerDay = interestOwedPerDay
            .add(interestOwedPerDayExtra);
        interestUnPaid = interestUnPaid
            .add(interestUnPaidExtra);

        interestUnPaid = interestUnPaid
            .mul(spreadMultiplier)
            .div(10**20);
    }

    function _getLegacyProtocol()
        internal
        view
        returns (LegacyBZxLike)
    {
        //keccak256("iToken_LegacyProtocolContract")
        LegacyBZxLike bzx;
        assembly {
            bzx := sload(0xb63afa61a70d23f8df32ca45a46641070aaebe46fca63e7727aa8423b712a13d)
        }
        return bzx;
    }

    function _getMarginBorrowAmountAndRate(
        uint256 leverageAmount,
        uint256 depositAmount)
        internal
        view
        returns (uint256 borrowAmount, uint256 interestRate)
    {
        uint256 initialMargin = SafeMath.div(10**38, leverageAmount);

        interestRate = _nextBorrowInterestRate2(
            depositAmount
                .mul(10**20)
                .div(initialMargin),
            _totalAssetSupplies(0),
            false // useFixedInterestModel
        );

        // assumes that loan, collateral, and interest token are the same
        borrowAmount = depositAmount
            .mul(10**40)
            .div(_adjustValue(
                interestRate,
                2419200, // 28 day duration for margin trades
                initialMargin))
            .div(initialMargin);
    }

    function _totalAssetSupplies(
        uint256 interestUnPaid)
        internal
        view
        returns (uint256 assetSupply)
    {
        if (totalSupply_ != 0) {
            uint256 assetsBalance = burntTokenReserved; // temporary holder when flash lending
            if (assetsBalance == 0) {
                assetsBalance = _underlyingBalance()
                    .add(totalAssetBorrows());
            }

            return assetsBalance
                .add(interestUnPaid);
        }
    }

    function _getLowUtilBaseRate()
        internal
        view
        returns (uint256 lowUtilBaseRate)
    {
        //keccak256("iToken_LowUtilBaseRate")
        assembly {
            lowUtilBaseRate := sload(0x3d82e958c891799f357c1316ae5543412952ae5c423336f8929ed7458039c995)
        }
    }

    function _checkPause()
        internal
        view
    {
        //keccak256("iToken_FunctionPause")
        bytes32 slot = keccak256(abi.encodePacked(msg.sig, uint256(0xd46a704bc285dbd6ff5ad3863506260b1df02812f4f857c8cc852317a6ac64f2)));
        bool isPaused;
        assembly {
            isPaused := sload(slot)
        }
        require(!isPaused, "unauthorized");
    }

    function _adjustValue(
        uint256 interestRate,
        uint256 maxDuration,
        uint256 marginAmount)
        internal
        pure
        returns (uint256)
    {
        return maxDuration != 0 ?
            interestRate
                .mul(10**20)
                .div(31536000) // 86400 * 365
                .mul(maxDuration)
                .div(marginAmount)
                .add(10**20) :
            10**20;
    }

    function _utilizationRate(
        uint256 assetBorrow,
        uint256 assetSupply)
        internal
        pure
        returns (uint256)
    {
        if (assetBorrow != 0 && assetSupply != 0) {
            // U = total_borrow / total_supply
            return assetBorrow
                .mul(10**20)
                .div(assetSupply);
        }
    }

    // Called only by BZxOracle when a loan is partially or fully closed
    // Used for backwards compatibility with bZx v1
    function closeLoanNotifier(
        LegacyBZxObjects.LoanOrder memory,
        LegacyBZxObjects.LoanPosition memory,
        address /*loanCloser*/,
        uint256 closeAmount,
        bool /*isLiquidation*/)
        public
        returns (bool)
    {
        require(msg.sender == ProtocolLike(bZxContract).getLegacyOracle(bZxOracle), "1");

        _settleInterest();

        totalAssetBorrow = totalAssetBorrow > closeAmount ?
            totalAssetBorrow.sub(closeAmount) : 0;

        return true;
    }

    /* Owner-Only functions */

    // once the pools are migrated, patch again with this removed
    function tmpMigratePool(
        address oldBZxContract,
        address newBZxContract)
        external
        onlyOwner
    {
        bZxContract = newBZxContract;
        bZxVault = newBZxContract;

        // keccak256("iToken_LegacyProtocolContract")
        assembly {
            sstore(0xb63afa61a70d23f8df32ca45a46641070aaebe46fca63e7727aa8423b712a13d, oldBZxContract)
        }
    }

    function updateSettings(
        address settingsTarget,
        bytes memory callData)
        public
    {
        if (msg.sender != owner()) {
            address _lowerAdmin;
            address _lowerAdminContract;

            //keccak256("iToken_LowerAdminAddress")
            //keccak256("iToken_LowerAdminContract")
            assembly {
                _lowerAdmin := sload(0x7ad06df6a0af6bd602d90db766e0d5f253b45187c3717a0f9026ea8b10ff0d4b)
                _lowerAdminContract := sload(0x34b31cff1dbd8374124bd4505521fc29cab0f9554a5386ba7d784a4e611c7e31)
            }
            require(msg.sender == _lowerAdmin && settingsTarget == _lowerAdminContract);
        }

        address currentTarget = target_;
        target_ = settingsTarget;

        (bool result,) = address(this).call(callData);

        uint256 size;
        uint256 ptr;
        assembly {
            size := returndatasize
            ptr := mload(0x40)
            returndatacopy(ptr, 0, size)
            if eq(result, 0) { revert(ptr, size) }
        }

        target_ = currentTarget;

        assembly {
            return(ptr, size)
        }
    }
}
