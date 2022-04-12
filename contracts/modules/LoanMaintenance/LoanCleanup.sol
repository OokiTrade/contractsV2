/**
 * Copyright 2017-2022, OokiDao. All Rights Reserved.
 * Licensed under the Apache License, Version 2.0.
 */

pragma solidity 0.5.17;
pragma experimental ABIEncoderV2;

import "../../core/State.sol";
import "../../mixins/VaultController.sol";
import "../../mixins/InterestUser.sol";


contract LoanCleanup is State, VaultController, InterestUser {

    function initialize(
        address target)
        external
        onlyOwner
    {
        _setTarget(this.cleanupLoans.selector, target);
    }

    function cleanupLoans(
        address loanToken,
        bytes32[] calldata loanIds)
        external
        payable
        onlyOwner
        returns (uint256 totalPrincipalIn)
    {
        for (uint256 i = 0; i < loanIds.length; i++) {
            Loan memory loanLocal = loans[loanIds[i]];

            uint256 payoffNeeded = loanLocal.principal;

            if (!loanLocal.active || payoffNeeded == 0)
                continue;

            require(loanToken == loanParams[loanLocal.loanParamsId].loanToken, "wrong token");

            // pay outstanding interest to lender
            _payInterest(
                loanLocal.lender,
                loanToken
            );

            LoanInterest storage loanInterestLocal = loanInterest[loanLocal.id];
            LenderInterest storage lenderInterestLocal = lenderInterest[loanLocal.lender][loanToken];
            
            lenderInterestLocal.principalTotal = lenderInterestLocal.principalTotal
                .sub(payoffNeeded);

            uint256 owedPerDayRefund = loanInterestLocal.owedPerDay;
            loanInterestLocal.owedPerDay = 0;

            lenderInterestLocal.owedPerDay = lenderInterestLocal.owedPerDay
                .sub(owedPerDayRefund);

            uint256 interestAvailable;
            if (block.timestamp < loanLocal.endTimestamp) {
                interestAvailable = loanLocal.endTimestamp
                    .sub(block.timestamp);
                interestAvailable = interestAvailable
                    .mul(owedPerDayRefund);
                interestAvailable = interestAvailable
                    .div(24 hours);
            }

            if (interestAvailable >= payoffNeeded) {
                vaultWithdraw(
                    loanToken,
                    loanLocal.lender,
                    payoffNeeded
                );
                vaultWithdraw(
                    loanToken,
                    loanLocal.borrower,
                    interestAvailable-payoffNeeded
                );
            } else {
                if (interestAvailable != 0) {
                    vaultWithdraw(
                        loanToken,
                        loanLocal.lender,
                        interestAvailable
                    );
                    payoffNeeded -= interestAvailable;
                }
                vaultTransfer(
                    loanToken,
                    msg.sender,
                    loanLocal.lender,
                    payoffNeeded
                );
                totalPrincipalIn += payoffNeeded;
            }
            loanInterestLocal.depositTotal = 0;
            loanInterestLocal.updatedTimestamp = block.timestamp;

            uint256 collateral = loanLocal.collateral;
            if (collateral != 0) {
                vaultWithdraw(
                    loanParams[loanLocal.loanParamsId].collateralToken,
                    msg.sender,
                    collateral
                );
                loanLocal.collateral = 0;
            }

            // loanLocal.collateral = 0; // should already be 0
            loanLocal.principal = 0;
            loanLocal.active = false;
            loanLocal.endTimestamp = block.timestamp;
            // loanLocal.pendingTradesId = 0; // should already be 0
            activeLoansSet.removeBytes32(loanLocal.id);
            lenderLoanSets[loanLocal.lender].removeBytes32(loanLocal.id);
            borrowerLoanSets[loanLocal.borrower].removeBytes32(loanLocal.id);

            loans[loanLocal.id] = loanLocal;
        }
    }
}