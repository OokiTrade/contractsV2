/**
 * Copyright 2017-2020, bZeroX, LLC. All Rights Reserved.
 * Licensed under the Apache License, Version 2.0.
 */

pragma solidity 0.5.17;
pragma experimental ABIEncoderV2;

import "../core/State.sol";

import "../mixins/VaultController.sol";
import "../modifiers/GasTokenUser.sol";


/*import "../openzeppelin-solidity/SafeMath.sol";
import "../proxy/BZxProxiable.sol";
import "../storage/BZxStorage.sol";
import "../BZxVault.sol";
import "../oracle/OracleInterface.sol";
import "../openzeppelin-solidity/ERC20.sol";
import "../shared/iZeroXConnector.sol";*/

interface IPriceFeeds {
    function shouldLiquidate(
        State.LoanParams calldata loanParamsLocal,
        State.Loan calldata loanLocal)
        external
        view
        returns (bool);

    function getTradeData(
        address sourceTokenAddress,
        address destTokenAddress,
        uint256 sourceTokenAmount)
        external
        view
        returns (uint256 sourceToDestRate, uint256 sourceToDestPrecision, uint256 destTokenAmount);
}

interface ITrades {
    function trade(
        address sourceTokenAddress,
        address destTokenAddress,
        uint256 sourceTokenAmount,
        uint256 maxDestTokenAmount)
        external
        returns (uint256 destTokenAmountReceived, uint256 sourceTokenAmountUsed);
}

