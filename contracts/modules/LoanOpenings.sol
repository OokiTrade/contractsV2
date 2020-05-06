/**
 * Copyright 2017-2020, bZeroX, LLC. All Rights Reserved.
 * Licensed under the Apache License, Version 2.0.
 */

pragma solidity 0.5.17;
pragma experimental ABIEncoderV2;

import "../core/State.sol";

import "../mixins/VaultController.sol";
import "../mixins/InterestUser.sol";
import "../modifiers/GasTokenUser.sol";
import "../swaps/SwapsUser.sol";


contract LoanOpenings is State, VaultController, InterestUser, GasTokenUser, SwapsUser {

    //TODO: function borrow(...) for trading directly from loan orders

    event Borrow(
        bytes32 indexed loanId,
        address indexed borrower,
        address indexed loanToken,
        address collateralToken,
        uint256 newPrincipal,
        uint256 newCollateral,
        uint256 interestRate,
        uint256 interestDuration,
        uint256 collateralToLoanRate,
        uint256 currentMargin
    );

    event Trade(
        address indexed trader,
        address indexed baseToken,
        address indexed quoteToken,
        bytes32 loanId,
        uint256 positionSize,
        uint256 borrowedAmount,
        uint256 interestRate,
        uint256 settlementDate,
        uint256 entryPrice, // one unit of baseToken, denominated in quoteToken
        uint256 entryLeverage,
        uint256 currentLeverage
    );

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

    // borrow(bytes32,bytes32,uint256,uint256,address,address,address)
    function borrow(
        bytes32 loanParamsId,
        bytes32 loanId, // if 0, start a new loan
        uint256 borrowAmount,
        uint256 initialLoanDuration,
        address lender,
        address receiver,
        address manager)
        external
        payable
        //usesGasToken
        nonReentrant
        returns (uint256)
    {
        Order memory orderLocal = lenderOrders[lender][loanParamsId];
        require(orderLocal.createdStartTimestamp != 0, "order not exists");
        require(initialLoanDuration >= orderLocal.minLoanTerm, "loan too short");
        require(initialLoanDuration <= orderLocal.maxLoanTerm, "loan too long");

        LoanParams memory loanParamsLocal = loanParams[loanParamsId];
        require(loanParamsLocal.id != 0, "loanParams not exists");
        require(msg.value == 0 || loanParamsLocal.collateralToken == address(wethToken), "wrong asset sent");
        require (loanParamsLocal.fixedLoanTerm == 0 || initialLoanDuration <= loanParamsLocal.fixedLoanTerm, "duration too long");

        address[4] memory sentAddresses;

        sentAddresses[0] = lender;
        sentAddresses[1] = msg.sender;
        sentAddresses[2] = receiver != address(0) ?
            receiver :
            msg.sender;
        sentAddresses[3] = manager;

        uint256[5] memory sentValues;

        // torqueInterest
        sentValues[2] = borrowAmount
            .mul(orderLocal.interestRate);
        sentValues[2] = sentValues[2]
            .mul(initialLoanDuration);
        sentValues[2] = sentValues[2]
            .div(31536000 * 10**20); // 365 * 86400 * 10**20

         // newRate
        sentValues[0] = orderLocal.interestRate;

        // newPrincipal
        sentValues[1] = borrowAmount
            .add(sentValues[2]);

        // loanTokenSent
        sentValues[3] = sentValues[1];

        // collateralTokenSent
        uint256 collateralAmountRequired = _getRequiredCollateral(
            loanParamsLocal.loanToken,
            loanParamsLocal.collateralToken,
            sentValues[1],
            loanParamsLocal.initialMargin,
            true // isTorqueLoan
        );
        require(collateralAmountRequired != 0, "collateral is 0");

        // deduct principal
        require(orderLocal.lockedAmount >= sentValues[1], "not enough to borrow");
        orderLocal.lockedAmount = orderLocal.lockedAmount
            .sub(sentValues[1]);

        // withdraw loan to receiver (usually borrower)
        if (loanParamsLocal.loanToken == address(wethToken)) {
            vaultEtherWithdraw(
                sentAddresses[2], // receiver
                borrowAmount
            );
        } else {
            vaultWithdraw(
                loanParamsLocal.loanToken,
                sentAddresses[2], // receiver
                borrowAmount
            );
        }

        // deposit collateral from msg.sender (usually borrower)
        if (msg.value == 0) {
            vaultDeposit(
                loanParamsLocal.collateralToken,
                msg.sender,
                collateralAmountRequired
            );
            sentValues[4] = collateralAmountRequired;
        } else {
            require(msg.value >= collateralAmountRequired, "not enough ether");
            vaultEtherDeposit(
                msg.sender,
                msg.value
            );
            sentValues[4] = msg.value; // all sent ether applies to collateral balance
        }

        return _borrowOrTrade(
            loanParamsLocal,
            loanId,
            true, // isTorqueLoan
            collateralAmountRequired,
            sentAddresses,
            sentValues,
            "" // loanDataBytes
        );
    }

    // borrowOrTradeFromPool(bytes32,bytes32,address[4],uint256[5],bytes)
    function borrowOrTradeFromPool(
        bytes32 loanParamsId,
        bytes32 loanId, // if 0, start a new loan
        bool isTorqueLoan,
        address[4] calldata sentAddresses,
            // lender: must match loan if loanId provided
            // borrower: must match loan if loanId provided
            // receiver: receiver of funds (address(0) assumes borrower address)
            // manager: delegated manager of loan unless address(0)
        uint256[5] calldata sentValues,
            // newRate: new loan interest rate
            // newPrincipal: new loan size (borrowAmount + any borrowed interest)
            // torqueInterest: new amount of interest to escrow for Torque loan (determines initial loan length)
            // loanTokenSent: total loanToken deposit
            // collateralTokenSent: total collateralToken deposit
        bytes calldata loanDataBytes)
        external
        payable
        //usesGasToken
        nonReentrant
        returns (uint256)
    {
        require(msg.value == 0 || loanDataBytes.length != 0, "loanDataBytes required with ether");

        // only callable by loan pools
        require(protocolManagers[msg.sender], "not authorized");

        LoanParams memory loanParamsLocal = loanParams[loanParamsId];
        require(loanParamsLocal.id != 0, "loanParams not exists");

        // get required collateral
        uint256 collateralAmountRequired = _getRequiredCollateral(
            loanParamsLocal.loanToken,
            loanParamsLocal.collateralToken,
            sentValues[1],
            loanParamsLocal.initialMargin,
            isTorqueLoan
        );
        require(collateralAmountRequired != 0, "collateral is 0");

        return _borrowOrTrade(
            loanParamsLocal,
            loanId,
            isTorqueLoan,
            collateralAmountRequired,
            sentAddresses,
            sentValues,
            loanDataBytes
        );
    }

    function _borrowOrTrade(
        LoanParams memory loanParamsLocal,
        bytes32 loanId, // if 0, start a new loan
        bool isTorqueLoan,
        uint256 collateralAmountRequired,
        address[4] memory sentAddresses,
            // lender: must match loan if loanId provided
            // borrower: must match loan if loanId provided
            // receiver: receiver of funds (address(0) assumes borrower address)
            // manager: delegated manager of loan unless address(0)
        uint256[5] memory sentValues,
            // newRate: new loan interest rate
            // newPrincipal: new loan size (borrowAmount + any borrowed interest)
            // torqueInterest: new amount of interest to escrow for Torque loan (determines initial loan length)
            // loanTokenSent: total loanToken deposit
            // collateralTokenSent: total collateralToken deposit
        bytes memory loanDataBytes)
        internal
        returns (uint256)
    {
        /*
            TODO: check these constraints
            isTorqueLoan == true:
                newPrincipal <= loanTokenSent
                Amount to withdraw = loanTokenSent - torqueInterest
                collateralTokenSent >= required colateral calculated later <- checked here _handleSettlements
            isTorqueLoan == false:
                newPrincipal <= loanTokenSent
                Amount to trade = loanTokenSent - required interest calculated later
                collateralTokenSent >= required colateral calculated later <- checked here _handleSettlements
        */
/*
todo:
    deposit/collateral token always sent in as iToken
    loan token sent in as underlying
*/

        require(sentValues[1] != 0 && sentValues[1] <= sentValues[3], "insufficient loanToken");
        require(loanParamsLocal.collateralToken != loanParamsLocal.loanToken, "collateral/loan match");

        require(loanParamsLocal.fixedLoanTerm != 0 ||
            sentValues[2] != 0, // torqueInterest
            "invalid interest");

        // initialize loan
        Loan storage loanLocal = loans[
            _initializeLoan(
                loanParamsLocal,
                loanId,
                sentAddresses,
                sentValues
            )
        ];

        // get required interest
        uint256 amount = _initializeInterest(
            loanParamsLocal,
            loanLocal,
            sentValues[0], // newRate
            sentValues[1], // newPrincipal,
            sentValues[2]  // torqueInterest
        );

        // substract out interest from usable loanToken sent
        sentValues[3] = sentValues[3]
            .sub(amount);

        if (!isTorqueLoan) {
            // update collateral after trade
            (uint256 receivedAmount,) = _loanSwap(
                sentAddresses[1], // borrower
                loanParamsLocal.loanToken,
                loanParamsLocal.collateralToken,
                sentValues[3], // loanTokenUsable
                0, // requiredDestTokenAmount
                0, // minConversionRate
                false, // isLiquidation
                loanDataBytes
            );
            sentValues[4] = sentValues[4] // collateralTokenSent
                .add(receivedAmount);
        }

        // settle collateral
        require(
            _isCollateralSatisfied(
                sentValues[4],
                collateralAmountRequired
            ),
            "collateral insufficient"
        );

        loanLocal.collateral = loanLocal.collateral
            .add(sentValues[4]);

        uint256 margin;
        // re-using amount variable to avoid stack too deep error
        (margin, amount) = IPriceFeeds(priceFeeds).getCurrentMargin(
            loanParamsLocal.loanToken,
            loanParamsLocal.collateralToken,
            loanLocal.principal,
            loanLocal.collateral
        );
        require(
            margin > loanParamsLocal.maintenanceMargin,
            "unhealthy position"
        );

        if (isTorqueLoan) {
            // reclaiming varaible -> interestDuration
            sentValues[2] = loanLocal.loanEndTimestamp.sub(block.timestamp);

            emit Borrow(
                loanLocal.id,                                   // loanId
                sentAddresses[1],                               // borrower
                loanParamsLocal.loanToken,                      // loanToken
                loanParamsLocal.collateralToken,                // collateralToken
                sentValues[1],                                  // newPrincipal
                sentValues[4],                                  // newCollateral
                sentValues[0],                                  // interestRate
                sentValues[2], // interestDuration
                amount,                                         // collateralToLoanRate,
                margin                                          // currentMargin
            );
        } else {
            // entryPrice = 1 / collateralToLoanRate
            amount = SafeMath.div(10**36, amount);

            // reclaiming varaible -> entryLeverage = 100 / initialMargin
            sentValues[2] = SafeMath.div(10**38, loanParamsLocal.initialMargin);

            // currentLeverage = 100 / currentMargin
            margin = SafeMath.div(10**38, margin);

            emit Trade(
                sentAddresses[1],                               // trader
                loanParamsLocal.collateralToken,                // baseToken
                loanParamsLocal.loanToken,                      // quoteToken
                loanLocal.id,                                   // loanId
                sentValues[4],                                  // positionSize
                sentValues[1],                                  // borrowedAmount
                sentValues[0],                                  // interestRate,
                loanLocal.loanEndTimestamp,                     // settlementDate
                amount,                                         // entryPrice
                sentValues[2],                                  // entryLeverage
                margin                                          // currentLeverage
            );
        }

        return sentValues[1]; // newPrincipal
    }

    // setDelegatedManager(bytes32,address,bool)
    function setDelegatedManager(
        bytes32 loanId,
        address delegated,
        bool toggle)
        external
    {
        require(loans[loanId].borrower == msg.sender, "unauthorized");

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

    // getRequiredCollateral(address,address,uint256,uint256,bool)
    function getRequiredCollateral(
        address loanToken,
        address collateralToken,
        uint256 newPrincipal,
        uint256 marginAmount,
        bool isTorqueLoan)
        public
        view
        returns (uint256 collateralAmountRequired)
    {
        if (marginAmount != 0) {
            collateralAmountRequired = _getRequiredCollateral(
                loanToken,
                collateralToken,
                newPrincipal,
                marginAmount,
                isTorqueLoan
            );
        }
    }

    // getBorrowAmount(address,address,uint256,uint256,bool)
    function getBorrowAmount(
        address loanToken,
        address collateralToken,
        uint256 collateralTokenAmount,
        uint256 marginAmount,
        bool isTorqueLoan)
        public
        view
        returns (uint256 borrowAmount)
    {
        if (marginAmount != 0) {
            if (isTorqueLoan) {
                marginAmount = marginAmount
                    .add(10**20); // adjust for over-collateralized loan
            }

            if (loanToken == collateralToken) {
                borrowAmount = collateralTokenAmount
                    .mul(10**20)
                    .div(marginAmount);
            } else {
                (uint256 sourceToDestRate, uint256 sourceToDestPrecision) = IPriceFeeds(priceFeeds).queryRate(
                    collateralToken,
                    loanToken
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

    function _isCollateralSatisfied(
        uint256 newCollateral,
        uint256 collateralAmountRequired)
        internal
        pure
        returns (bool)
    {
        if (newCollateral < collateralAmountRequired) {
            // allow at most 2% under-collateralized
            uint256 diff = collateralAmountRequired
                .sub(newCollateral)
                .mul(10**20)
                .div(collateralAmountRequired);

            return diff <= (2 * 10**18); // 2% diff
        } else {
            return true;
        }
    }

    function _initializeLoan(
        LoanParams memory loanParamsLocal,
        bytes32 loanId,
        address[4] memory sentAddresses,
        uint256[5] memory sentValues)
        internal
        returns (bytes32)
    {
        address lender = sentAddresses[0];
        address borrower = sentAddresses[1];
        address manager = sentAddresses[3];
        uint256 newPrincipal = sentValues[1];

        Loan memory loanLocal;

        if (loanId == 0) {
            loanId = keccak256(abi.encodePacked(
                loanParamsLocal.id,
                lender,
                borrower,
                block.timestamp
            ));
            require(loans[loanId].id == 0, "loan exists");

            loanLocal = Loan({
                id: loanId,
                loanParamsId: loanParamsLocal.id,
                pendingTradesId: 0,
                active: true,
                principal: newPrincipal,
                collateral: 0, // calculated later
                loanStartTimestamp: block.timestamp,
                loanEndTimestamp: 0, // calculated later
                borrower: borrower,
                lender: lender
            });

            loansSet.add(loanId);
        } else {
            loanLocal = loans[loanId];
            require(loanLocal.active && block.timestamp < loanLocal.loanEndTimestamp, "loan has ended");
            require(loanLocal.borrower == borrower, "borrower mismatch");
            require(loanLocal.lender == lender, "lender mismatch");

            loanLocal.principal = loanLocal.principal
                .add(newPrincipal);
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
            require(block.timestamp < loanLocal.loanEndTimestamp, "loan has ended");

            //require(depositToken == loanParamsLocal.collateralToken, "wrong collateral");

            if (tradeTokenAddress == address(0)) {
                require(loanParamsLocal.loanToken == loanLocal.positionTokenAddressFilled, "no withdrawals when in trade");
            } else {
                require(tradeTokenAddress == loanLocal.positionTokenAddressFilled, "wrong trade");
            }

            loanLocal.principal = loanLocal.principal.add(newPrincipal);
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
                principal: newPrincipal,
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
        orderFilledAmounts[loanParamsLocal.loanParamsId] = orderFilledAmounts[loanParamsLocal.loanParamsId].add(newPrincipal);

        loans[loanId] = loanLocal;*/
    }

    function _initializeInterest(
        LoanParams memory loanParamsLocal,
        Loan storage loanLocal,
        uint256 newRate,
        uint256 newPrincipal,
        uint256 torqueInterest) // ignored for fixed-term loans
        internal
        returns (uint256 interestAmountRequired)
    {
        LoanInterest storage loanInterestLocal = loanInterest[loanLocal.id];
        LenderInterest storage lenderInterestLocal = lenderInterest[loanLocal.lender][loanParamsLocal.loanToken];

        // pay outstanding interest to lender
        _payInterest(
            lenderInterestLocal,
            loanLocal.lender,
            loanParamsLocal.loanToken
        );

        uint256 maxDuration = loanParamsLocal.fixedLoanTerm;

        uint256 previousDepositRemaining;
        if (maxDuration == 0 && loanLocal.loanEndTimestamp != 0) {
            previousDepositRemaining = loanLocal.loanEndTimestamp
                .sub(block.timestamp) // block.timestamp < loanEndTimestamp was confirmed earlier
                .mul(loanInterestLocal.owedPerDay)
                .div(86400);
        }

        uint256 owedPerDay = newPrincipal
            .mul(newRate)
            .div(365 * 10**20);

        /*if (loanInterestLocal.updatedTimestamp != 0 && loanInterestLocal.owedPerDay != 0) {
            loanInterestLocal.paidTotal = block.timestamp
                .sub(loanInterestLocal.updatedTimestamp)
                .mul(loanInterestLocal.owedPerDay)
                .div(86400)
                .add(loanInterestLocal.paidTotal);
        }*/

        // update stored owedPerDay
        loanInterestLocal.owedPerDay = loanInterestLocal.owedPerDay
            .add(owedPerDay);
        lenderInterestLocal.owedPerDay = lenderInterestLocal.owedPerDay
            .add(owedPerDay);

        if (maxDuration == 0) {
            // indefinite-term loan

            // torqueInterest != 0 was confirmed earlier
            loanLocal.loanEndTimestamp = torqueInterest
                .add(previousDepositRemaining)
                .mul(86400)
                .div(loanInterestLocal.owedPerDay)
                .add(block.timestamp);

            // update maxDuration
            maxDuration = loanLocal.loanEndTimestamp
                .sub(block.timestamp);

            // loan term has to at least be 24 hours
            require(maxDuration >= 86400, "loan too short");

            interestAmountRequired = torqueInterest;
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

        loanInterestLocal.depositToken = loanInterestLocal.depositToken
            .add(interestAmountRequired);
        loanInterestLocal.updatedTimestamp = block.timestamp;

        // update remaining lender interest values
        lenderInterestLocal.principalTotal = lenderInterestLocal.principalTotal
            .add(newPrincipal);
        lenderInterestLocal.owedTotal = lenderInterestLocal.owedTotal
            .add(interestAmountRequired);
    }

    function _getRequiredCollateral(
        address loanToken,
        address collateralToken,
        uint256 newPrincipal,
        uint256 marginAmount,
        bool isTorqueLoan)
        internal
        view
        returns (uint256 collateralTokenAmount)
    {
        if (loanToken == collateralToken) {
            collateralTokenAmount = newPrincipal
                .mul(marginAmount)
                .div(10**20);
        } else {
            (uint256 sourceToDestRate, uint256 sourceToDestPrecision) = IPriceFeeds(priceFeeds).queryRate(
                collateralToken,
                loanToken
            );
            if (sourceToDestRate != 0) {
                collateralTokenAmount = newPrincipal
                    .mul(sourceToDestPrecision)
                    .div(sourceToDestRate)
                    .mul(marginAmount)
                    .div(10**20);
            } else {
                collateralTokenAmount = 0;
            }
        }

        if (isTorqueLoan && collateralTokenAmount != 0) {
            collateralTokenAmount = collateralTokenAmount
                .mul(10**20)
                .div(marginAmount)
                .add(collateralTokenAmount);
        }
    }
}
