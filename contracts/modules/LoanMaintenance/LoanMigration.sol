/**
 * Copyright 2017-2022, OokiDao. All Rights Reserved.
 * Licensed under the Apache License, Version 2.0.
 */

pragma solidity 0.5.17;
pragma experimental ABIEncoderV2;

import "../../core/State.sol";
import "../../mixins/VaultController.sol";
import "../../mixins/InterestHandler.sol";
import "../../mixins/InterestUser.sol";


contract LoanMigration is State, VaultController, InterestHandler, InterestUser {

    function initialize(
        address target)
        external
        onlyOwner
    {
        _setTarget(this.migrateLoans.selector, target);

        // TEMP: remove after upgrade
        _setTarget(bytes4(keccak256("cleanupLoans(address,bytes32[])")), address(0));
    }

    function migrateLoans(
        address lender,
        uint256 start,
        uint256 count)
        external
        onlyOwner
    {
        address loanToken = loanPoolToUnderlying[lender];
        require(loanToken != address(0), "invalid lender");

        // pay outstanding interest to lender
        _payInterest(
            lender,
            loanToken
        );

        LenderInterest storage lenderInterestLocal = lenderInterest[lender][loanToken];

        uint256 owedPerDayRefundTotal;
        uint256 interestRefundTotal;
        uint256 principalTotal;

        EnumerableBytes32Set.Bytes32Set storage set = lenderLoanSets[lender];
        uint256 end = start.add(count).min256(set.length());
        require(start <= end, "start after end");
        for (uint256 i = start; i < end; i++) {
            (uint256 interestRefund, uint256 owedPerDayRefund, uint256 principal) = _migrateLoan(
                set.get(i),
                lender
            );

            interestRefundTotal = interestRefundTotal.add(interestRefund);
            owedPerDayRefundTotal = owedPerDayRefundTotal.add(owedPerDayRefund);
            principalTotal = principalTotal.add(principal);
        }

        lenderInterestLocal.owedPerDay = lenderInterestLocal.owedPerDay
            .sub(owedPerDayRefundTotal);

        if (interestRefundTotal != 0) {
            uint256 owedTotal = lenderInterestLocal.owedTotal;
            if (interestRefundTotal > owedTotal)
	            interestRefundTotal = owedTotal;

            lenderInterestLocal.owedTotal -= interestRefundTotal;

            // refund overage
            vaultWithdraw(
                loanToken,
                lender,
                interestRefundTotal
            );
        }

        lenderInterestLocal.principalTotal = lenderInterestLocal.principalTotal
            .sub(principalTotal)
            .sub(interestRefundTotal);

        poolPrincipalTotal[lender] = poolPrincipalTotal[lender]
            .add(principalTotal);
    }
            
    function _migrateLoan(
        bytes32 loanId,
        address lender)
        internal
        returns (uint256 interestRefund, uint256 owedPerDayRefund, uint256 principal)
    {
        Loan memory loanLocal = loans[loanId];
        LoanInterest storage loanInterestLocal = loanInterest[loanId];

        owedPerDayRefund = loanInterestLocal.owedPerDay;
        if (owedPerDayRefund == 0) {
            return (0, 0, 0);
        }

        if (block.timestamp < loanLocal.endTimestamp) {
            interestRefund = loanLocal.endTimestamp
                .sub(block.timestamp);
            interestRefund = interestRefund
                .mul(owedPerDayRefund);
            interestRefund = interestRefund
                .div(24 hours);
        }
        loanInterestLocal.owedPerDay = 0;
        loanInterestLocal.depositTotal = 0;
        
        principal = loanLocal.principal;

        // interest settlement for new loan
        loanRatePerTokenPaid[loanId] = poolRatePerTokenStored[lender];
    }
}