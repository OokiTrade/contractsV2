/**
 * Copyright 2017-2020, bZeroX, LLC. All Rights Reserved.
 * Licensed under the Apache License, Version 2.0.
 */

pragma solidity 0.5.17;
pragma experimental ABIEncoderV2;

import "../core/State.sol";
import "../events/LoanOpeningsEvents.sol";
import "../mixins/VaultController.sol";
import "../mixins/InterestUser.sol";
import "../mixins/GasTokenUser.sol";
import "../swaps/SwapsUser.sol";


//TODO: function borrow(...) for trading directly from loan orders
contract LoanOpenings is State, LoanOpeningsEvents, VaultController, InterestUser, GasTokenUser, SwapsUser {

    constructor() public {}

    function()
        external
    {
        revert("fallback not allowed");
    }

    function initialize(
        address target)
        external
        onlyOwner
    {
        _setTarget(this.borrow.selector, target);
        _setTarget(this.borrowOrTradeFromPool.selector, target);
        _setTarget(this.setDelegatedManager.selector, target);
        _setTarget(this.getDepositAmountForBorrow.selector, target);
        _setTarget(this.getRequiredCollateral.selector, target);
        _setTarget(this.getBorrowAmount.selector, target);
    }

    function borrow(
        bytes32 loanParamsId,
        bytes32 loanId, // if 0, start a new loan
        uint256 borrowAmount,
        uint256 initialLoanDuration,
        address lender,
        address receiver,
        address manager,
        bool depositCollateral)
        external
        payable
        //usesGasToken
        nonReentrant
        returns (uint256)
    {
        Order storage orderLocal = lenderOrders[lender][loanParamsId];
        require(orderLocal.createdTimestamp != 0, "order not exists");
        require(initialLoanDuration >= orderLocal.minLoanTerm, "loan too short");
        require(initialLoanDuration <= orderLocal.maxLoanTerm, "loan too long");
        require(orderLocal.expirationTimestamp == 0 || orderLocal.expirationTimestamp > block.timestamp, "order is expired");

        LoanParams memory loanParamsLocal = loanParams[loanParamsId];
        require(loanParamsLocal.id != 0, "loanParams not exists");
        require(msg.value == 0 || loanParamsLocal.collateralToken == address(wethToken), "wrong asset sent");
        require (loanParamsLocal.maxLoanTerm == 0 || initialLoanDuration <= loanParamsLocal.maxLoanTerm, "duration too long");

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

        // newPrincipal (principal + initial ecrowed interest)
        sentValues[1] = borrowAmount
            .add(sentValues[2]);

        // loanTokenReceived (amount not sent directly to borrower)
        sentValues[3] = sentValues[2];

        // collateralTokenReceived
        uint256 collateralAmountRequired = _getRequiredCollateral(
            loanParamsLocal.loanToken,
            loanParamsLocal.collateralToken,
            sentValues[1],
            loanParamsLocal.minInitialMargin,
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

        if (depositCollateral) {
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
        } else {
            require (msg.value == 0, "ether not accepted");

            // if collateral isn't deposited, an existing loan can be added to if there's sufficient
            // excess collateral (checked later)
            // sentValues[4] == 0
        }

        return _borrowOrTrade(
            loanParamsLocal,
            loanId,
            true, // isTorqueLoan
            collateralAmountRequired,
            loanParamsLocal.minInitialMargin,
            sentAddresses,
            sentValues,
            "" // loanDataBytes
        );
    }

    function borrowOrTradeFromPool(
        bytes32 loanParamsId,
        bytes32 loanId, // if 0, start a new loan
        bool isTorqueLoan,
        uint256 initialMargin,
        address[4] calldata sentAddresses,
            // lender: must match loan if loanId provided
            // borrower: must match loan if loanId provided
            // receiver: receiver of funds (address(0) assumes borrower address)
            // manager: delegated manager of loan unless address(0)
        uint256[5] calldata sentValues,
            // newRate: new loan interest rate
            // newPrincipal: new loan size (borrowAmount + any borrowed interest)
            // torqueInterest: new amount of interest to escrow for Torque loan (determines initial loan length)
            // loanTokenReceived: total loanToken deposit (amount not sent to borrower in the case of Torque loans)
            // collateralTokenReceived: total collateralToken deposit
        bytes calldata loanDataBytes)
        external
        payable
        //usesGasToken
        nonReentrant
        returns (uint256)
    {
        require(msg.value == 0 || loanDataBytes.length != 0, "loanDataBytes required with ether");

        // only callable by loan pools
        require(loanPoolToUnderlying[msg.sender] != address(0), "not authorized");

        LoanParams memory loanParamsLocal = loanParams[loanParamsId];
        require(loanParamsLocal.id != 0, "loanParams not exists");

        // get required collateral
        uint256 collateralAmountRequired = _getRequiredCollateral(
            loanParamsLocal.loanToken,
            loanParamsLocal.collateralToken,
            sentValues[1],
            initialMargin,
            isTorqueLoan
        );
        require(collateralAmountRequired != 0, "collateral is 0");

        return _borrowOrTrade(
            loanParamsLocal,
            loanId,
            isTorqueLoan,
            collateralAmountRequired,
            initialMargin,
            sentAddresses,
            sentValues,
            loanDataBytes
        );
    }

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

    function getDepositAmountForBorrow(
        address loanToken,            // address(0) means ETH
        address collateralToken,      // address(0) means ETH
        uint256 borrowAmount,
        uint256 marginAmount,
        uint256 initialLoanDuration,  // duration in seconds
        uint256 interestRate)
        external
        view
        returns (uint256 depositAmount)
    {
        if (borrowAmount != 0) {
            // adjust value since interest is also borrowed
            uint256 _borrowAmount = borrowAmount
                .mul(
                    interestRate
                        .mul(initialLoanDuration)
                        .div(315360) // 365 * 86400 / 100
                        .add(10**22)
                )
                .div(10**22);

            return _getRequiredCollateral(
                loanToken,
                collateralToken != address(0) ? collateralToken : address(wethToken),
                _borrowAmount,
                marginAmount,
                true // isTorqueLoan
            ).add(10); // some dust to compensate for rounding errors
        }
    }

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

    function _borrowOrTrade(
        LoanParams memory loanParamsLocal,
        bytes32 loanId, // if 0, start a new loan
        bool isTorqueLoan,
        uint256 collateralAmountRequired,
        uint256 margin, // initialMargin
        address[4] memory sentAddresses,
            // lender: must match loan if loanId provided
            // borrower: must match loan if loanId provided
            // receiver: receiver of funds (address(0) assumes borrower address)
            // manager: delegated manager of loan unless address(0)
        uint256[5] memory sentValues,
            // newRate: new loan interest rate
            // newPrincipal: new loan size (borrowAmount + any borrowed interest)
            // torqueInterest: new amount of interest to escrow for Torque loan (determines initial loan length)
            // loanTokenReceived: total loanToken deposit
            // collateralTokenReceived: total collateralToken deposit
        bytes memory loanDataBytes)
        internal
        returns (uint256)
    {
        require (loanParamsLocal.collateralToken != loanParamsLocal.loanToken, "collateral/loan match");
        require (margin >= loanParamsLocal.minInitialMargin, "initialMargin too low");

        // maxLoanTerm == 0 indicates a Torqueloan and requres that torqueInterest != 0
        require(loanParamsLocal.maxLoanTerm != 0 ||
            sentValues[2] != 0, // torqueInterest
            "invalid interest");

        // initialize loan
        Loan storage loanLocal = loans[
            _initializeLoan(
                loanParamsLocal,
                loanId,
                margin, // initialMargin
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

        if (isTorqueLoan) {
            require(sentValues[3] == 0, "surplus loan token");
        } else {
            // update collateral after trade
            (uint256 receivedAmount,) = _loanSwap(
                loanId,
                loanParamsLocal.loanToken,
                loanParamsLocal.collateralToken,
                sentAddresses[1], // borrower
                sentValues[3], // loanTokenUsable
                0, // requiredDestTokenAmount (enforces that all of loanTokenUsable is swapped)
                0, // minConversionRate
                false, // isLiquidation
                loanDataBytes
            );
            sentValues[4] = sentValues[4] // collateralTokenReceived
                .add(receivedAmount);
        }

        // settle collateral
        require(
            _isCollateralSatisfied(
                loanParamsLocal,
                loanLocal,
                margin, // initialMargin
                sentValues[4],
                collateralAmountRequired
            ),
            "collateral insufficient"
        );

        loanLocal.collateral = loanLocal.collateral
            .add(sentValues[4]);

        if (isTorqueLoan) {
            // reclaiming varaible -> interestDuration
            sentValues[2] = loanLocal.endTimestamp.sub(block.timestamp);
        } else {
            // reclaiming varaible -> entryLeverage = 100 / initialMargin
            sentValues[2] = SafeMath.div(10**38, margin);
        }

        // re-using margin and amount variables to avoid stack too deep error
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

        if (loanLocal.startTimestamp == block.timestamp) {
            loanLocal.startRate = amount; // collateralToLoanRate
        }

        _emitOpeningEvents(
            loanParamsLocal,
            loanLocal,
            sentAddresses,
            sentValues,
            amount,
            margin,
            isTorqueLoan
        );

        return sentValues[1]; // newPrincipal
    }

    function _emitOpeningEvents(
        LoanParams memory loanParamsLocal,
        Loan memory loanLocal,
        address[4] memory sentAddresses,
        uint256[5] memory sentValues,
        uint256 amount,
        uint256 margin,
        bool isTorqueLoan)
        internal
    {
        if (isTorqueLoan) {
            emit Borrow(
                loanLocal.id,                                   // loanId
                sentAddresses[1],                               // borrower
                sentAddresses[0],                               // lender
                loanParamsLocal.loanToken,                      // loanToken
                loanParamsLocal.collateralToken,                // collateralToken
                sentValues[1],                                  // newPrincipal
                sentValues[4],                                  // newCollateral
                sentValues[0],                                  // interestRate
                sentValues[2],                                  // interestDuration
                amount,                                         // collateralToLoanRate,
                margin                                          // currentMargin
            );
        } else {
            // entryPrice = 1 / collateralToLoanRate
            amount = SafeMath.div(10**36, amount);

            // currentLeverage = 100 / currentMargin
            margin = SafeMath.div(10**38, margin);

            emit Trade(
                sentAddresses[1],                               // trader
                loanParamsLocal.collateralToken,                // baseToken
                loanParamsLocal.loanToken,                      // quoteToken
                sentAddresses[0],                               // lender
                loanLocal.id,                                   // loanId
                sentValues[4],                                  // positionSize
                sentValues[1],                                  // borrowedAmount
                sentValues[0],                                  // interestRate,
                loanLocal.endTimestamp,                         // settlementDate
                amount,                                         // entryPrice
                sentValues[2],                                  // entryLeverage
                margin                                          // currentLeverage
            );
        }
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

    function _isCollateralSatisfied(
        LoanParams memory loanParamsLocal,
        Loan memory loanLocal,
        uint256 initialMargin,
        uint256 newCollateral,
        uint256 collateralAmountRequired)
        internal
        view
        returns (bool)
    {
        if (newCollateral < collateralAmountRequired) {
            // check that existing collateral is sufficient coverage
            if (loanLocal.collateral != 0) {
                uint256 maxDrawdown = IPriceFeeds(priceFeeds).getMaxDrawdown(
                    loanParamsLocal.loanToken,
                    loanParamsLocal.collateralToken,
                    loanLocal.principal,
                    loanLocal.collateral,
                    initialMargin
                );
                return newCollateral
                    .add(maxDrawdown) >= collateralAmountRequired;
            } else {
                return false;
            }
        }
        return true;
    }

    function _initializeLoan(
        LoanParams memory loanParamsLocal,
        bytes32 loanId,
        uint256 initialMargin,
        address[4] memory sentAddresses,
        uint256[5] memory sentValues)
        internal
        returns (bytes32)
    {
        require(loanParamsLocal.active, "loanParams disabled");

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
                startTimestamp: block.timestamp,
                endTimestamp: 0, // calculated later
                startMargin: initialMargin,
                startRate: 0, // queried later
                borrower: borrower,
                lender: lender
            });

            activeLoansSet.add(loanId);
            lenderLoanSets[lender].add(loanId);
            borrowerLoanSets[borrower].add(loanId);
        } else {
            loanLocal = loans[loanId];
            require(loanLocal.active && block.timestamp < loanLocal.endTimestamp, "loan has ended");
            require(loanLocal.borrower == borrower, "borrower mismatch");
            require(loanLocal.lender == lender, "lender mismatch");
            require(loanLocal.loanParamsId == loanParamsLocal.id, "loanParams mismatch");

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

        uint256 maxLoanTerm = loanParamsLocal.maxLoanTerm;

        uint256 previousDepositRemaining;
        if (maxLoanTerm == 0 && loanLocal.endTimestamp != 0) {
            previousDepositRemaining = loanLocal.endTimestamp
                .sub(block.timestamp) // block.timestamp < endTimestamp was confirmed earlier
                .mul(loanInterestLocal.owedPerDay)
                .div(86400);
        }

        uint256 owedPerDay = newPrincipal
            .mul(newRate)
            .div(365 * 10**20);

        // update stored owedPerDay
        loanInterestLocal.owedPerDay = loanInterestLocal.owedPerDay
            .add(owedPerDay);
        lenderInterestLocal.owedPerDay = lenderInterestLocal.owedPerDay
            .add(owedPerDay);

        if (maxLoanTerm == 0) {
            // indefinite-term (Torque) loan

            // torqueInterest != 0 was confirmed earlier
            loanLocal.endTimestamp = torqueInterest
                .add(previousDepositRemaining)
                .mul(86400)
                .div(loanInterestLocal.owedPerDay)
                .add(block.timestamp);

            // update maxLoanTerm
            maxLoanTerm = loanLocal.endTimestamp
                .sub(block.timestamp);

            // loan term has to at least be 24 hours
            require(maxLoanTerm >= 86400, "loan too short");

            interestAmountRequired = torqueInterest;
        } else {
            // fixed-term loan

            if (loanLocal.endTimestamp == 0) {
                loanLocal.endTimestamp = block.timestamp
                    .add(maxLoanTerm);
            }

            interestAmountRequired = loanLocal.endTimestamp
                .sub(block.timestamp)
                .mul(owedPerDay)
                .div(86400);
        }

        loanInterestLocal.depositTotal = loanInterestLocal.depositTotal
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
