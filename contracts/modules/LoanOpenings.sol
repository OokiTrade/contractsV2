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
import "../swaps/SwapsUser.sol";


contract LoanOpenings is State, LoanOpeningsEvents, VaultController, InterestUser, SwapsUser {

    function initialize(
        address target)
        external
        onlyOwner
    {
        _setTarget(this.borrowOrTradeFromPool.selector, target);
        _setTarget(this.setDelegatedManager.selector, target);
        _setTarget(this.getEstimatedMarginExposure.selector, target);
        _setTarget(this.getRequiredCollateral.selector, target);
        _setTarget(this.getBorrowAmount.selector, target);
    }


    // Note: Only callable by loan pools (iTokens)
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
        nonReentrant
        returns (uint256 newPrincipal, uint256 newCollateral)
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

    function getEstimatedMarginExposure(
        address loanToken,
        address collateralToken,
        uint256 loanTokenSent,
        uint256 collateralTokenSent,
        uint256 interestRate,
        uint256 newPrincipal)
        external
        view
        returns (uint256)
    {
        uint256 maxLoanTerm = 2419200; // 28 days

        uint256 owedPerDay = newPrincipal
            .mul(interestRate)
            .div(DAYS_IN_A_YEAR * WEI_PERCENT_PRECISION);

        uint256 interestAmountRequired = maxLoanTerm
            .mul(owedPerDay)
            .div(1 days);

        uint256 receivedAmount = _swapsExpectedReturn(
            loanToken,
            collateralToken,
            loanTokenSent
                .sub(interestAmountRequired)
        );
        if (receivedAmount == 0) {
            return 0;
        } else {
            return collateralTokenSent
                .add(receivedAmount);
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

            uint256 fee = isTorqueLoan ?
                _getBorrowingFee(collateralAmountRequired) :
                _getTradingFee(collateralAmountRequired);
            if (fee != 0) {
                collateralAmountRequired = collateralAmountRequired
                    .add(fee);
            }
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
                    .add(WEI_PERCENT_PRECISION); // adjust for over-collateralized loan
            }

            uint256 collateral = collateralTokenAmount;
            uint256 fee = isTorqueLoan ?
                _getBorrowingFee(collateral) :
                _getTradingFee(collateral);
            if (fee != 0) {
                collateral = collateral
                    .sub(fee);
            }

            if (loanToken == collateralToken) {
                borrowAmount = collateral
                    .mul(WEI_PERCENT_PRECISION)
                    .div(marginAmount);
            } else {
                (uint256 sourceToDestRate, uint256 sourceToDestPrecision) = IPriceFeeds(priceFeeds).queryRate(
                    collateralToken,
                    loanToken
                );
                if (sourceToDestPrecision != 0) {
                    borrowAmount = collateral
                        .mul(WEI_PERCENT_PRECISION)
                        .mul(sourceToDestRate)
                        .div(marginAmount)
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
        uint256 initialMargin,
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
        returns (uint256, uint256)
    {
        require (loanParamsLocal.collateralToken != loanParamsLocal.loanToken, "collateral/loan match");
        require (initialMargin >= loanParamsLocal.minInitialMargin, "initialMargin too low");

        // maxLoanTerm == 0 indicates a Torqueloan and requres that torqueInterest != 0
        require(loanParamsLocal.maxLoanTerm != 0 ||
            sentValues[2] != 0, // torqueInterest
            "invalid interest");

        // initialize loan
        Loan storage loanLocal = _initializeLoan(
            loanParamsLocal,
            loanId,
            initialMargin,
            sentAddresses,
            sentValues
        );

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

            uint256 borrowingFee = _getBorrowingFee(sentValues[4]);
            if (borrowingFee != 0) {
                _payBorrowingFee(
                    sentAddresses[1], // borrower
                    loanLocal.id,
                    loanParamsLocal.collateralToken,
                    borrowingFee
                );

                sentValues[4] = sentValues[4] // collateralTokenReceived
                    .sub(borrowingFee);
            }
        } else {
            // update collateral after trade
            // sentValues[3] is repurposed to hold loanToCollateralSwapRate to avoid stack too deep error
            uint256 receivedAmount;
            (receivedAmount,,sentValues[3]) = _loanSwap(
                loanId,
                loanParamsLocal.loanToken,
                loanParamsLocal.collateralToken,
                sentAddresses[1], // borrower
                sentValues[3], // loanTokenUsable (minSourceTokenAmount)
                0, // maxSourceTokenAmount (0 means minSourceTokenAmount)
                0, // requiredDestTokenAmount (enforces that all of loanTokenUsable is swapped)
                false, // bypassFee
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
                initialMargin,
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
            sentValues[2] = SafeMath.div(WEI_PRECISION * WEI_PERCENT_PRECISION, initialMargin);
        }

        _finalizeOpen(
            loanParamsLocal,
            loanLocal,
            sentAddresses,
            sentValues,
            isTorqueLoan
        );

        return (sentValues[1], sentValues[4]); // newPrincipal, newCollateral
    }

    function _finalizeOpen(
        LoanParams memory loanParamsLocal,
        Loan storage loanLocal,
        address[4] memory sentAddresses,
        uint256[5] memory sentValues,
        bool isTorqueLoan)
        internal
    {
        (uint256 initialMargin, uint256 collateralToLoanRate) = IPriceFeeds(priceFeeds).getCurrentMargin(
            loanParamsLocal.loanToken,
            loanParamsLocal.collateralToken,
            loanLocal.principal,
            loanLocal.collateral
        );
        require(
            initialMargin > loanParamsLocal.maintenanceMargin,
            "unhealthy position"
        );

        if (loanLocal.startTimestamp == block.timestamp) {
            loanLocal.startRate = collateralToLoanRate;
        }

        _emitOpeningEvents(
            loanParamsLocal,
            loanLocal,
            sentAddresses,
            sentValues,
            collateralToLoanRate,
            initialMargin,
            isTorqueLoan
        );
    }

    function _emitOpeningEvents(
        LoanParams memory loanParamsLocal,
        Loan memory loanLocal,
        address[4] memory sentAddresses,
        uint256[5] memory sentValues,
        uint256 collateralToLoanRate,
        uint256 margin,
        bool isTorqueLoan)
        internal
    {
        if (isTorqueLoan) {
            emit Borrow(
                sentAddresses[1],                               // user (borrower)
                sentAddresses[0],                               // lender
                loanLocal.id,                                   // loanId
                loanParamsLocal.loanToken,                      // loanToken
                loanParamsLocal.collateralToken,                // collateralToken
                sentValues[1],                                  // newPrincipal
                sentValues[4],                                  // newCollateral
                sentValues[0],                                  // interestRate
                sentValues[2],                                  // interestDuration
                collateralToLoanRate,                           // collateralToLoanRate,
                margin                                          // currentMargin
            );
        } else {
            // currentLeverage = 100 / currentMargin
            margin = SafeMath.div(WEI_PRECISION * WEI_PERCENT_PRECISION, margin);

            emit Trade(
                sentAddresses[1],                               // user (trader)
                sentAddresses[0],                               // lender
                loanLocal.id,                                   // loanId
                loanParamsLocal.collateralToken,                // collateralToken
                loanParamsLocal.loanToken,                      // loanToken
                sentValues[4],                                  // positionSize
                sentValues[1],                                  // borrowedAmount
                sentValues[0],                                  // interestRate,
                loanLocal.endTimestamp,                         // settlementDate
                sentValues[3],                                  // entryPrice (loanToCollateralSwapRate)
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
        // allow at most 2% under-collateralized
        collateralAmountRequired = collateralAmountRequired
            .mul(98 ether)
            .div(100 ether);

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
        returns (Loan storage sloanLocal)
    {
        require(loanParamsLocal.active, "loanParams disabled");

        address lender = sentAddresses[0];
        address borrower = sentAddresses[1];
        address manager = sentAddresses[3];
        uint256 newPrincipal = sentValues[1];

        if (loanId == 0) {
            loanId = keccak256(abi.encodePacked(
                loanParamsLocal.id,
                lender,
                borrower,
                block.timestamp
            ));

            sloanLocal = loans[loanId];
            require(sloanLocal.id == 0, "loan exists");

            sloanLocal.id = loanId;
            sloanLocal.loanParamsId = loanParamsLocal.id;
            sloanLocal.principal = newPrincipal;
            sloanLocal.startTimestamp = block.timestamp;
            sloanLocal.startMargin = initialMargin;
            sloanLocal.borrower = borrower;
            sloanLocal.lender = lender;
            sloanLocal.active = true;
            //sloanLocal.pendingTradesId = 0;
            //sloanLocal.collateral = 0; // calculated later
            //sloanLocal.endTimestamp = 0; // calculated later
            //sloanLocal.startRate = 0; // queried later

            activeLoansSet.addBytes32(loanId);
            lenderLoanSets[lender].addBytes32(loanId);
            borrowerLoanSets[borrower].addBytes32(loanId);
        } else {
            sloanLocal = loans[loanId];
            require(sloanLocal.active && block.timestamp < sloanLocal.endTimestamp, "loan has ended");
            require(sloanLocal.borrower == borrower, "borrower mismatch");
            require(sloanLocal.lender == lender, "lender mismatch");
            require(sloanLocal.loanParamsId == loanParamsLocal.id, "loanParams mismatch");

            sloanLocal.principal = sloanLocal.principal
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
        // pay outstanding interest to lender
        _payInterest(
            loanLocal.lender,
            loanParamsLocal.loanToken
        );

        LoanInterest storage loanInterestLocal = loanInterest[loanLocal.id];
        LenderInterest storage lenderInterestLocal = lenderInterest[loanLocal.lender][loanParamsLocal.loanToken];

        uint256 maxLoanTerm = loanParamsLocal.maxLoanTerm;

        _settleFeeRewardForInterestExpense(
            loanInterestLocal,
            loanLocal.id,
            loanParamsLocal.loanToken,
            loanLocal.borrower,
            block.timestamp
        );

        uint256 previousDepositRemaining;
        if (maxLoanTerm == 0 && loanLocal.endTimestamp != 0) {
            previousDepositRemaining = loanLocal.endTimestamp
                .sub(block.timestamp) // block.timestamp < endTimestamp was confirmed earlier
                .mul(loanInterestLocal.owedPerDay)
                .div(1 days);
        }

        uint256 owedPerDay = newPrincipal
            .mul(newRate)
            .div(DAYS_IN_A_YEAR * WEI_PERCENT_PRECISION);

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
                .mul(1 days)
                .div(loanInterestLocal.owedPerDay)
                .add(block.timestamp);

            maxLoanTerm = loanLocal.endTimestamp
                .sub(block.timestamp);

            // loan term has to at least be greater than one hour
            require(maxLoanTerm > 1 hours, "loan too short");

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
                .div(1 days);
        }

        loanInterestLocal.depositTotal = loanInterestLocal.depositTotal
            .add(interestAmountRequired);

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
                .div(WEI_PERCENT_PRECISION);
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
                    .div(WEI_PERCENT_PRECISION);
            } else {
                collateralTokenAmount = 0;
            }
        }

        if (isTorqueLoan && collateralTokenAmount != 0) {
            collateralTokenAmount = collateralTokenAmount
                .mul(WEI_PERCENT_PRECISION)
                .div(marginAmount)
                .add(collateralTokenAmount);
        }
    }
}
