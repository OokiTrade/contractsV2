/**
 * Copyright 2017-2022, OokiDao. All Rights Reserved.
 * Licensed under the Apache License, Version 2.0.
 */

pragma solidity 0.5.17;
pragma experimental ABIEncoderV2;

import "../../core/State.sol";
import "../../events/LoanMaintenanceEvents.sol";
import "../../mixins/VaultController.sol";
import "../../mixins/InterestHandler.sol";
import "../../mixins/LiquidationHelper.sol";
import "../../swaps/SwapsUser.sol";
import "../../governance/PausableGuardian.sol";


contract LoanMaintenance_Arbitrum is State, LoanMaintenanceEvents, VaultController, InterestHandler, SwapsUser, LiquidationHelper, PausableGuardian {

    function initialize(
        address target)
        external
        onlyOwner
    {
        _setTarget(this.depositCollateral.selector, target);
        _setTarget(this.withdrawCollateral.selector, target);
        _setTarget(this.setDepositAmount.selector, target);
        _setTarget(this.claimRewards.selector, target);
        _setTarget(this.rewardsBalanceOf.selector, target);
        _setTarget(this.getUserLoans.selector, target);
        _setTarget(this.getUserLoansCount.selector, target);
        _setTarget(this.getLoan.selector, target);
        _setTarget(this.getActiveLoans.selector, target);
        _setTarget(this.getActiveLoansAdvanced.selector, target);
        _setTarget(this.getActiveLoansCount.selector, target);

        // TEMP: remove after upgrade
        _setTarget(bytes4(keccak256("withdrawAccruedInterest(address)")), address(0));
        _setTarget(bytes4(keccak256("extendLoanDuration(bytes32,uint256,bool,bytes)")), address(0));
        _setTarget(bytes4(keccak256("reduceLoanDuration(bytes32,address,uint256)")), address(0));
        _setTarget(bytes4(keccak256("getLenderInterestData(address,address)")), address(0));
        _setTarget(bytes4(keccak256("getLoanInterestData(bytes32)")), address(0));
    }

    function depositCollateral(
        bytes32 loanId,
        uint256 depositAmount) // must match msg.value if ether is sent
        external
        payable
        nonReentrant
        pausable
    {
        require(depositAmount != 0, "depositAmount is 0");

        Loan storage loanLocal = loans[loanId];
        require(loanLocal.active, "loan is closed");

        LoanParams storage loanParamsLocal = loanParams[loanLocal.loanParamsId];

        address collateralToken = loanParamsLocal.collateralToken;
        uint256 collateral = loanLocal.collateral;

        require(msg.value == 0 || collateralToken == address(wethToken), "wrong asset sent");

        collateral = collateral
            .add(depositAmount);
        loanLocal.collateral = collateral;

        if (msg.value == 0) {
            vaultDeposit(
                collateralToken,
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

        // update deposit amount
        (uint256 collateralToLoanRate, uint256 collateralToLoanPrecision) = IPriceFeeds(priceFeeds).queryRate(
            collateralToken,
            loanParamsLocal.loanToken
        );
        if (collateralToLoanRate != 0) {
            _setDepositAmount(
                loanId,
                depositAmount
                    .mul(collateralToLoanRate)
                    .div(collateralToLoanPrecision),
                depositAmount,
                false // isSubtraction
            );
        }

        emit DepositCollateral(
            loanLocal.borrower,
            collateralToken,
            loanId,
            depositAmount
        );
    }

    function withdrawCollateral(
        bytes32 loanId,
        address receiver,
        uint256 withdrawAmount)
        external
        nonReentrant
        pausable
        returns (uint256 actualWithdrawAmount)
    {
        require(withdrawAmount != 0, "withdrawAmount is 0");
        Loan storage loanLocal = loans[loanId];
        LoanParams storage loanParamsLocal = loanParams[loanLocal.loanParamsId];

        require(loanLocal.active, "loan is closed");
        require(
            msg.sender == loanLocal.borrower ||
            delegatedManagers[loanLocal.id][msg.sender],
            "unauthorized"
        );

        address collateralToken = loanParamsLocal.collateralToken;
        uint256 collateral = loanLocal.collateral;

        uint256 maxDrawdown = IPriceFeeds(priceFeeds).getMaxDrawdown(
            loanParamsLocal.loanToken,
            collateralToken,
            loanLocal.principal,
            collateral,
            loanParamsLocal.maintenanceMargin
        );

        if (withdrawAmount > maxDrawdown) {
            actualWithdrawAmount = maxDrawdown;
        } else {
            actualWithdrawAmount = withdrawAmount;
        }

        collateral = collateral
            .sub(actualWithdrawAmount, "withdrawAmount too high");
        loanLocal.collateral = collateral;

        /*if (collateralToken == address(wethToken)) {
            vaultEtherWithdraw(
                receiver,
                actualWithdrawAmount
            );
        } else {
            vaultWithdraw(
                collateralToken,
                receiver,
                actualWithdrawAmount
            );
        }*/
        // Arbitrum has issues with eth withdraw from weth
        vaultWithdraw(
            collateralToken,
            receiver,
            actualWithdrawAmount
        );

        // update deposit amount
        (uint256 collateralToLoanRate, uint256 collateralToLoanPrecision) = IPriceFeeds(priceFeeds).queryRate(
            collateralToken,
            loanParamsLocal.loanToken
        );
        if (collateralToLoanRate != 0) {
            _setDepositAmount(
                loanId,
                actualWithdrawAmount
                    .mul(collateralToLoanRate)
                    .div(collateralToLoanPrecision),
                actualWithdrawAmount,
                true // isSubtraction
            );
        }

        emit WithdrawCollateral(
            loanLocal.borrower,
            collateralToken,
            loanId,
            actualWithdrawAmount
        );
    }

    function setDepositAmount(
        bytes32 loanId,
        uint256 depositValueAsLoanToken,
        uint256 depositValueAsCollateralToken)
        external
    {
        // only callable by loan pools
        require(loanPoolToUnderlying[msg.sender] != address(0), "not authorized");

        _setDepositAmount(
            loanId,
            depositValueAsLoanToken,
            depositValueAsCollateralToken,
            false // isSubtraction
        );
    }

    function claimRewards(
        address receiver)
        external
        pausable
        returns (uint256 claimAmount)
    {
        bytes32 slot = keccak256(abi.encodePacked(msg.sender, UserRewardsID));
        assembly {
            claimAmount := sload(slot)
        }

        if (claimAmount != 0) {
            assembly {
                sstore(slot, 0)
            }

            protocolTokenPaid = protocolTokenPaid
                .add(claimAmount);

            IERC20(vbzrxTokenAddress).transfer(
                receiver,
                claimAmount
            );

            emit ClaimReward(
                msg.sender,
                receiver,
                vbzrxTokenAddress,
                claimAmount
            );
        }
    }

    function rewardsBalanceOf(
        address user)
        external
        view
        returns (uint256 rewardsBalance)
    {
        bytes32 slot = keccak256(abi.encodePacked(user, UserRewardsID));
        assembly {
            rewardsBalance := sload(slot)
        }
    }

    // Only returns data for loans that are active
    // All(0): all loans
    // Margin(1): margin trade loans
    // NonMargin(2): non-margin trade loans
    // only active loans are returned
    function getUserLoans(
        address user,
        uint256 start,
        uint256 count,
        LoanType loanType,
        bool isLender,
        bool unsafeOnly)
        external
        view
        returns (LoanReturnData[] memory loansData)
    {
        EnumerableBytes32Set.Bytes32Set storage set = isLender ?
            lenderLoanSets[user] :
            borrowerLoanSets[user];

        uint256 end = start.add(count).min256(set.length());
        if (start >= end) {
            return loansData;
        }
        count = end-start;

        uint256 idx = count;
        LoanReturnData memory loanData;
        loansData = new LoanReturnData[](idx);
        for (uint256 i = --end; i >= start; i--) {
            loanData = _getLoan(
                set.get(i), // loanId
                loanType,
                unsafeOnly
            );
            if (loanData.loanId == 0) {
                if (i == 0) {
                    break;
                } else {
                    continue;
                }
            }

            loansData[count-(idx--)] = loanData;

            if (i == 0) {
                break;
            }
        }

        if (idx != 0) {
            count -= idx;
            assembly {
                mstore(loansData, count)
            }
        }
    }

    function getUserLoansCount(
        address user,
        bool isLender)
        external
        view
        returns (uint256)
    {
        return isLender ?
            lenderLoanSets[user].length() :
            borrowerLoanSets[user].length();
    }

    function getLoan(
        bytes32 loanId)
        external
        view
        returns (LoanReturnData memory loanData)
    {
        return _getLoan(
            loanId,
            LoanType.All,
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
        return _getActiveLoans(start, count, unsafeOnly, false);
    }

    function getActiveLoansAdvanced(
        uint256 start,
        uint256 count,
        bool unsafeOnly,
        bool isLiquidatable)
        external
        view
        returns (LoanReturnData[] memory loansData) 
    {
        return _getActiveLoans(start, count, unsafeOnly, isLiquidatable);
    }

    function _getActiveLoans(
        uint256 start,
        uint256 count,
        bool unsafeOnly,
        bool isLiquidatable)
        internal
        view 
        returns (LoanReturnData[] memory loansData)
    {
        uint256 end = start.add(count).min256(activeLoansSet.length());
        if (start >= end) {
            return loansData;
        }
        count = end-start;

        uint256 idx = count;
        LoanReturnData memory loanData;
        loansData = new LoanReturnData[](idx);
        for (uint256 i = --end; i >= start; i--) {
            loanData = _getLoan(
                activeLoansSet.get(i), // loanId
                LoanType.All,
                unsafeOnly
            );

            if (loanData.loanId == 0) {
                if (i == 0) {
                    break;
                } else {
                    continue;
                }
            }

            if (isLiquidatable && loanData.currentMargin == 0) {
                // we skip, not adding it to result set
                if (i == 0) {
                    break;
                } else {
                    continue;
                }
            }

            loansData[count-(idx--)] = loanData;

            if (i == 0) {
                break;
            }
        }

        if (idx != 0) {
            count -= idx;
            assembly {
                mstore(loansData, count)
            }
        }
    }

    function getActiveLoansCount()
        external
        view
        returns (uint256)
    {
        return activeLoansSet.length();
    }

    function _getLoan(
        bytes32 loanId,
        LoanType loanType,
        bool unsafeOnly)
        internal
        view
        returns (LoanReturnData memory loanData)
    {
        Loan memory loanLocal = loans[loanId];
        LoanParams memory loanParamsLocal = loanParams[loanLocal.loanParamsId];

        if ((loanType == LoanType.Margin && loanParamsLocal.maxLoanTerm == 0) ||
            (loanType == LoanType.NonMargin && loanParamsLocal.maxLoanTerm != 0)) {
            return loanData;
        }

        loanLocal.principal = _getLoanPrincipal(loanLocal.lender, loanLocal.id);
        (uint256 currentMargin, uint256 value) = IPriceFeeds(priceFeeds).getCurrentMargin( // currentMargin, collateralToLoanRate
            loanParamsLocal.loanToken,
            loanParamsLocal.collateralToken,
            loanLocal.principal,
            loanLocal.collateral
        );

        uint256 maxLiquidatable;
        uint256 maxSeizable;
        if (currentMargin <= loanParamsLocal.maintenanceMargin) {
            (maxLiquidatable, maxSeizable) = _getLiquidationAmounts(
                loanLocal.principal,
                loanLocal.collateral,
                currentMargin,
                loanParamsLocal.maintenanceMargin,
                value, // collateralToLoanRate
                liquidationIncentivePercent[loanParamsLocal.loanToken][loanParamsLocal.collateralToken]
            );
        } else if (unsafeOnly) {
            return loanData;
        }

        uint256 depositValueAsLoanToken;
        uint256 depositValueAsCollateralToken;
        bytes32 slot = keccak256(abi.encode(loanId, LoanDepositValueID));
        assembly {
            depositValueAsLoanToken := sload(slot)
            depositValueAsCollateralToken := sload(add(slot, 1))
        }

        return LoanReturnData({
            loanId: loanId,
            endTimestamp: 0, // depreciated: uint96(loanLocal.endTimestamp),
            loanToken: loanParamsLocal.loanToken,
            collateralToken: loanParamsLocal.collateralToken,
            principal: loanLocal.principal,
            collateral: loanLocal.collateral,
            interestOwedPerDay: 0, // depreciated
            interestDepositRemaining: 0, // depreciated
            startRate: loanLocal.startRate,
            startMargin: loanLocal.startMargin,
            maintenanceMargin: loanParamsLocal.maintenanceMargin,
            currentMargin: currentMargin,
            maxLoanTerm: loanParamsLocal.maxLoanTerm,
            maxLiquidatable: maxLiquidatable,
            maxSeizable: maxSeizable,
            depositValueAsLoanToken: depositValueAsLoanToken,
            depositValueAsCollateralToken: depositValueAsCollateralToken
        });
    }

    function _doSwapWithCollateral(
        Loan storage loanLocal,
        LoanParams memory loanParamsLocal,
        uint256 depositAmount)
        internal
        returns (uint256)
    {
        // reverts in _loanSwap if amountNeeded can't be bought
        (,uint256 sourceTokenAmountUsed,) = _loanSwap(
            loanLocal.id,
            loanParamsLocal.collateralToken,
            loanParamsLocal.loanToken,
            loanLocal.borrower,
            loanLocal.collateral, // minSourceTokenAmount
            0, // maxSourceTokenAmount (0 means minSourceTokenAmount)
            depositAmount, // requiredDestTokenAmount (partial spend of loanLocal.collateral to fill this amount)
            true, // bypassFee
            "" // loanDataBytes
        );
        loanLocal.collateral = loanLocal.collateral
            .sub(sourceTokenAmountUsed);

        // ensure the loan is still healthy
        (uint256 currentMargin, uint256 collateralToLoanRate) = IPriceFeeds(priceFeeds).getCurrentMargin(
            loanParamsLocal.loanToken,
            loanParamsLocal.collateralToken,
            loanLocal.principal,
            loanLocal.collateral
        );
        require(
            currentMargin > loanParamsLocal.maintenanceMargin,
            "unhealthy position"
        );

        // update deposit amount
        if (sourceTokenAmountUsed != 0 && collateralToLoanRate != 0) {
            _setDepositAmount(
                loanLocal.id,
                sourceTokenAmountUsed
                    .mul(collateralToLoanRate)
                    .div(WEI_PRECISION),
                sourceTokenAmountUsed,
                true // isSubtraction
            );
        }

        return sourceTokenAmountUsed;
    }

    function _setDepositAmount(
        bytes32 loanId,
        uint256 depositValueAsLoanToken,
        uint256 depositValueAsCollateralToken,
        bool isSubtraction)
        internal
    {
        bytes32 slot = keccak256(abi.encode(loanId, LoanDepositValueID));
        assembly {
            let val := sload(slot)
            switch isSubtraction
            case 0 {
                sstore(slot, add(val, depositValueAsLoanToken))
            }
            default {
                switch gt(val, depositValueAsLoanToken)
                case 1 {
                    sstore(slot, sub(val, depositValueAsLoanToken))
                }
                default {
                    sstore(slot, 0)
                }
            }

            slot := add(slot, 1)
            val := sload(slot)
            switch isSubtraction
            case 0 {
                sstore(slot, add(val, depositValueAsCollateralToken))
            }
            default {
                switch gt(val, depositValueAsCollateralToken)
                case 1 {
                    sstore(slot, sub(val, depositValueAsCollateralToken))
                }
                default {
                    sstore(slot, 0)
                }
            }
        }

        emit LoanDeposit(
            loanId,
            depositValueAsLoanToken,
            depositValueAsCollateralToken
        );
    }
}
