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
import "../mixins/LiquidationHelper.sol";
import "../swaps/SwapsUser.sol";


contract LoanMaintenance is State, LoanOpeningsEvents, VaultController, InterestUser, SwapsUser, LiquidationHelper {

    struct LoanReturnData {
        bytes32 loanId;
        address loanToken;
        address collateralToken;
        uint256 principal;
        uint256 collateral;
        uint256 interestOwedPerDay;
        uint256 interestDepositRemaining;
        uint256 minInitialMargin;
        uint256 maintenanceMargin;
        uint256 currentMargin;
        uint256 maxLoanTerm;
        uint256 loanEndTimestamp;
        uint256 maxLiquidatable;
        uint256 maxSeizable;
    }

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
        logicTargets[this.depositCollateral.selector] = target;
        logicTargets[this.withdrawCollateral.selector] = target;
        //logicTargets[this.rolloverLoan.selector] = target;
        logicTargets[this.withdrawAccruedInterest.selector] = target;
        logicTargets[this.extendLoanDuration.selector] = target;
        logicTargets[this.reduceLoanDuration.selector] = target;
        logicTargets[this.getLenderInterestData.selector] = target;
        logicTargets[this.getLoanInterestData.selector] = target;
        logicTargets[this.getUserLoans.selector] = target;
        logicTargets[this.getLoan.selector] = target;
        logicTargets[this.getActiveLoans.selector] = target;
    }

    function depositCollateral(
        bytes32 loanId,
        uint256 depositAmount) // must match msg.value if ether is sent
        external
        payable
        nonReentrant
    {
        require(depositAmount != 0, "depositAmount is 0");
        Loan storage loanLocal = loans[loanId];
        LoanParams storage loanParamsLocal = loanParams[loanLocal.loanParamsId];

        require(loanLocal.active, "loan is closed");
        require(msg.value == 0 || loanParamsLocal.collateralToken == address(wethToken), "wrong asset sent");

        loanLocal.collateral = loanLocal.collateral
            .add(depositAmount);

        if (msg.value == 0) {
            vaultDeposit(
                loanParamsLocal.collateralToken,
                msg.sender,
                depositAmount
            );
        } else {
            require(msg.value == depositAmount, "ether deposit mismatch");
            vaultEtherDeposit(
                msg.sender,
                msg.value
            );
        }
    }

    function withdrawCollateral(
        bytes32 loanId,
        address receiver,
        uint256 withdrawAmount)
        external
        nonReentrant
        returns (uint256 actualWithdrawAmount)
    {
        require(withdrawAmount != 0, "withdrawAmount is 0");
        Loan storage loanLocal = loans[loanId];
        LoanParams storage loanParamsLocal = loanParams[loanLocal.loanParamsId];

        require(loanLocal.active, "loan is closed");
        require(
            msg.sender == loanLocal.borrower ||
            protocolManagers[msg.sender] ||
            delegatedManagers[loanLocal.id][msg.sender],
            "unauthorized"
        );

        uint256 maxDrawdown = IPriceFeeds(priceFeeds).getMaxDrawdown(
            loanParamsLocal.loanToken,
            loanParamsLocal.collateralToken,
            loanLocal.principal,
            loanLocal.collateral,
            loanParamsLocal.maintenanceMargin
        );

        if (withdrawAmount > maxDrawdown) {
            actualWithdrawAmount = maxDrawdown;
        } else {
            actualWithdrawAmount = withdrawAmount;
        }

        loanLocal.collateral = loanLocal.collateral
            .sub(actualWithdrawAmount);

        if (loanParamsLocal.collateralToken == address(wethToken)) {
            vaultEtherWithdraw(
                receiver,
                actualWithdrawAmount
            );
        } else {
            vaultWithdraw(
                loanParamsLocal.collateralToken,
                receiver,
                actualWithdrawAmount
            );
        }
    }

    /*function rolloverLoan(
        bytes32 loanId,
        bytes calldata loanDataBytes)
        external
        nonReentrant
    {
        require(depositAmount != 0, "depositAmount is 0");
        Loan storage loanLocal = loans[loanId];
        LoanParams storage loanParamsLocal = loanParams[loanLocal.loanParamsId];

        require(loanLocal.active, "loan is closed");
        require(
            (
                (
                    msg.sender == loanLocal.borrower || delegatedManagers[loanLocal.id][msg.sender]
                ) && msg.sender == payer <-- get rid of this
            ) || protocolManagers[msg.sender],
            "unauthorized"
        );
        require(loanParamsLocal.maxLoanTerm == 0, "indefinite-term only");
        require(msg.value == 0 || (!useCollateral && loanParamsLocal.loanToken == address(wethToken)), "wrong asset sent");


        LoanInterest storage loanInterestLocal = loanInterest[loanLocal.id];
        LenderInterest storage lenderInterestLocal = lenderInterest[loanLocal.lender][loanParamsLocal.loanToken];

        // pay outstanding interest to lender
        _payInterest(
            lenderInterestLocal,
            loanLocal.lender,
            loanParamsLocal.loanToken
        );

        // deposit interest
        if (useCollateral) {
            // reverts in _swap if amountNeeded can't be bought
            (,uint256 sourceTokenAmountUsed) = _loanSwap(
                loanLocal.borrower,
                loanParamsLocal.collateralToken,
                loanParamsLocal.loanToken,
                loanLocal.collateral,
                depositAmount, // requiredDestTokenAmount (partial spend of loanLocal.collateral to fill this amount)
                0, // minConversionRate
                false, // isLiquidation
                loanDataBytes
            );
            loanLocal.collateral = loanLocal.collateral
                .sub(sourceTokenAmountUsed);

            // ensure the loan is still healthy
            (uint256 currentMargin,) = IPriceFeeds(priceFeeds).getCurrentMargin(
                loanParamsLocal.loanToken,
                loanParamsLocal.collateralToken,
                loanLocal.principal,
                loanLocal.collateral
            );
            require(
                currentMargin > loanParamsLocal.maintenanceMargin,
                "unhealthy position"
            );
        } else {
            if (msg.value == 0) {
                vaultDeposit(
                    loanParamsLocal.loanToken,
                    payer,
                    depositAmount
                );
            } else {
                require(msg.value == depositAmount, "ether deposit mismatch");
                vaultEtherDeposit(
                    msg.sender,
                    msg.value
                );
            }
        }

        secondsExtended = depositAmount
            .mul(86400)
            .div(loanInterestLocal.owedPerDay);

        loanLocal.loanEndTimestamp = loanLocal.loanEndTimestamp
            .add(secondsExtended);

        require (loanLocal.loanEndTimestamp > block.timestamp, "loan too short");

        uint256 maxDuration = loanLocal.loanEndTimestamp
            .sub(block.timestamp);

        // loan term has to at least be 24 hours
        require(maxDuration >= 86400, "loan too short");

        loanInterestLocal.depositTotal = loanInterestLocal.depositTotal
            .add(depositAmount);
        loanInterestLocal.updatedTimestamp = block.timestamp;

        lenderInterestLocal.owedTotal = lenderInterestLocal.owedTotal
            .add(depositAmount);



        if (block.timestamp >= loanLocal.loanEndTimestamp) {
        }

        // Handle back interest
        uint256 backInterestTime = block.timestamp
            .sub(loanLocal.loanEndTimestamp);
        uint256 backInterestOwed = backInterestTime
            .mul(loanInterestLocal.owedPerDay);
        backInterestOwed = backInterestOwed
            .div(86400);
    }*/

    function withdrawAccruedInterest(
        address loanToken)
        external
    {
        LenderInterest storage lenderInterestLocal = lenderInterest[msg.sender][loanToken];
        if (lenderInterestLocal.owedTotal != 0) {
            // pay outstanding interest to lender
            _payInterest(
                lenderInterestLocal,
                msg.sender, // lender
                loanToken
            );
        }
    }

    function extendLoanDuration(
        bytes32 loanId,
        uint256 depositAmount,
        bool useCollateral,
        bytes calldata loanDataBytes)
        external
        payable
        nonReentrant
        returns (uint256 secondsExtended)
    {
        require(depositAmount != 0, "depositAmount is 0");
        Loan storage loanLocal = loans[loanId];
        LoanParams storage loanParamsLocal = loanParams[loanLocal.loanParamsId];

        require(loanLocal.active, "loan is closed");
        require(
            !useCollateral ||
            msg.sender == loanLocal.borrower ||
            protocolManagers[msg.sender] ||
            delegatedManagers[loanLocal.id][msg.sender],
            "unauthorized"
        );
        require(loanParamsLocal.maxLoanTerm == 0, "indefinite-term only");
        require(msg.value == 0 || (!useCollateral && loanParamsLocal.loanToken == address(wethToken)), "wrong asset sent");


        LoanInterest storage loanInterestLocal = loanInterest[loanLocal.id];
        LenderInterest storage lenderInterestLocal = lenderInterest[loanLocal.lender][loanParamsLocal.loanToken];

        // pay outstanding interest to lender
        _payInterest(
            lenderInterestLocal,
            loanLocal.lender,
            loanParamsLocal.loanToken
        );

        // deposit interest
        if (useCollateral) {
            // reverts in _swap if amountNeeded can't be bought
            (,uint256 sourceTokenAmountUsed) = _loanSwap(
                loanLocal.borrower,
                loanParamsLocal.collateralToken,
                loanParamsLocal.loanToken,
                loanLocal.collateral,
                depositAmount, // requiredDestTokenAmount (partial spend of loanLocal.collateral to fill this amount)
                0, // minConversionRate
                false, // isLiquidation
                loanDataBytes
            );
            loanLocal.collateral = loanLocal.collateral
                .sub(sourceTokenAmountUsed);

            // ensure the loan is still healthy
            (uint256 currentMargin,) = IPriceFeeds(priceFeeds).getCurrentMargin(
                loanParamsLocal.loanToken,
                loanParamsLocal.collateralToken,
                loanLocal.principal,
                loanLocal.collateral
            );
            require(
                currentMargin > loanParamsLocal.maintenanceMargin,
                "unhealthy position"
            );
        } else {
            if (msg.value == 0) {
                vaultDeposit(
                    loanParamsLocal.loanToken,
                    msg.sender,
                    depositAmount
                );
            } else {
                require(msg.value == depositAmount, "ether deposit mismatch");
                vaultEtherDeposit(
                    msg.sender,
                    msg.value
                );
            }
        }

        secondsExtended = depositAmount
            .mul(86400)
            .div(loanInterestLocal.owedPerDay);

        loanLocal.loanEndTimestamp = loanLocal.loanEndTimestamp
            .add(secondsExtended);

        require (loanLocal.loanEndTimestamp > block.timestamp, "loan too short");

        uint256 maxDuration = loanLocal.loanEndTimestamp
            .sub(block.timestamp);

        // loan term has to at least be 24 hours
        require(maxDuration >= 86400, "loan too short");

        loanInterestLocal.depositTotal = loanInterestLocal.depositTotal
            .add(depositAmount);
        loanInterestLocal.updatedTimestamp = block.timestamp;

        lenderInterestLocal.owedTotal = lenderInterestLocal.owedTotal
            .add(depositAmount);
    }

    function reduceLoanDuration(
        bytes32 loanId,
        address receiver,
        uint256 withdrawAmount)
        external
        nonReentrant
        returns (uint256 secondsReduced)
    {
        require(withdrawAmount != 0, "withdrawAmount is 0");
        Loan storage loanLocal = loans[loanId];
        LoanParams storage loanParamsLocal = loanParams[loanLocal.loanParamsId];

        require(loanLocal.active, "loan is closed");
        require(
            msg.sender == loanLocal.borrower ||
            delegatedManagers[loanLocal.id][msg.sender] ||
            protocolManagers[msg.sender],
            "unauthorized"
        );
        require(loanParamsLocal.maxLoanTerm == 0, "indefinite-term only");

        LoanInterest storage loanInterestLocal = loanInterest[loanLocal.id];
        LenderInterest storage lenderInterestLocal = lenderInterest[loanLocal.lender][loanParamsLocal.loanToken];

        // pay outstanding interest to lender
        _payInterest(
            lenderInterestLocal,
            loanLocal.lender,
            loanParamsLocal.loanToken
        );

        uint256 interestTime = block.timestamp;
        if (interestTime > loanLocal.loanEndTimestamp) {
            interestTime = loanLocal.loanEndTimestamp;
        }
        uint256 interestDepositRemaining = loanLocal.loanEndTimestamp > interestTime ? loanLocal.loanEndTimestamp.sub(interestTime).mul(loanInterestLocal.owedPerDay).div(86400) : 0;
        require(withdrawAmount < interestDepositRemaining, "withdraw amount too high");

        // withdraw interest
        if (loanParamsLocal.loanToken == address(wethToken)) {
            vaultEtherWithdraw(
                receiver,
                withdrawAmount
            );
        } else {
            vaultWithdraw(
                loanParamsLocal.loanToken,
                receiver,
                withdrawAmount
            );
        }

        secondsReduced = withdrawAmount
            .mul(86400)
            .div(loanInterestLocal.owedPerDay);

        require (loanLocal.loanEndTimestamp > secondsReduced, "loan too short");

        loanLocal.loanEndTimestamp = loanLocal.loanEndTimestamp
            .sub(secondsReduced);

        require (loanLocal.loanEndTimestamp > block.timestamp, "loan too short");

        uint256 maxDuration = loanLocal.loanEndTimestamp
            .sub(block.timestamp);

        // loan term has to at least be 24 hours
        require(maxDuration >= 86400, "loan too short");

        loanInterestLocal.depositTotal = loanInterestLocal.depositTotal
            .add(withdrawAmount);
        loanInterestLocal.updatedTimestamp = block.timestamp;

        lenderInterestLocal.owedTotal = lenderInterestLocal.owedTotal
            .sub(withdrawAmount);
    }

    /// @dev Gets current lender interest data totals for all loans with a specific oracle and interest token
    /// @param lender The lender address
    /// @param loanToken The loan token address
    /// @return interestPaid The total amount of interest that has been paid to a lender so far
    /// @return interestPaidDate The date of the last interest pay out, or 0 if no interest has been withdrawn yet
    /// @return interestOwedPerDay The amount of interest the lender is earning per day
    /// @return interestUnPaid The total amount of interest the lender is owned and not yet withdrawn
    /// @return principalTotal The total amount of outstading principal the lender has loaned
    function getLenderInterestData(
        address lender,
        address loanToken)
        external
        view
        returns (
            uint256 interestPaid,
            uint256 interestPaidDate,
            uint256 interestOwedPerDay,
            uint256 interestUnPaid,
            uint256 principalTotal)
    {
        LenderInterest memory lenderInterestLocal = lenderInterest[lender][loanToken];

        interestUnPaid = block.timestamp.sub(lenderInterestLocal.updatedTimestamp).mul(lenderInterestLocal.owedPerDay).div(86400);
        if (interestUnPaid > lenderInterestLocal.owedTotal)
            interestUnPaid = lenderInterestLocal.owedTotal;

        return (
            lenderInterestLocal.paidTotal,
            lenderInterestLocal.paidTotal > 0 ? lenderInterestLocal.updatedTimestamp : 0,
            lenderInterestLocal.owedPerDay,
            lenderInterestLocal.updatedTimestamp > 0 ? interestUnPaid : 0,
            lenderInterestLocal.principalTotal
        );
    }

    /// @dev Gets current interest data for a loan
    /// @param loanId A unique id representing the loan
    /// @return loanToken The loan token that interest is paid in
    /// @return interestOwedPerDay The amount of interest the borrower is paying per day
    /// @return interestDepositTotal The total amount of interest the borrower has deposited
    /// @return interestDepositRemaining The amount of deposited interest that is not yet owed to a lender
    function getLoanInterestData(
        bytes32 loanId)
        external
        view
        returns (
            address loanToken,
            uint256 interestOwedPerDay,
            uint256 interestDepositTotal,
            uint256 interestDepositRemaining)
    {
        loanToken = loanParams[loans[loanId].loanParamsId].loanToken;
        interestOwedPerDay = loanInterest[loanId].owedPerDay;
        interestDepositTotal = loanInterest[loanId].depositTotal;

        uint256 loanEndTimestamp = loans[loanId].loanEndTimestamp;
        uint256 interestTime = block.timestamp > loanEndTimestamp ?
            loanEndTimestamp :
            block.timestamp;
        interestDepositRemaining = loanEndTimestamp > interestTime ?
            loanEndTimestamp
                .sub(interestTime)
                .mul(interestOwedPerDay)
                .div(86400) :
                0;
    }

    // Only returns data for loans that are active
    // loanType 0: all loans
    // loanType 1: margin trade loans
    // loanType 2: non-margin trade loans
    // only active loans are returned
    function getUserLoans(
        address user,
        uint256 start,
        uint256 count,
        uint256 loanType,
        bool isLender,
        bool unsafeOnly)
        external
        view
        returns (LoanReturnData[] memory loansData)
    {
        EnumerableBytes32Set.Bytes32Set storage set = isLender ?
            lenderLoanSets[user] :
            borrowerLoanSets[user];

        uint256 end = count.min256(set.values.length);
        if (end == 0 || start >= end) {
            return loansData;
        }

        loansData = new LoanReturnData[](count);
        uint256 itemCount;
        for (uint256 i = end-start; i > 0; i--) {
            if (itemCount == count) {
                break;
            }
            LoanReturnData memory loanData = _getLoan(
                set.get(i+start-1), // loanId
                loanType,
                unsafeOnly
            );
            if (loanData.loanId == 0)
                continue;

            loansData[itemCount] = loanData;
            itemCount++;
        }

        if (itemCount < count) {
            assembly {
                mstore(loansData, itemCount)
            }
        }
    }

    function getLoan(
        bytes32 loanId)
        external
        view
        returns (LoanReturnData memory loanData)
    {
        return _getLoan(
            loanId,
            0, // loanType
            false // unsafeOnly
        );
    }

    function getActiveLoans(
        uint256 start,
        uint256 count,
        bool unsafeOnly)
        external
        view
        returns (LoanReturnData[] memory loansData)
    {
        uint256 end = count.min256(activeLoansSet.values.length);
        if (end == 0 || start >= end) {
            return loansData;
        }

        loansData = new LoanReturnData[](count);
        uint256 itemCount;
        for (uint256 i = end-start; i > 0; i--) {
            if (itemCount == count) {
                break;
            }
            LoanReturnData memory loanData = _getLoan(
                activeLoansSet.get(i+start-1), // loanId
                0, // loanType
                unsafeOnly
            );
            if (loanData.loanId == 0)
                continue;

            loansData[itemCount] = loanData;
            itemCount++;
        }

        if (itemCount < count) {
            assembly {
                mstore(loansData, itemCount)
            }
        }
    }

    function _getLoan(
        bytes32 loanId,
        uint256 loanType,
        bool unsafeOnly)
        internal
        view
        returns (LoanReturnData memory loanData)
    {
        Loan memory loanLocal = loans[loanId];
        LoanParams memory loanParamsLocal = loanParams[loanLocal.loanParamsId];

        if (loanType != 0) {
            if (!(
                (loanType == 1 && loanParamsLocal.maxLoanTerm != 0) ||
                (loanType == 2 && loanParamsLocal.maxLoanTerm == 0)
            )) {
                return loanData;
            }
        }

        LoanInterest memory loanInterestLocal = loanInterest[loanId];

        (uint256 currentMargin, uint256 collateralToLoanRate) = IPriceFeeds(priceFeeds).getCurrentMargin(
            loanParamsLocal.loanToken,
            loanParamsLocal.collateralToken,
            loanLocal.principal,
            loanLocal.collateral
        );

        uint256 maxLiquidatable;
        uint256 maxSeizable;
        uint256 incentivePercent;
        if (currentMargin > loanParamsLocal.maintenanceMargin) {
            if (unsafeOnly) {
                return loanData;
            } else {
                (maxLiquidatable, maxSeizable, incentivePercent) = _getLiquidationAmounts(
                    loanLocal.principal,
                    loanLocal.collateral,
                    currentMargin,
                    loanParamsLocal.maintenanceMargin,
                    collateralToLoanRate
                );
            }
        }

        return LoanReturnData({
            loanId: loanId,
            loanToken: loanParamsLocal.loanToken,
            collateralToken: loanParamsLocal.collateralToken,
            principal: loanLocal.principal,
            collateral: loanLocal.collateral,
            interestOwedPerDay: loanInterestLocal.owedPerDay,
            interestDepositRemaining: loanLocal.loanEndTimestamp >= block.timestamp ? loanLocal.loanEndTimestamp.sub(block.timestamp).mul(loanInterestLocal.owedPerDay).div(86400) : 0,
            minInitialMargin: loanParamsLocal.minInitialMargin,
            maintenanceMargin: loanParamsLocal.maintenanceMargin,
            currentMargin: currentMargin,
            maxLoanTerm: loanParamsLocal.maxLoanTerm,
            loanEndTimestamp: loanLocal.loanEndTimestamp,
            maxLiquidatable: maxLiquidatable,
            maxSeizable: maxSeizable
        });
    }
}
