/**
 * Copyright 2017-2022, OokiDao. All Rights Reserved.
 * Licensed under the Apache License, Version 2.0.
 */

pragma solidity 0.5.17;

import "../LoanClosings/LoanClosingsBase.sol";


contract TmpAdminClosings is LoanClosingsBase {

    function initialize(
        address target)
        external
        onlyOwner
    {
        _setTarget(this.tmpAdminCloseWithSwap.selector, target);
        _setTarget(this.tmpAdminCloseWithSwapBatch.selector, target);
        _setTarget(this.tmpAdminCloseWithDeposit.selector, target);
        _setTarget(this.tmpAdminCloseWithDepositBatch.selector, target);
        _setTarget(this.tmpAdminForceClose.selector, target);
        _setTarget(this.tmpAdminForceCloseBatch.selector, target);
    }

    function tmpAdminCloseWithSwap(
        bytes32 loanId,
        uint256 swapAmount, // denominated in collateralToken
        bool returnTokenIsCollateral,
        bytes memory loanDataBytes)
        public
        onlyOwner
        returns (
            uint256 loanCloseAmount,
            uint256 withdrawAmount,
            address withdrawToken
        )
    {
        bool isDelegated = delegatedManagers[loanId][msg.sender];
        if (!isDelegated) {
            delegatedManagers[loanId][msg.sender] = true;
        }

        (loanCloseAmount, withdrawAmount, withdrawToken) = super._closeWithSwap(
            loanId,
            msg.sender, // receiver
            swapAmount, // denominated in collateralToken
            returnTokenIsCollateral, // true: withdraws collateralToken, false: withdraws loanToken
            loanDataBytes
        );

        if (!isDelegated) {
            delegatedManagers[loanId][msg.sender] = false;
        }
    }

    function tmpAdminCloseWithSwapBatch(
        bytes32[] calldata loanIds)
        external
        onlyOwner
    {
        for (uint256 i = 0; i < loanIds.length; i++) {
            tmpAdminCloseWithSwap(
                loanIds[i],
                uint256(-1),
                true,
                ""
            );
        }
    }

    function tmpAdminCloseWithDeposit(
        bytes32 loanId,
        uint256 depositAmount)
        public
        payable
        onlyOwner
        returns (
            uint256 loanCloseAmount,
            uint256 withdrawAmount,
            address withdrawToken
        )
    {
        bool isDelegated = delegatedManagers[loanId][msg.sender];
        if (!isDelegated) {
            delegatedManagers[loanId][msg.sender] = true;
        }

        (loanCloseAmount, withdrawAmount, withdrawToken) = super._closeWithDeposit(
            loanId,
            msg.sender,
            depositAmount
        );

        if (!isDelegated) {
            delegatedManagers[loanId][msg.sender] = false;
        }
    }

    function tmpAdminCloseWithDepositBatch(
        bytes32[] calldata loanIds)
        external
        payable
        onlyOwner
    {
        for (uint256 i = 0; i < loanIds.length; i++) {
            tmpAdminCloseWithDeposit(
                loanIds[i],
                uint256(-1)
            );
        }
    }

    // this can break things (lender doesn't get paid back)
    // only use if absolutely necessary to clear stuck loans in a test environment!
    function tmpAdminForceClose(
        bytes32 loanId)
        public
        onlyOwner
    {
        Loan storage loanLocal = loans[loanId];
        LoanParams storage loanParamsLocal = loanParams[loanLocal.loanParamsId];
        require(loanLocal.active, "loan is closed");

        _withdrawAsset(
            loanParamsLocal.collateralToken,
            msg.sender,
            loanLocal.collateral
        );
        loanLocal.collateral = 0;

        _settleInterestToPrincipal(
            loanLocal,
            loanParamsLocal,
            loanLocal.principal,
            msg.sender
        );
        loanLocal.principal = 0;
        loanLocal.active = false;
        loanLocal.endTimestamp = block.timestamp;
        loanLocal.pendingTradesId = 0;
        activeLoansSet.removeBytes32(loanLocal.id);
        lenderLoanSets[loanLocal.lender].removeBytes32(loanLocal.id);
        borrowerLoanSets[loanLocal.borrower].removeBytes32(loanLocal.id);
    }

    function tmpAdminForceCloseBatch(
        bytes32[] calldata loanIds)
        external
        onlyOwner
    {
        for (uint256 i = 0; i < loanIds.length; i++) {
            tmpAdminForceClose(
                loanIds[i]
            );
        }
    }
}