//contract LoanOpenings is BZxStorage, BZxProxiable, ZeroXAPIUser {
contract LoanOpenings is State, VaultController, GasTokenUser {
    //using SafeMath for uint256;

    event DelegatedManagerSet(
        bytes32 indexed loanId,
        address indexed delegator,
        address indexed delegated,
        bool isActive
    );

    constructor() public {}

    function()
        external
    {
        revert("fallback not allowed");
    }

    function borrowDirect(
        bytes32 loanParamsId,
        bytes32 loanId, // if 0, start a new loan
        address borrower,
        address receiver,
        address[4] calldata sentAddresses,
            // lender
            // borrower
            // receiver: receiver of funds (address(0) assumes borrower address)
            // manager: will set a delegated manager of this loan unless address(0)
        uint256[6] calldata sentAmounts,
            // newInterestRate: new loan interest rate
            // newLoanAmount: new loan size (principal from lender)
            // interestInitialAmount: interestAmount sent to determine initial loan length (this is included in one of the below)
            // loanTokenSent: newLoanAmount + interestAmount + any extra
            // collateralTokenSent: collateralAmountRequired + any extra
            // withdrawalAmount: Actual amount sent to borrower (can't exceed newLoanAmount); 0 for margin trade
        bytes calldata loanDataBytes)
        external
        payable
        usesGasToken
        nonReentrant
        returns (uint256)
    {
    /*
        mapping (bytes32 => Order) public lendOrders;                                   // orderId => Order
        mapping (bytes32 => Order) public borrowOrders;                                 // orderId => Order

        // TODO: setters for lenders and borrowers
        //  owner can deposit or withdraw (changes locked amount and transfers the token in or out)
        //  owner can change expirationStartTimestamp
        EnumerableBytes32Set.Bytes32Set internal lendOrdersSet;                         // active loans set
        EnumerableBytes32Set.Bytes32Set internal borrowOrdersSet;                       // active loans set
    */

        /*
        // only callable by loan pools
        require(protocolManagers[msg.sender], "not authorized");

        return _borrowOrTradeFromPool(
            loanParamsId,
            loanId,
            sentAddresses,
            sentAmounts,
            loanDataBytes
        );*/
    }

    // borrowOrTradeFromPool(bytes32,bytes32,address[4],uint256[6],bytes)
    function borrowOrTradeFromPool(
        bytes32 loanParamsId,
        bytes32 loanId, // if 0, start a new loan
        address[4] calldata sentAddresses,
            // lender
            // borrower
            // receiver: receiver of funds (address(0) assumes borrower address)
            // manager: will set a delegated manager of this loan unless address(0)
        uint256[6] calldata sentAmounts,
            // newInterestRate: new loan interest rate
            // newLoanAmount: new loan size (principal from lender)
            // interestInitialAmount: interestAmount sent to determine initial loan length (this is included in one of the below)
            // loanTokenSent: newLoanAmount + interestAmount + any extra
            // collateralTokenSent: collateralAmountRequired + any extra
            // withdrawalAmount: Actual amount sent to borrower (can't exceed newLoanAmount); 0 for margin trade
        bytes calldata loanDataBytes)
        external
        payable
        usesGasToken
        nonReentrant
        returns (uint256)
    {
        // only callable by loan pools
        require(protocolManagers[msg.sender], "not authorized");

        return _borrowOrTrade(
            loanParamsId,
            loanId,
            sentAddresses,
            sentAmounts,
            loanDataBytes
        );
    }

    function _borrowOrTrade(
        bytes32 loanParamsId,
        bytes32 loanId, // if 0, start a new loan
        address[4] memory sentAddresses,
            // lender
            // borrower
            // receiver: receiver of funds (address(0) assumes borrower address)
            // manager: will set a delegated manager of this loan unless address(0)
        uint256[6] memory sentAmounts,
            // newInterestRate: new loan interest rate
            // newLoanAmount: new loan size (principal from lender)
            // interestInitialAmount: interestAmount sent to determine initial loan length (this is included in one of the below)
            // loanTokenSent: newLoanAmount + interestAmount + any extra
            // collateralTokenSent: collateralAmountRequired + any extra
            // withdrawalAmount: Actual amount sent to borrower (can't exceed newLoanAmount); 0 for margin trade
        bytes memory loanDataBytes)
        internal
        returns (uint256)
    {
/*
todo:
how to differentiate margin loan and torque loan?

margin loan ->
currently:
 tradeTokenAddress != address(0) AND withdrawalAmount == newLoanAmount
future (maybe):
    

Torque loan ->
currently:
 tradeTokenAddress == address(0) AND withdrawalAmount <= newLoanAmount
future (maybe):

also todo:
    deposit/collateral token always sent in as iToken
    loan token sent in as underlying
*/

        require(sentAmounts[5] <= sentAmounts[1], "invalid withdrawal");
        require(sentAmounts[1] != 0 && sentAmounts[3] >= sentAmounts[1], "loanTokenSent insufficient");
        require(msg.value == 0 || loanDataBytes.length != 0, "loanDataBytes required with ether");

        LoanParams memory loanParamsLocal = loanParams[loanParamsId];
        require(loanParamsLocal.maxLoanDuration != 0 ||
            sentAmounts[2] != 0, // interestInitialAmount
            "invalid interest");

        // initialize loan
        Loan storage loanLocal = loans[
            _initializeLoan(
                loanParamsLocal,
                loanId,
                sentAddresses,
                sentAmounts
            )
        ];

        // get required collateral
        uint256 collateralAmountRequired = _getRequiredCollateral(
            loanParamsLocal.loanToken,
            loanParamsLocal.collateralToken,
            sentAmounts[1].add(sentAmounts[2]),  // newLoanAmount + interestAmount
            loanParamsLocal.initialMargin
        );
        require(collateralAmountRequired != 0, "collateral is 0");
        if (sentAmounts[5] != 0) { // Torque loan
            collateralAmountRequired = collateralAmountRequired
                .mul(10**20)
                .div(loanParamsLocal.initialMargin)
                .add(collateralAmountRequired);
        }

        // get required interest
        uint256 interestAmountRequired = _initializeInterest(
            loanParamsLocal,
            loanLocal,
            sentAmounts[0], // newInterestRate
            sentAmounts[1], // newLoanAmount,
            sentAmounts[2]  // interestInitialAmount
        );

        // handle transfer and trades
        _handleTransfersAndTrades(
            loanParamsLocal,
            loanLocal,
            [
                interestAmountRequired,
                collateralAmountRequired
            ],
            sentAmounts,
            sentAddresses[2] != address(0) ?
                sentAddresses[2] : // receiver
                sentAddresses[1],  // borrower
            loanDataBytes
        );

        require (
            !IPriceFeeds(feedsController).shouldLiquidate(
                loanParamsLocal,
                loanLocal
            ),
            "unhealthy position"
        );

        return sentAmounts[1]; // newLoanAmount
    }

    // setDelegatedManager(bytes32,address,bool)
    function setDelegatedManager(
        bytes32 loanId,
        address delegated,
        bool toggle)
        external
    {
        require (loans[loanId].borrower == msg.sender, "unauthorized");

        _setDelegatedManager(
            loanId,
            msg.sender,
            delegated,
            toggle
        );
    }

    function _setDelegatedManager(
        bytes32 loanId,
        address delegator,
        address delegated,
        bool toggle)
        internal
    {
        delegatedManagers[loanId][delegated] = toggle;

        emit DelegatedManagerSet(
            loanId,
            delegator,
            delegated,
            toggle
        );
    }

    // getRequiredCollateral(address,address,address,uint256,uint256)
    function getRequiredCollateral(
        address loanToken,
        address collateralToken,
        uint256 newLoanAmount,
        uint256 marginAmount)
        public
        view
        returns (uint256 collateralAmountRequired)
    {
        if (marginAmount != 0) {
            collateralAmountRequired = _getRequiredCollateral(
                loanToken,
                collateralToken,
                newLoanAmount,
                marginAmount
            );
        }
    }

    // getBorrowAmount(address,address,uint256,uint256)
    function getBorrowAmount(
        address loanToken,
        address collateralToken,
        uint256 collateralTokenAmount,
        uint256 marginAmount)
        public
        view
        returns (uint256 borrowAmount)
    {
        if (marginAmount != 0) {
            if (loanToken == collateralToken) {
                borrowAmount = collateralTokenAmount
                    .mul(10**20)
                    .div(marginAmount);
            } else {
                (uint256 sourceToDestRate, uint256 sourceToDestPrecision,) = IPriceFeeds(feedsController).getTradeData(
                    collateralToken,
                    loanToken,
                    uint256(-1) // get best rate
                );
                if (sourceToDestPrecision != 0) {
                    borrowAmount = collateralTokenAmount
                        .mul(10**20)
                        .div(marginAmount)
                        .mul(sourceToDestRate)
                        .div(sourceToDestPrecision);
                }
            }
        }
    }

    function _initializeLoan(
        LoanParams memory loanParamsLocal,
        bytes32 loanId,
        address[4] memory sentAddresses,
        uint256[6] memory sentAmounts)
        internal
        returns (bytes32)
    {
        address lender = sentAddresses[0];
        address borrower = sentAddresses[1];
        address manager = sentAddresses[3];
        uint256 newLoanAmount = sentAmounts[1];

        Loan memory loanLocal;

        if (loanId == 0) {
            loanId = keccak256(abi.encodePacked(
                loanParamsLocal.id,
                lender,
                borrower,
                block.timestamp
            ));
            require(loans[loanId].id == 0, "loan exists");

            loanLocal.id = loanId;
            loanLocal.loanParamsId = loanId;
            loanLocal.active = true;
            loanLocal.principal = newLoanAmount;
            //loanLocal.collateral = loanId;
            loanLocal.loanStartTimestamp = block.timestamp;
            //loanLocal.loanEndTimestamp = 0;
            loanLocal.borrower = borrower;
            loanLocal.lender = lender;

            loansSet.add(loanId);
        } else {
            loanLocal = loans[loanId];
            require(loanLocal.active && block.timestamp < loanLocal.loanEndTimestamp, "loan has ended");
            require(loanLocal.borrower == borrower, "borrower mismatch");

            loanLocal.principal = loanLocal.principal
                .add(newLoanAmount);
        }

        if (manager != address(0)) {
            _setDelegatedManager(
                loanId,
                borrower,
                manager,
                true
            );
        }

        loans[loanId] = loanLocal;

        return loanId;

        /*

        Loan memory loanLocal = loans[loanId];
        if (loanLocal.active) {
            // borrower has already filled part of the loan order previously and that loan is still active
            require (block.timestamp < loanLocal.loanEndTimestamp, "loan has ended");

            //require(depositToken == loanParamsLocal.collateralToken, "wrong collateral");

            if (tradeTokenAddress == address(0)) {
                require(loanParamsLocal.loanToken == loanLocal.positionTokenAddressFilled, "no withdrawals when in trade");
            } else {
                require(tradeTokenAddress == loanLocal.positionTokenAddressFilled, "wrong trade");
            }

            loanLocal.principal = loanLocal.principal.add(newLoanAmount);
        } else {
            // borrower has not previously filled part of this loan or the previous fill is inactive
            
            loanId = uint256(keccak256(abi.encodePacked(
                loanParamsLocal.loanParamsId,
                orderPositionList[loanParamsLocal.loanParamsId].length,
                borrower,
                msg.sender, // lender
                block.timestamp
            )));

            loanLocal = Loan({
                borrower: borrower,
                collateralTokenFilled: collateralToken,
                positionTokenAddressFilled: tradeTokenAddress == address(0) ? loanParamsLocal.loanToken : tradeTokenAddress,
                principal: newLoanAmount,
                loanTokenAmountUsed: 0,
                collateral: 0, // set later
                positionTokenAmountFilled: 0, // set later, unless tradeTokenAddress == address(0) (withdrawOnOpen)
                loanStartTimestamp: block.timestamp,
                loanEndTimestamp: 0, // set later
                active: true,
                loanId: loanId
            });
            
            if (!orderListIndex[loanParamsLocal.loanParamsId][borrower].isSet) {
                orderList[borrower].push(loanParamsLocal.loanParamsId);
                orderListIndex[loanParamsLocal.loanParamsId][borrower] = ListIndex({
                    index: orderList[borrower].length-1,
                    isSet: true
                });
            }

            orderPositionList[loanParamsLocal.loanParamsId].push(loanId);

            positionList.push(PositionRef({
                loanParamsId: loanParamsLocal.loanParamsId,
                loanId: loanId
            }));
            positionListIndex[loanId] = ListIndex({
                index: positionList.length-1,
                isSet: true
            });

            loanIds[loanParamsLocal.loanParamsId][borrower] = loanId;
        }
        
        if (orderLender[loanParamsLocal.loanParamsId] == address(0)) {
            // send lender (msg.sender)
            orderLender[loanParamsLocal.loanParamsId] = msg.sender;
            orderList[msg.sender].push(loanParamsLocal.loanParamsId);
            orderListIndex[loanParamsLocal.loanParamsId][msg.sender] = ListIndex({
                index: orderList[msg.sender].length-1,
                isSet: true
            });
        }
        orderFilledAmounts[loanParamsLocal.loanParamsId] = orderFilledAmounts[loanParamsLocal.loanParamsId].add(newLoanAmount);

        loans[loanId] = loanLocal;*/
    }

    function _initializeInterest(
        LoanParams memory loanParamsLocal,
        Loan storage loanLocal,
        uint256 newInterestRate,
        uint256 newLoanAmount,
        uint256 interestInitialAmount) // ignored for fixed-term loans
        internal
        returns (uint256 interestAmountRequired)
    {
        LenderInterest storage lenderInterestLocal = lenderInterest[loanLocal.lender][loanParamsLocal.loanToken];
        LoanInterest storage loanInterestLocal = loanInterest[loanLocal.id];

        // update lender interest
        /*
        TODO
        _payInterestForOracleAsLender(
            lenderInterestLocal,
            loanParamsLocal.oracleAddress,
            loanParamsLocal.loanToken
        );*/

        uint256 maxDuration = loanParamsLocal.maxLoanDuration;

        uint256 previousDepositRemaining;
        if (maxDuration == 0 && loanLocal.loanEndTimestamp != 0) {
            previousDepositRemaining = loanLocal.loanEndTimestamp
                .sub(block.timestamp) // block.timestamp < loanEndTimestamp was confirmed earlier
                .mul(loanInterestLocal.owedPerDay)
                .div(86400);
        }

        uint256 owedPerDay = newLoanAmount
            .mul(newInterestRate)
            .div(365 * 10**20);
        lenderInterestLocal.owedPerDay = lenderInterestLocal.owedPerDay
            .add(owedPerDay);

        if (loanInterestLocal.updatedTimestamp != 0 && loanInterestLocal.owedPerDay != 0) {
            loanInterestLocal.paidTotal = block.timestamp
                .sub(loanInterestLocal.updatedTimestamp)
                .mul(loanInterestLocal.owedPerDay)
                .div(86400)
                .add(loanInterestLocal.paidTotal);
        }
        loanInterestLocal.owedPerDay = loanInterestLocal.owedPerDay
            .add(owedPerDay);

        if (maxDuration == 0) {
            // indefinite-term loan

            // interestInitialAmount != 0 was confirmed earlier
            loanLocal.loanEndTimestamp = interestInitialAmount
                .add(previousDepositRemaining)
                .mul(86400)
                .div(loanInterestLocal.owedPerDay)
                .add(block.timestamp);

            // update maxDuration
            maxDuration = loanLocal.loanEndTimestamp
                .sub(block.timestamp);

            // loan term has to at least be 24 hours
            require(maxDuration >= 86400, "loan too short");

            interestAmountRequired = interestInitialAmount;
        } else {
            // fixed-term loan

            if (loanLocal.loanEndTimestamp == 0) {
                loanLocal.loanEndTimestamp = block.timestamp
                    .add(maxDuration);
            }

            interestAmountRequired = loanLocal.loanEndTimestamp
                .sub(block.timestamp)
                .mul(owedPerDay)
                .div(86400);
        }

        loanInterestLocal.depositTotal = loanInterestLocal.depositTotal
            .add(interestAmountRequired);
        loanInterestLocal.updatedTimestamp = block.timestamp;

        lenderInterestLocal.owedTotal = lenderInterestLocal.owedTotal
            .add(interestAmountRequired);

        lenderInterestLocal.borrowTotal = lenderInterestLocal.borrowTotal
            .add(newLoanAmount);
    }

    function _getRequiredCollateral(
        address loanToken,
        address collateralToken,
        uint256 newLoanAmount,
        uint256 marginAmount)
        internal
        view
        returns (uint256 collateralTokenAmount)
    {
        if (loanToken == collateralToken) {
            return newLoanAmount
                .mul(marginAmount)
                .div(10**20);
        } else {
            (uint256 sourceToDestRate, uint256 sourceToDestPrecision,) = IPriceFeeds(feedsController).getTradeData(
                collateralToken,
                loanToken,
                uint256(-1) // get best rate
            );
            if (sourceToDestRate != 0) {
                return newLoanAmount
                    .mul(sourceToDestPrecision)
                    .div(sourceToDestRate)
                    .mul(marginAmount)
                    .div(10**20);
            } else {
                return 0;
            }
        }
    }

    // loanParamsLocal.collateralToken
    // ****** sentAmounts[5] != 0 means torque loan ******
    function _handleTransfersAndTrades(
        LoanParams memory loanParamsLocal,
        Loan memory loanLocal,
        uint256[2] memory requiredAmounts, // interestAmountRequired, collateralAmountRequired
        uint256[6] memory sentAmounts,
        address /*receiver*/,
        bytes memory loanDataBytes)
        internal
    {
        uint256 loanTokenUsable = sentAmounts[3];
        uint256 collateralTokenUsable = sentAmounts[4];

        // deposit collateral token, unless same as loan token
        if (collateralTokenUsable != 0) {
            if (loanParamsLocal.collateralToken == loanParamsLocal.loanToken) {
                loanTokenUsable = loanTokenUsable
                    .add(collateralTokenUsable);
                collateralTokenUsable = 0;
            }
        }

        // withdraw loan token if needed
        if (sentAmounts[5] != 0) { // Torque loan
            loanTokenUsable = loanTokenUsable
                .sub(sentAmounts[5]); // withdrawalAmount
        }

        uint256 destTokenAmountReceived;
        uint256 sourceTokenAmountUsed;

        if (requiredAmounts[0] > loanTokenUsable) {
            require (collateralTokenUsable != 0, "can't fill interest");

            // spend collateral token to fill interest required
            uint256 interestTokenNeeded = requiredAmounts[0] - loanTokenUsable;

            vaultWithdraw(
                loanParamsLocal.collateralToken,
                tradesController,
                collateralTokenUsable
            );
            (destTokenAmountReceived, sourceTokenAmountUsed) = ITrades(tradesController).trade(
                loanParamsLocal.collateralToken,
                loanParamsLocal.loanToken,
                collateralTokenUsable,
                interestTokenNeeded
            );
            require (destTokenAmountReceived >= interestTokenNeeded && destTokenAmountReceived != uint256(-1), "can't fill interest");

            collateralTokenUsable = collateralTokenUsable.sub(sourceTokenAmountUsed);
            loanTokenUsable = loanTokenUsable.add(destTokenAmountReceived);
        }

        // requiredAmounts[0] (interestAmountRequired) is reserved from usable loan amount
        loanTokenUsable = loanTokenUsable.sub(requiredAmounts[0]);

        if (loanParamsLocal.collateralToken == loanParamsLocal.loanToken) {
            // requiredAmounts[1] (collateralAmountRequired) is reserved from usable loan amount (collateralTokenUsable is zero until now)
            loanTokenUsable = loanTokenUsable.sub(requiredAmounts[1]);
            collateralTokenUsable = requiredAmounts[1];
        }

        if (sentAmounts[5] == 0) { // Margin trade

            require(loanTokenUsable >= sentAmounts[1], // newLoanAmount
                "can't fill position");
            //require((collateralTokenUsable != 0 && loanParamsLocal.collateralToken == loanLocal.positionTokenAddressFilled) ||
            //    loanTokenUsable >= sentAmounts[1], // newLoanAmount
            //    "can't fill position");

            if (loanParamsLocal.collateralToken == loanParamsLocal.loanToken) {
                if (loanTokenUsable > sentAmounts[1]) { // newLoanAmount
                    collateralTokenUsable = collateralTokenUsable
                        .add(loanTokenUsable - sentAmounts[1]); // newLoanAmount
                    loanTokenUsable = sentAmounts[1]; // newLoanAmount
                }
            }

            destTokenAmountReceived = 0;
            sourceTokenAmountUsed = 0;

            if (loanTokenUsable != 0 && loanParamsLocal.collateralToken != loanParamsLocal.loanToken) {
                vaultWithdraw(
                    loanParamsLocal.loanToken,
                    loanDataBytes.length == 0 ?
                        tradesController :
                        tradesController,//address(zeroXConnector),
                    loanTokenUsable
                );

                if (loanDataBytes.length == 0) {
                    (destTokenAmountReceived, sourceTokenAmountUsed) = ITrades(tradesController).trade(
                        loanParamsLocal.loanToken,
                        loanParamsLocal.collateralToken,
                        loanTokenUsable,
                        uint256(-1)
                    );
                } else {
                    /*(destTokenAmountReceived, sourceTokenAmountUsed) = zeroXConnector.trade.value(msg.value)(
                        loanParamsLocal.loanToken,
                        loanParamsLocal.collateralToken,
                        receiver,
                        loanTokenUsable,
                        0,
                        loanDataBytes
                    );*/
                }

                require(destTokenAmountReceived != 0 && destTokenAmountReceived != uint256(-1), "trade failed");

                collateralTokenUsable = collateralTokenUsable
                    .add(destTokenAmountReceived);

                loanTokenUsable = loanTokenUsable
                    .sub(sourceTokenAmountUsed);
            }

            /*uint256 newPositionTokenAmount;
            if (loanParamsLocal.collateralToken == loanLocal.positionTokenAddressFilled) {
                newPositionTokenAmount = collateralTokenUsable.add(destTokenAmountReceived)
                    .sub(requiredAmounts[1]);

                collateralTokenUsable = requiredAmounts[1];
            } else {
                newPositionTokenAmount = destTokenAmountReceived;
            }

            loanLocal.positionTokenAmountFilled = loanLocal.positionTokenAmountFilled
                .add(newPositionTokenAmount);*/
        }

       //require (collateralTokenUsable >= collateralAmountRequired, "collateral insufficient");
        loanLocal.collateral = loanLocal.collateral
            .add(collateralTokenUsable);
        if (collateralTokenUsable < requiredAmounts[1]) { // collateralAmountRequired
            // allow at most 2% under-collateralized
            collateralTokenUsable = requiredAmounts[1]
                .sub(collateralTokenUsable);
            collateralTokenUsable = collateralTokenUsable
                .mul(10**20);
            collateralTokenUsable = collateralTokenUsable
                .div(requiredAmounts[1]);
            require(
                collateralTokenUsable <= (2 * 10**18),
                "collateral insufficient"
            );
        }

        if (loanTokenUsable != 0) {
            revert("surplus loan token");
            /*if (sentAmounts[5] != 0) {
                // since Torque loan, we send excced to the receiver

                loanLocal.positionTokenAmountFilled = loanLocal.positionTokenAmountFilled
                    .add(loanTokenUsable);
            } else {
                revert("surplus loan token");
            }*/
        }

        loans[loanLocal.id] = loanLocal;
    }

    /*
    // TODO
    function _payInterestForOracleAsLender(
        LenderInterest memory lenderInterestLocal,
        address oracleAddress,
        address interestTokenAddress)
        internal
    {
        address oracleRef = oracleAddresses[oracleAddress];

        uint256 interestOwedNow = 0;
        if (lenderInterestLocal.owedPerDay > 0 && lenderInterestLocal.updatedTimestamp > 0 && interestTokenAddress != address(0)) {
            interestOwedNow = block.timestamp.sub(lenderInterestLocal.updatedTimestamp).mul(lenderInterestLocal.owedPerDay).div(86400);
            if (interestOwedNow > tokenInterestOwed[msg.sender][interestTokenAddress])
	        interestOwedNow = tokenInterestOwed[msg.sender][interestTokenAddress];

            if (interestOwedNow > 0) {
                lenderInterestLocal.paidTotal = lenderInterestLocal.paidTotal.add(interestOwedNow);
                tokenInterestOwed[msg.sender][interestTokenAddress] = tokenInterestOwed[msg.sender][interestTokenAddress].sub(interestOwedNow);

                // send the interest to the oracle for further processing
                vaultWithdraw(
                    interestTokenAddres,
                    oracleRef,
                    interestOwedNow
                );

                // calls the oracle to signal processing of the interest (ie: paying the lender, retaining fees)
                if (!OracleInterface(oracleRef).didPayInterestByLender(
                    msg.sender, // lender
                    interestTokenAddress,
                    interestOwedNow,
                    gasUsed // initial used gas, collected in modifier
                )) {
                    revert("_payInterestForOracle: OracleInterface.didPayInterestByLender failed");
                }
            }
        }

        lenderInterestLocal.updatedTimestamp = block.timestamp;
        lenderInterest[msg.sender][interestTokenAddress] = lenderInterestLocal;
    }
    */
}
