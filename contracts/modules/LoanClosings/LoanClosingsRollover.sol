/**
 * Copyright 2017-2021, bZeroX, LLC. All Rights Reserved.
 * Licensed under the Apache License, Version 2.0.
 */

pragma solidity 0.5.17;
pragma experimental ABIEncoderV2;

import "./LoanClosingsBase.sol";


contract LoanClosingsRollover is LoanClosingsBase {

    function initialize(
        address target)
        external
        onlyOwner
    {
        _setTarget(this.rollover.selector, target);
    }

    function rollover(
        bytes32 loanId,
        bytes calldata /*loanDataBytes*/) // for future use
        external
        nonReentrant
        returns (
            address rebateToken,
            uint256 gasRebate
        )
    {
        uint256 startingGas = gasleft() +
            21576; // estimated used gas ignoring loanDataBytes: 21000 + (4+32) * 16

        return _rollover(
            loanId,
            startingGas,
            "" // loanDataBytes
        );
    }

    function _rollover(
        bytes32 loanId,
        uint256 startingGas,
        bytes memory loanDataBytes)
        internal
        returns (
            address rebateToken,
            uint256 gasRebate
        )
    {
        Loan memory loanLocal = loans[loanId];
        require(loanLocal.active, "loan is closed");
        require(
            block.timestamp > loanLocal.endTimestamp.sub(1 hours),
            "healthy position"
        );

        LoanParams memory loanParamsLocal = loanParams[loanLocal.loanParamsId];
        uint256 maxDuration = loanParamsLocal.maxLoanTerm;

        if (maxDuration != 0) {
            // margin positions need to close
            return _rolloverClose(
                loanLocal,
                startingGas,
                loanDataBytes
            );
        }

        require(
            loanPoolToUnderlying[loanLocal.lender] != address(0),
            "invalid lender"
        );

        // pay outstanding interest to lender
        _payInterest(
            loanLocal.lender,
            loanParamsLocal.loanToken
        );

        LoanInterest storage loanInterestLocal = loanInterest[loanLocal.id];
        LenderInterest storage lenderInterestLocal = lenderInterest[loanLocal.lender][loanParamsLocal.loanToken];

        _settleFeeRewardForInterestExpense(
            loanInterestLocal,
            loanLocal.id,
            loanParamsLocal.loanToken,
            loanLocal.borrower,
            block.timestamp
        );

        // Handle back interest: calculates interest owned since the loan endtime passed but the loan remained open
        uint256 backInterestTime;
        uint256 backInterestOwed;
        if (block.timestamp > loanLocal.endTimestamp) {
            backInterestTime = block.timestamp
                .sub(loanLocal.endTimestamp);
            backInterestOwed = backInterestTime
                .mul(loanInterestLocal.owedPerDay);
            backInterestOwed = backInterestOwed
                .div(24 hours);
        }

        // loanInterestLocal.owedPerDay doesn't change
        maxDuration = ONE_MONTH;

        if (backInterestTime >= maxDuration) {
            maxDuration = backInterestTime
                .add(24 hours); // adds an extra 24 hours
        }

        // update loan end time
        loanLocal.endTimestamp = loanLocal.endTimestamp
            .add(maxDuration);

        uint256 interestAmountRequired = loanLocal.endTimestamp
            .sub(block.timestamp);
        interestAmountRequired = interestAmountRequired
            .mul(loanInterestLocal.owedPerDay);
        interestAmountRequired = interestAmountRequired
            .div(24 hours);

        loanInterestLocal.depositTotal = loanInterestLocal.depositTotal
            .add(interestAmountRequired);

        lenderInterestLocal.owedTotal = lenderInterestLocal.owedTotal
            .add(interestAmountRequired);

        // add backInterestOwed
        interestAmountRequired = interestAmountRequired
            .add(backInterestOwed);

        // collect interest
        (,uint256 sourceTokenAmountUsed,) = _doCollateralSwap(
            loanLocal,
            loanParamsLocal,
            loanLocal.collateral,
            interestAmountRequired,
            true, // returnTokenIsCollateral
            ""
        );
        loanLocal.collateral = loanLocal.collateral
            .sub(sourceTokenAmountUsed);

        if (backInterestOwed != 0) {
            // pay out backInterestOwed

            _payInterestTransfer(
                loanLocal.lender,
                loanParamsLocal.loanToken,
                backInterestOwed
            );
        }

        if (msg.sender != loanLocal.borrower) {
            gasRebate = _getRebate(
                loanParamsLocal.collateralToken,
                loanLocal.collateral,
                startingGas
            );
            if (gasRebate != 0) {
                // pay out gas rebate to caller
                // the preceeding logic should ensure gasRebate <= collateral, but just in case, will use SafeMath here
                loanLocal.collateral = loanLocal.collateral
                    .sub(gasRebate, "gasRebate too high");

                rebateToken = loanParamsLocal.collateralToken;

                _withdrawAsset(
                    rebateToken,
                    msg.sender,
                    gasRebate
                );
            }
        }

        _finalizeRollover(
            loanLocal,
            loanParamsLocal,
            sourceTokenAmountUsed,
            interestAmountRequired,
            gasRebate
        );
    }

    function _rolloverClose(
        Loan memory loanLocal,
        uint256 startingGas,
        bytes memory loanDataBytes)
        internal
        returns (
            address rebateToken,
            uint256 gasRebate
        )
    {
        uint256 withdrawAmount;
        bool isDelegateManager = delegatedManagers[loanLocal.id][msg.sender];
        if (!isDelegateManager) {
            delegatedManagers[loanLocal.id][msg.sender] = true;
        }
        (, withdrawAmount, rebateToken) = _closeWithSwap(
            loanLocal.id,
            address(this),  // receiver
            uint256(-1),    // swapAmount
            true,           // returnTokenIsCollateral
            loanDataBytes
        );
        if (!isDelegateManager) {
            delete delegatedManagers[loanLocal.id][msg.sender];
        }

        if (msg.sender != loanLocal.borrower) {
            gasRebate = _getRebate(
                rebateToken, // collateralToken,
                withdrawAmount, // collateral,
                startingGas
            );
            if (gasRebate != 0) {
                // pay out gas rebate to caller
                // the preceeding logic should ensure gasRebate <= collateral, but just in case, will use SafeMath here
                withdrawAmount = withdrawAmount
                    .sub(gasRebate, "gasRebate too high");

                _withdrawAsset(
                    rebateToken,
                    msg.sender,
                    gasRebate
                );
            }
        }

        _withdrawAsset(
            rebateToken,
            loanLocal.borrower,
            withdrawAmount
        );
    }

    function _finalizeRollover(
        Loan memory loanLocal,
        LoanParams memory loanParamsLocal,
        uint256 sourceTokenAmountUsed,
        uint256 interestAmountRequired,
        uint256 gasRebate)
        internal
    {
        emit Rollover(
            loanLocal.borrower,                 // user (borrower)
            msg.sender,                         // caller
            loanLocal.id,                       // loanId
            loanLocal.lender,                   // lender
            loanParamsLocal.loanToken,          // loanToken
            loanParamsLocal.collateralToken,    // collateralToken
            sourceTokenAmountUsed,              // collateralAmountUsed
            interestAmountRequired,             // interestAmountAdded
            loanLocal.endTimestamp,             // loanEndTimestamp
            gasRebate                           // gasRebate
        );

        loans[loanLocal.id] = loanLocal;
    }
}
