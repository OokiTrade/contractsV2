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
        uint256 initialMargin;
        uint256 maintenanceMargin;
        uint256 currentMargin;
        uint256 fixedLoanTerm;
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

    // extendLoanByInterest(bytes32,address,uint256,bool,bytes)
    function extendLoanByInterest(
        bytes32 loanId,
        address payer,
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
            (
                (
                    msg.sender == loanLocal.borrower || delegatedManagers[loanLocal.id][msg.sender]
                ) && msg.sender == payer
            ) || protocolManagers[msg.sender],
            "unauthorized"
        );
        require(loanParamsLocal.fixedLoanTerm == 0, "indefinite-term only");
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
                // TODO: how to handle too much ether sent?
                require(msg.value >= depositAmount, "not enough ether");
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

    // reduceLoanByInterest(bytes32,address,address,uint256)
    function reduceLoanByInterest(
        bytes32 loanId,
        address borrower,
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
        require(loanParamsLocal.fixedLoanTerm == 0, "indefinite-term only");

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

    // Only returns data for loans that are active
    // loanType 0: all loans
    // loanType 1: margin trade loans
    // loanType 2: non-margin trade loans
    // only active loans are returned
    // getUserLoans(address,uint256,uint256,uint256,bool,bool)
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
        for (uint256 i=end-start; i > 0; i--) {
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

    // getLoan(bytes32)
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

    // getActiveLoans(uint256,uint256,bool)
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
        for (uint256 i=end-start; i > 0; i--) {
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
                (loanType == 1 && loanParamsLocal.fixedLoanTerm != 0) ||
                (loanType == 2 && loanParamsLocal.fixedLoanTerm == 0)
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
                    loanParamsLocal.initialMargin,
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
            initialMargin: loanParamsLocal.initialMargin,
            maintenanceMargin: loanParamsLocal.maintenanceMargin,
            currentMargin: currentMargin,
            fixedLoanTerm: loanParamsLocal.fixedLoanTerm,
            loanEndTimestamp: loanLocal.loanEndTimestamp,
            maxLiquidatable: maxLiquidatable,
            maxSeizable: maxSeizable
        });
    }
}
