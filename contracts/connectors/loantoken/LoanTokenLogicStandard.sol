/**
 * Copyright 2017-2022, OokiDao. All Rights Reserved.
 * Licensed under the Apache License, Version 2.0.
 */

pragma solidity 0.5.17;
pragma experimental ABIEncoderV2;

import "./AdvancedToken.sol";
import "./StorageExtension.sol";
import "../../../interfaces/IBZx.sol";
import "../../../interfaces/IPriceFeeds.sol";
import "../../mixins/Flags.sol";
import "../../interfaces/draft-IERC20Permit.sol";

contract LoanTokenLogicStandard is AdvancedToken, StorageExtension, Flags {
    using SafeMath for uint256;
    using SignedSafeMath for int256;


    //// CONSTANTS ////

    uint256 public constant VERSION = 7;

    //address internal constant arbitraryCaller = 0x000F400e6818158D541C3EBE45FE3AA0d47372FF; // mainnet
    address internal constant arbitraryCaller = 0x81e7dddFAD37E6FAb0eccE95f0B508fd40996e6d; // bsc
    // address internal constant arbitraryCaller = 0x81e7dddFAD37E6FAb0eccE95f0B508fd40996e6d; // polygon
    // address internal constant arbitraryCaller = 0x01207468F48822f8535BC96D1Cf18EddDE4A2392; // arbitrum

    //address public constant bZxContract = 0xD8Ee69652E4e4838f2531732a46d1f7F584F0b7f; // mainnet
    //address public constant wethToken = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2; // mainnet

    //address public constant bZxContract = 0x5cfba2639a3db0D9Cc264Aa27B2E6d134EeA486a; // kovan
    //address public constant wethToken = 0xd0A1E359811322d97991E03f863a0C30C2cF029C; // kovan

    address public constant bZxContract = 0xD154eE4982b83a87b0649E5a7DDA1514812aFE1f; // bsc
    address public constant wethToken = 0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c; // bsc

    // address public constant bZxContract = 0x059D60a9CEfBc70b9Ea9FFBb9a041581B1dFA6a8; // polygon
    // address public constant wethToken = 0x0d500B1d8E8eF31E21C99d1Db9A6444d3ADf1270; // polygon

    // address public constant bZxContract = 0x37407F3178ffE07a6cF5C847F8f680FEcf319FAB; // arbitrum
    // address public constant wethToken = 0x82aF49447D8a07e3bd95BD0d56f35241523fBab1; // arbitrum

    bytes32 internal constant iToken_ProfitSoFar = 0x37aa2b7d583612f016e4a4de4292cb015139b3d7762663d06a53964912ea2fb6;          // keccak256("iToken_ProfitSoFar")
    bytes32 internal constant iToken_LowerAdminAddress = 0x7ad06df6a0af6bd602d90db766e0d5f253b45187c3717a0f9026ea8b10ff0d4b;    // keccak256("iToken_LowerAdminAddress")
    bytes32 internal constant iToken_LowerAdminContract = 0x34b31cff1dbd8374124bd4505521fc29cab0f9554a5386ba7d784a4e611c7e31;   // keccak256("iToken_LowerAdminContract")

    constructor()
        public
    {
        renounceOwnership();
    }

    function()
        external
        payable
    {
        require(msg.sender == wethToken, "fallback not allowed");
    }

    /* Public functions */
    function mint(
        address receiver,
        uint256 depositAmount,
        bytes memory loanDataBytes)
        public
        returns (uint256) // mintAmount
    {  
        _checkPermit(loanTokenAddress, loanDataBytes);
        mint(receiver, depositAmount);
    }

    function mint(
        address receiver,
        uint256 depositAmount)
        public
        nonReentrant
        pausable
        returns (uint256) // mintAmount
    {
        return _mintToken(
            receiver,
            depositAmount
        );
    }

    function burn(
        address receiver,
        uint256 burnAmount)
        public
        nonReentrant
        pausable
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
        pausable
        returns (bytes memory)
    {
        require(borrowAmount != 0, "38");

        _settleInterest(0);

        // save before balances
        uint256 beforeEtherBalance = address(this).balance.sub(msg.value);
        uint256 beforeAssetsBalance = _underlyingBalance()
            .add(_totalAssetBorrowStored());

        // lock totalAssetSupply for duration of flash loan
        _flTotalAssetSupply = beforeAssetsBalance;

        // transfer assets to calling contract
        _safeTransfer(loanTokenAddress, borrower, borrowAmount, "39");

        emit FlashBorrow(borrower, target, loanTokenAddress, borrowAmount);

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
        _flTotalAssetSupply = 0;
		
		// pay flash borrow fees
        IBZx(bZxContract).payFlashBorrowFees(
            borrower,
            borrowAmount,
            flashBorrowFeePercent
        );
	
        // verifies return of flash loan
        require(
            address(this).balance >= beforeEtherBalance &&
            _underlyingBalance()
                .add(_totalAssetBorrowStored()) >= beforeAssetsBalance,
            "40"
        );

        return returnData;
    }

    function borrow(
        bytes32 loanId,                 // 0 if new loan
        uint256 withdrawAmount,
        uint256 initialLoanDuration,    // duration in seconds
        uint256 collateralTokenSent,    // if 0, loanId must be provided; any ETH sent must equal this value
        address collateralTokenAddress, // if address(0), this means ETH and ETH must be sent with the call or loanId must be provided
        address borrower,
        address receiver,
        bytes memory loanDataBytes) // arbitrary order data
        public
        payable
        nonReentrant
        pausable
        returns (IBZx.LoanOpenData memory)
    {
        return _borrow(
            loanId,
            withdrawAmount,
            initialLoanDuration,
            collateralTokenSent,
            collateralTokenAddress,
            borrower,
            receiver,
            loanDataBytes
        );
    }

    // Called to borrow and immediately get into a position
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
        nonReentrant
        pausable
        returns (IBZx.LoanOpenData memory)
    {
        return _marginTrade(
            loanId,
            leverageAmount,
            loanTokenSent,
            collateralTokenSent,
            collateralTokenAddress,
            trader,
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
            allowed[_from][msg.sender] = _allowanceAmount.sub(_value, "14");
        }

        require(_to != address(0), "15");

        uint256 _balancesFrom = balances[_from];
        uint256 _balancesFromNew = _balancesFrom
            .sub(_value, "16");
        balances[_from] = _balancesFromNew;

        uint256 _balancesTo = balances[_to];
        uint256 _balancesToNew = _balancesTo
            .add(_value);
        balances[_to] = _balancesToNew;

        emit Transfer(_from, _to, _value);
        return true;
    }

    function tokenPrice()
        public
        view
        returns (uint256) // price
    {
        return _tokenPrice(_totalAssetSupply(totalAssetBorrow()));
    }

    function checkpointPrice(
        address _user)
        public
        view
        returns (uint256) // price
    {
        return checkpointPrices_[_user];
    }

    // the current rate being paid by borrowers in active loans
    function borrowInterestRate()
        public
        view
        returns (uint256)
    {
        return _nextBorrowInterestRate(
            _totalAssetBorrowStored(),
            0,
            poolTWAI()
        );
    }

    // the minimum rate that new and existing borrowers will pay after the next borrow
    function nextBorrowInterestRate(
        uint256 borrowAmount)
        external
        view
        returns (uint256)
    {
        return _nextBorrowInterestRate(
            totalAssetBorrow(),
            borrowAmount,
            poolTWAI()
        );
    }

    // the current rate being received by suppliers
    function supplyInterestRate()
        external
        view
        returns (uint256)
    {
        uint256 assetBorrow = _totalAssetBorrowStored();
        return _nextSupplyInterestRate(
            _nextBorrowInterestRate(assetBorrow, 0, poolTWAI()),
            assetBorrow,
            _totalAssetSupply(assetBorrow)
        );
    }

    // the minimum rate new and existing suppliers will receive after the next supply
    function nextSupplyInterestRate(
        int256 supplyAmount)
        external
        view
        returns (uint256)
    {
        uint256 assetBorrow = totalAssetBorrow();
        uint256 totalSupply = _totalAssetSupply(assetBorrow);

        if(supplyAmount >= 0)
            totalSupply = totalSupply.add(uint256(supplyAmount));
        else
            totalSupply = totalSupply.sub(uint256(-supplyAmount));

        return _nextSupplyInterestRate(
            _nextBorrowInterestRate(assetBorrow, 0, poolTWAI()),
            assetBorrow,
            totalSupply
        );
    }


    function totalAssetBorrow()
        public
        view
        returns (uint256)
    {
        return IBZx(bZxContract).getTotalPrincipal(
            address(this),
            address(0) // loanTokenAddress (depreciated)
        );
    }

    function _totalAssetBorrowStored()
        internal
        view
        returns (uint256)
    {
        return IBZx(bZxContract).getPoolPrincipalStored(address(this));
    }

    function totalAssetSupply()
        external
        view
        returns (uint256)
    {
        return _totalAssetSupply(totalAssetBorrow());
    }

    function poolLastInterestRate()
        public
        view
        returns (uint256)
    {
        return IBZx(bZxContract).getPoolLastInterestRate(address(this));
    }

    function poolTWAI()
        public
        view
        returns (uint256)
    {
        return IBZx(bZxContract).getTWAI(address(this));
    }

    // returns the user's balance of underlying token
    function assetBalanceOf(
        address _owner)
        external
        view
        returns (uint256)
    {
        return balanceOf(_owner)
            .mul(tokenPrice())
            .div(WEI_PRECISION);
    }

    function getDepositAmountForBorrow(
        uint256 borrowAmount,
        uint256 initialLoanDuration,        // duration in seconds
        address collateralTokenAddress)     // address(0) means ETH
        external
        view
        returns (uint256) // depositAmount
    {
        if (borrowAmount != 0) {
            if (borrowAmount <= _underlyingBalance()) {
                if (collateralTokenAddress == address(0)) {
                    collateralTokenAddress = wethToken;
                }
                return IBZx(bZxContract).getRequiredCollateralByParams(
                    loanParamsIds[uint256(keccak256(abi.encodePacked(
                        collateralTokenAddress,
                        true
                    )))],
                    borrowAmount
                ).add(10); // some dust to compensate for rounding errors
            }
        }
    }

    function getBorrowAmountForDeposit(
        uint256 depositAmount,
        uint256 initialLoanDuration,        // duration in seconds
        address collateralTokenAddress)     // address(0) means ETH
        external
        view
        returns (uint256 borrowAmount)
    {
        if (depositAmount != 0) {
            if (collateralTokenAddress == address(0)) {
                collateralTokenAddress = wethToken;
            }
            borrowAmount = IBZx(bZxContract).getBorrowAmountByParams(
                loanParamsIds[uint256(keccak256(abi.encodePacked(
                    collateralTokenAddress,
                    true
                )))],
                depositAmount
            );

            if (borrowAmount > _underlyingBalance()) {
                borrowAmount = 0;
            }
        }
    }

    function getPoolUtilization()
        external
        view
        returns (uint256)
    {
        uint256 totalBorrow = totalAssetBorrow();
        return _utilizationRate(
            totalBorrow,
            _totalAssetSupply(totalBorrow)
        );
    }

    /* Internal functions */

    function _mintToken(
        address receiver,
        uint256 depositAmount)
        internal
        pausable
        returns (uint256 mintAmount)
    {
        require (depositAmount != 0, "17");

        _settleInterest(0);

        uint256 currentPrice = _tokenPrice(_totalAssetSupply(_totalAssetBorrowStored()));
        mintAmount = depositAmount
            .mul(WEI_PRECISION)
            .div(currentPrice);

        if (msg.value == 0) {
            _safeTransferFrom(loanTokenAddress, msg.sender, address(this), depositAmount, "18");
        } else {
            require(msg.value == depositAmount, "18");
            IWeth(wethToken).deposit.value(depositAmount)();
        }
        _mint(receiver, mintAmount, depositAmount, currentPrice);
    }

    function _burnToken(
        uint256 burnAmount)
        internal
        pausable
        returns (uint256 loanAmountPaid)
    {
        require(burnAmount != 0, "19");

        _settleInterest(0);

        if (burnAmount > balanceOf(msg.sender)) {
            require(burnAmount == uint256(-1), "32");
            burnAmount = balanceOf(msg.sender);
        }

        uint256 currentPrice = _tokenPrice(_totalAssetSupply(_totalAssetBorrowStored()));

        uint256 loanAmountOwed = burnAmount
            .mul(currentPrice)
            .div(WEI_PRECISION);
        uint256 loanAmountAvailableInContract = _underlyingBalance();

        loanAmountPaid = loanAmountOwed;
        require(loanAmountPaid <= loanAmountAvailableInContract, "37");
        _burn(msg.sender, burnAmount, loanAmountPaid, currentPrice);
    }

    function _borrow(
        bytes32 loanId,                 // 0 if new loan
        uint256 withdrawAmount,
        uint256 initialLoanDuration,    // duration in seconds
        uint256 collateralTokenSent,    // if 0, loanId must be provided; any ETH sent must equal this value
        address collateralTokenAddress, // if address(0), this means ETH and ETH must be sent with the call or loanId must be provided
        address borrower,
        address receiver,
        bytes memory loanDataBytes) // arbitrary order data
        internal
        pausable
        returns (IBZx.LoanOpenData memory)
    {
        require(withdrawAmount != 0, "6");

        require(msg.value == 0 || msg.value == collateralTokenSent, "7");
        require(collateralTokenSent != 0 || loanId != 0, "8");
        require(collateralTokenAddress != address(0) || msg.value != 0 || loanId != 0, "9");

        // ensures authorized use of existing loan
        require(loanId == 0 || msg.sender == borrower, "13");

        _settleInterest(loanId);

        if (loanId == 0) {
            loanId = keccak256(abi.encodePacked(
                collateralTokenAddress,
                address(this),
                msg.sender,
                borrower,
                block.timestamp
            ));
        }

        if (collateralTokenAddress == address(0)) {
            collateralTokenAddress = wethToken;
        }
        require(collateralTokenAddress != loanTokenAddress, "10");

        address[4] memory sentAddresses;
        uint256[5] memory sentAmounts;

        sentAddresses[0] = address(this); // lender
        sentAddresses[1] = borrower;
        sentAddresses[2] = receiver;
        //sentAddresses[3] = address(0); // manager

        //sentAmounts[0] = 0; // interestRate (found later)
        //sentAmounts[1] = 0; // borrowAmount (found later)
        //sentAmounts[2] = 0; // interestInitialAmount (found later)
        //sentAmounts[3] = 0; // loanTokenSent
        sentAmounts[4] = collateralTokenSent;

        sentAmounts[1] = withdrawAmount;
        sentAmounts[2] = 0; // interestInitialAmount (depreciated)

        return _borrowOrTrade(
            loanId,
            withdrawAmount,
            0, // leverageAmount (calculated later)
            collateralTokenAddress,
            sentAddresses,
            sentAmounts,
            loanDataBytes // loanDataBytes
        );
    }

    function _marginTrade(
        bytes32 loanId,                 // 0 if new loan
        uint256 leverageAmount,
        uint256 loanTokenSent,
        uint256 collateralTokenSent,
        address collateralTokenAddress,
        address trader,
        bytes memory loanDataBytes)
        internal
        pausable
        returns (IBZx.LoanOpenData memory loanOpenData)
    {
        // ensures authorized use of existing loan
        require(loanId == 0 || msg.sender == trader, "13");

        _settleInterest(loanId);

        if (loanId == 0) {
            loanId = keccak256(abi.encodePacked(
                collateralTokenAddress,
                address(this),
                msg.sender,
                trader,
                block.timestamp
            ));
        }

        if (collateralTokenAddress == address(0)) {
            collateralTokenAddress = wethToken;
        }
        require(collateralTokenAddress != loanTokenAddress, "11");

        address[4] memory sentAddresses;
        uint256[5] memory sentAmounts;

        sentAddresses[0] = address(this); // lender
        sentAddresses[1] = trader;
        sentAddresses[2] = trader;
        //sentAddresses[3] = address(0); // manager

        //sentAmounts[0] = 0; // interestRate (found later)
        //sentAmounts[1] = 0; // borrowAmount (found later)
        //sentAmounts[2] = 0; // interestInitialAmount (interest is calculated based on fixed-term loan)
        sentAmounts[3] = loanTokenSent;
        sentAmounts[4] = collateralTokenSent;

        uint256 totalDeposit;
        uint256 collateralToLoanRate;
        (sentAmounts[1],, totalDeposit, collateralToLoanRate) = _getPreMarginData( // borrowAmount, interestRate, totalDeposit, collateralToLoanRate
            collateralTokenAddress,
            collateralTokenSent,
            loanTokenSent,
            leverageAmount
        );
        require(totalDeposit != 0, "12");

        loanOpenData = _borrowOrTrade(
            loanId,
            0, // withdrawAmount
            leverageAmount,
            collateralTokenAddress,
            sentAddresses,
            sentAmounts,
            loanDataBytes
        );

        IBZx(bZxContract).setDepositAmount(
            loanOpenData.loanId,
            totalDeposit,
            totalDeposit
                .mul(WEI_PRECISION)
                .div(collateralToLoanRate)
        );

        return loanOpenData;
    }

    function _settleInterest(
        bytes32 loanId)
        internal
    {   
        IBZx(bZxContract).settleInterest(loanId);
    }

    function _totalDeposit(
        address collateralTokenAddress,
        uint256 collateralTokenSent,
        uint256 loanTokenSent)
        internal
        view
        returns (uint256 totalDeposit, uint256 collateralToLoanRate)
    {
        uint256 collateralToLoanPrecision;
        (collateralToLoanRate, collateralToLoanPrecision) = IPriceFeeds(IBZx(bZxContract).priceFeeds()).queryRate(
            collateralTokenAddress,
            loanTokenAddress
        );
        require(collateralToLoanRate != 0 && collateralToLoanPrecision != 0, "20");
        collateralToLoanRate = collateralToLoanRate
            .mul(WEI_PRECISION)
            .div(collateralToLoanPrecision);

        totalDeposit = loanTokenSent;
        if (collateralTokenSent != 0) {
            totalDeposit = collateralTokenSent
                .mul(collateralToLoanRate)
                .div(WEI_PRECISION)
                .add(totalDeposit);
        }
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
        returns (IBZx.LoanOpenData memory)
    {
        require (sentAmounts[1] <= _underlyingBalance() && // newPrincipal
            sentAddresses[1] != address(0), // borrower
            "24"
        );

	    if (sentAddresses[2] == address(0)) {
            sentAddresses[2] = sentAddresses[1]; // receiver = borrower
        }

        loanDataBytes = _checkPermit(collateralTokenAddress, loanDataBytes);
        // handle transfers prior to adding newPrincipal to loanTokenSent
        uint256 msgValue = _verifyTransfers(
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

        bool isTorqueLoan = withdrawAmount != 0 ?
            true :
            false;

        // converting to initialMargin
        if (leverageAmount != 0) {
            leverageAmount = SafeMath.div(WEI_PRECISION * WEI_PERCENT_PRECISION, leverageAmount);
        }

        return IBZx(bZxContract).borrowOrTradeFromPool.value(msgValue)(
            collateralTokenAddress,
            loanId,
            isTorqueLoan,
            leverageAmount, // initialMargin
            sentAddresses,
            sentAmounts,
            loanDataBytes
        );
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
        returns (uint256 msgValue)
    {
        address _wethToken = wethToken;
        address _loanTokenAddress = loanTokenAddress;
        address receiver = sentAddresses[2];
        uint256 newPrincipal = sentAmounts[1];
        uint256 loanTokenSent = sentAmounts[3];
        uint256 collateralTokenSent = sentAmounts[4];

        require(_loanTokenAddress != collateralTokenAddress, "26");

        msgValue = msg.value;

        if (withdrawalAmount != 0) { // withdrawOnOpen == true
            _safeTransfer(_loanTokenAddress, receiver, withdrawalAmount, "27");
            if (newPrincipal > withdrawalAmount) {
                _safeTransfer(_loanTokenAddress, bZxContract, newPrincipal - withdrawalAmount, "27");
            }
        } else {
            _safeTransfer(_loanTokenAddress, bZxContract, newPrincipal, "27");
        }

        if (collateralTokenSent != 0) {
            if (collateralTokenAddress == _wethToken && msgValue != 0 && msgValue >= collateralTokenSent) {
                IWeth(_wethToken).deposit.value(collateralTokenSent)();
                _safeTransfer(collateralTokenAddress, bZxContract, collateralTokenSent, "28");
                msgValue -= collateralTokenSent;
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

    function _checkPermit(address token, bytes memory loanDataBytes) internal returns (bytes memory) {
        if(abi.decode(loanDataBytes, (uint128)) & WITH_PERMIT != 0) {
            (uint128 f, bytes[] memory payload) = abi.decode(
                loanDataBytes,
                (uint128, bytes[])
            );
            (address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) = abi.decode(payload[2], (address, address, uint, uint, uint8, bytes32, bytes32));
            IERC20Permit(token).permit(owner, spender, value, deadline, v, r, s);
            payload[2] = "";
            loanDataBytes = abi.encode(f, payload);
        }
        return loanDataBytes;
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

    function _nextSupplyInterestRate(
        uint256 nextBorrowRate,
        uint256 assetBorrow,
        uint256 assetSupply)
        public
        view
        returns (uint256)
    {
        if (assetBorrow != 0 && assetSupply >= assetBorrow) {
            return nextBorrowRate
                .mul(_utilizationRate(assetBorrow, assetSupply))
                .mul(SafeMath.sub(WEI_PERCENT_PRECISION, IBZx(bZxContract).lendingFeePercent()))
                .div(WEI_PERCENT_PRECISION * WEI_PERCENT_PRECISION);
        }
    }

    function _nextBorrowInterestRate(
        uint256 totalBorrow,
        uint256 newBorrowNotYetRealized,
        uint256 lastIR)
        public
        view
        returns (uint256 nextRate)
    {
        uint256 utilRate = _utilizationRate(
            totalBorrow.add(newBorrowNotYetRealized),
            _totalAssetSupply(totalBorrow)
        );

        //utilRate from 0e18 to 100e18
        nextRate = rateHelper.calculateIR(utilRate, lastIR);
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
                .mul(WEI_PRECISION)
                .div(totalTokenSupply) : initialPrice;
    }

    function _getPreMarginData(
        address collateralTokenAddress,
        uint256 collateralTokenSent,
        uint256 loanTokenSent,
        uint256 leverageAmount)
        internal
        view
        returns (uint256 borrowAmount, uint256 interestRate, uint256 totalDeposit, uint256 collateralToLoanRate)
    {
        (totalDeposit, collateralToLoanRate) = _totalDeposit(
            collateralTokenAddress,
            collateralTokenSent,
            loanTokenSent
        );

        uint256 initialMargin = SafeMath.div(WEI_PRECISION * WEI_PERCENT_PRECISION, leverageAmount);

        // assumes that loan and collateral token are the same
        borrowAmount = totalDeposit
            .mul(WEI_PERCENT_PRECISION)
            .div(initialMargin);
    }

    function _totalAssetSupply(
        uint256 totalBorrow)
        internal
        view
        returns (uint256 totalSupply)
    {
        totalSupply = _flTotalAssetSupply; // temporary locked totalAssetSupply during a flash loan transaction
        if (totalSupply == 0) {
            totalSupply = _underlyingBalance()
                .add(totalBorrow);
        }
    }

    function _utilizationRate(
        uint256 assetBorrow,
        uint256 assetSupply)
        internal
        pure
        returns (uint256)
    {
        if (assetSupply != 0) {
            // U = total_borrow / total_supply
            return assetBorrow
                .mul(WEI_PERCENT_PRECISION)
                .div(assetSupply);
        }
    }


    function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) public {
        require(deadline >= block.timestamp, "OOKI: EXPIRED");
        bytes32 digest = keccak256(
            abi.encodePacked(
                "\x19\x01",
                DOMAIN_SEPARATOR,
                keccak256(abi.encode(PERMIT_TYPEHASH, owner, spender, value, nonces[owner]++, deadline))
            )
        );
        address recoveredAddress = ecrecover(digest, v, r, s);
        require(recoveredAddress != address(0) && recoveredAddress == owner, "OOKI: INVALID_SIGNATURE");
        _approve(owner, spender, value);
    }


    /* Owner-Only functions */

    function updateSettings(
        address settingsTarget,
        bytes memory callData)
        public
    {
        if (msg.sender != owner()) {
            address _lowerAdmin;
            address _lowerAdminContract;
            assembly {
                _lowerAdmin := sload(iToken_LowerAdminAddress)
                _lowerAdminContract := sload(iToken_LowerAdminContract)
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
    

    function initializeDomainSeparator() public onlyGuardian {
        uint chainId;
        assembly {
            chainId := chainid
        }
        DOMAIN_SEPARATOR = keccak256(
            abi.encode(
                keccak256('EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)'),
                keccak256(bytes(name)),
                keccak256(bytes('1')),
                chainId,
                address(this)
            )
        );
    }

    function setDemandCurve(ICurvedInterestRate _rateHelper) public onlyGuardian {
        require(address(_rateHelper) != address(0), "no zero address");
        rateHelper = _rateHelper;
    }

    function updateFlashBorrowFeePercent(uint256 newFeePercent) public onlyOwner {
        flashBorrowFeePercent = newFeePercent;
    }
}

