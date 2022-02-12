/**
 * Copyright 2017-2022, OokiDao. All Rights Reserved.
 * Licensed under the Apache License, Version 2.0.
 */

pragma solidity 0.5.17;
pragma experimental ABIEncoderV2;

import "../../core/State.sol";
import "../../events/LoanOpeningsEvents.sol";
import "../../mixins/VaultController.sol";
import "../../mixins/InterestHandler.sol";
import "../../swaps/SwapsUser.sol";
import "../../governance/PausableGuardian.sol";


contract LoanOpenings is State, LoanOpeningsEvents, VaultController, InterestHandler, SwapsUser, PausableGuardian {

    function initialize(
        address target)
        external
        onlyOwner
    {
        _setTarget(this.borrowOrTradeFromPool.selector, target);
        _setTarget(this.setDelegatedManager.selector, target);
        _setTarget(this.getEstimatedMarginExposure.selector, target); // DEPRECATED, remove next deploy
        _setTarget(this.getRequiredCollateral.selector, target);
        _setTarget(this.getRequiredCollateralByParams.selector, target);
        _setTarget(this.getBorrowAmount.selector, target);
        _setTarget(this.getBorrowAmountByParams.selector, target);
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
        pausable
        returns (LoanOpenData memory)
    {
        require(msg.value == 0 || loanDataBytes.length != 0, "loanDataBytes required with ether");

        // only callable by loan pools
        require(loanPoolToUnderlying[msg.sender] != address(0), "not authorized");

        LoanParams memory loanParamsLocal = loanParams[loanParamsId];
        require(loanParamsLocal.id != 0, "loanParams not exists");

        if (initialMargin == 0) {
            require(isTorqueLoan, "initialMargin == 0");
            initialMargin = loanParamsLocal.minInitialMargin;
        }

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
        pausable
    {
        require(loans[loanId].borrower == msg.sender, "unauthorized");

        _setDelegatedManager(
            loanId,
            msg.sender,
            delegated,
            toggle
        );
    }


    // DEPRECATED, UI going to calculate this
    function getEstimatedMarginExposure(
        address loanToken,
        address collateralToken,
        uint256 loanTokenSent,
        uint256 collateralTokenSent,
        uint256 /*interestRate*/,
        uint256 /*newPrincipal*/,
        bytes calldata payload)
        external
        returns (uint256 value)
    {
        value = _swapsExpectedReturn(
            loanToken,
            collateralToken,
            loanTokenSent,
            payload
        );
        if (value != 0) {
            return collateralTokenSent
                .add(value);
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

            uint256 feePercent = isTorqueLoan ?
                borrowingFeePercent :
                tradingFeePercent;
            if (collateralAmountRequired != 0 && feePercent != 0) {
                collateralAmountRequired = collateralAmountRequired
                    .mul(WEI_PERCENT_PRECISION)
                    .divCeil(
                        WEI_PERCENT_PRECISION - feePercent // never will overflow
                    );
            }
        }
    }

    function getRequiredCollateralByParams(
        bytes32 loanParamsId,
        uint256 newPrincipal)
        public
        view
        returns (uint256 collateralAmountRequired)
    {
        LoanParams memory loanParamsLocal = loanParams[loanParamsId];
        return getRequiredCollateral(
            loanParamsLocal.loanToken,
            loanParamsLocal.collateralToken,
            newPrincipal,
            loanParamsLocal.minInitialMargin, // marginAmount
            loanParamsLocal.maxLoanTerm == 0 ? // isTorqueLoan
                true :
                false
        );
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

            if (loanToken == collateralToken) {
                borrowAmount = collateralTokenAmount
                    .mul(WEI_PERCENT_PRECISION)
                    .div(marginAmount);
            } else {
                (uint256 sourceToDestRate, uint256 sourceToDestPrecision) = IPriceFeeds(priceFeeds).queryRate(
                    collateralToken,
                    loanToken
                );
                if (sourceToDestPrecision != 0) {
                    borrowAmount = collateralTokenAmount
                        .mul(WEI_PERCENT_PRECISION)
                        .mul(sourceToDestRate)
                        .div(marginAmount)
                        .div(sourceToDestPrecision);
                }
            }

            uint256 feePercent = isTorqueLoan ?
                borrowingFeePercent :
                tradingFeePercent;
            if (borrowAmount != 0 && feePercent != 0) {
                borrowAmount = borrowAmount
                    .mul(
                        WEI_PERCENT_PRECISION - feePercent // never will overflow
                    )
                    .div(WEI_PERCENT_PRECISION);
            }
        }
    }

    function getBorrowAmountByParams(
        bytes32 loanParamsId,
        uint256 collateralTokenAmount)
        public
        view
        returns (uint256 borrowAmount)
    {
        LoanParams memory loanParamsLocal = loanParams[loanParamsId];
        return getBorrowAmount(
            loanParamsLocal.loanToken,
            loanParamsLocal.collateralToken,
            collateralTokenAmount,
            loanParamsLocal.minInitialMargin, // marginAmount
            loanParamsLocal.maxLoanTerm == 0 ? // isTorqueLoan
                true :
                false
        );
    }

    function _borrowOrTrade(
        LoanParams memory loanParamsLocal,
        bytes32 loanId,
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
        returns (LoanOpenData memory)
    {
        require (loanParamsLocal.collateralToken != loanParamsLocal.loanToken, "collateral/loan match");
        require (initialMargin >= loanParamsLocal.minInitialMargin, "initialMargin too low");

        // maxLoanTerm == 0 indicates a Torqueloan and requres that torqueInterest != 0
        /*require(loanParamsLocal.maxLoanTerm != 0 ||
            sentValues[2] != 0, // torqueInterest
            "invalid interest");*/

        require(loanId != 0, "invalid loanId");

        // initialize loan
        Loan storage loanLocal = _initializeLoan(
            loanParamsLocal,
            loanId,
            initialMargin,
            sentAddresses,
            sentValues
        );

        poolPrincipalTotal[sentAddresses[0]] = poolPrincipalTotal[sentAddresses[0]]
            .add(sentValues[1]); // newPrincipal

        uint256 amount;
        if (isTorqueLoan) {
            require(sentValues[3] == 0, "surplus loan token");

            // fee based off required collateral (amount variable repurposed)
            amount = _getBorrowingFee(collateralAmountRequired);
            if (amount != 0) {
                _payBorrowingFee(
                    sentAddresses[1], // borrower
                    loanId,
                    loanParamsLocal.collateralToken,
                    amount
                );
            }
        } else {
            amount = 0; // repurposed

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
                collateralAmountRequired,
                amount // borrowingFee
            ),
            "collateral insufficient"
        );

        loanLocal.collateral = loanLocal.collateral
            .add(sentValues[4])
            .sub(amount); // borrowingFee

        if (!isTorqueLoan) {
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

        return LoanOpenData({
            loanId: loanId,
            principal: sentValues[1],
            collateral: sentValues[4]
        });
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
            if (isTorqueLoan) {
                loanLocal.startRate = collateralToLoanRate;
            } else {
                loanLocal.startRate = sentValues[3]; // loanToCollateralSwapRate
            }
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
                0,                                              // interestRate (old value: sentValues[0])
                0,                                              // interestDuration (old value: sentValues[2])
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
                0,                                              // interestRate (old value: sentValues[0])
                0,                                              // settlementDate (old value: loanLocal.endTimestamp)
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
        uint256 collateralAmountRequired,
        uint256 borrowingFee)
        internal
        view
        returns (bool)
    {
        // allow at most 2% under-collateralized
        collateralAmountRequired = collateralAmountRequired
            .mul(98 ether)
            .div(100 ether)
            .add(borrowingFee);

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

        sloanLocal = loans[loanId];

        if (sloanLocal.id == 0) {
            // new loan
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

            // interest settlement for new loan
            loanRatePerTokenPaid[loanId] = poolRatePerTokenStored[lender];
        } else {
            // existing loan
            sloanLocal = loans[loanId];
            //require(sloanLocal.active && block.timestamp < sloanLocal.endTimestamp, "loan has ended");
            require(sloanLocal.active, "loan has ended");
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
                .divCeil(WEI_PERCENT_PRECISION);
        } else {
            (uint256 sourceToDestRate, uint256 sourceToDestPrecision) = IPriceFeeds(priceFeeds).queryRate(
                collateralToken,
                loanToken
            );
            if (sourceToDestRate != 0) {
                collateralTokenAmount = newPrincipal
                    .mul(sourceToDestPrecision)
                    .mul(marginAmount)
                    .divCeil(sourceToDestRate * WEI_PERCENT_PRECISION);
            }
        }

        if (isTorqueLoan && collateralTokenAmount != 0) {
            collateralTokenAmount = collateralTokenAmount
                .mul(WEI_PERCENT_PRECISION)
                .divCeil(marginAmount)
                .add(collateralTokenAmount);
        }
    }
}
