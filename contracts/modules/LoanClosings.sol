/**
 * Copyright 2017-2020, bZeroX, LLC. All Rights Reserved.
 * Licensed under the Apache License, Version 2.0.
 */

pragma solidity 0.5.17;
pragma experimental ABIEncoderV2;

import "../core/State.sol";
import "../events/LoanClosingsEvents.sol";
import "../mixins/VaultController.sol";
import "../mixins/InterestUser.sol";
import "../mixins/LiquidationHelper.sol";
import "../mixins/GasTokenUser.sol";
import "../swaps/SwapsUser.sol";


contract LoanClosings is State, LoanClosingsEvents, VaultController, InterestUser, GasTokenUser, SwapsUser, LiquidationHelper {

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
        logicTargets[this.liquidate.selector] = target;
        logicTargets[this.repayWithDeposit.selector] = target;
        logicTargets[this.repayWithCollateral.selector] = target;
        logicTargets[this.closeTrade.selector] = target;
    }

    function liquidate(
        bytes32 loanId,
        address receiver,
        uint256 closeAmount) // denominated in loanToken
        external
        payable
        //usesGasToken
        nonReentrant
        returns (
            uint256 loanCloseAmount,
            uint256 collateralWithdrawAmount,
            address collateralToken
        )
    {
        Loan storage loanLocal = loans[loanId];
        LoanParams storage loanParamsLocal = loanParams[loanLocal.loanParamsId];

        require(loanLocal.active, "loan is closed");
        require(loanParamsLocal.id != 0, "loanParams not exists");

        (uint256 currentMargin, uint256 collateralToLoanRate) = IPriceFeeds(priceFeeds).getCurrentMargin(
            loanParamsLocal.loanToken,
            loanParamsLocal.collateralToken,
            loanLocal.principal,
            loanLocal.collateral
        );
        require(
            currentMargin <= loanParamsLocal.maintenanceMargin,
            "healthy position"
        );

        loanCloseAmount = closeAmount;

        (uint256 maxLiquidatable, uint256 maxSeizable,) = _getLiquidationAmounts(
            loanLocal.principal,
            loanLocal.collateral,
            currentMargin,
            loanParamsLocal.maintenanceMargin,
            collateralToLoanRate
        );

        if (loanCloseAmount < maxLiquidatable) {
            collateralWithdrawAmount = SafeMath.div(
                SafeMath.mul(maxSeizable, loanCloseAmount),
                maxLiquidatable
            );
        } else if (loanCloseAmount > maxLiquidatable) {
            // adjust down the close amount to the max
            loanCloseAmount = maxLiquidatable;
            collateralWithdrawAmount = maxSeizable;
        }

        if (loanCloseAmount != 0) {
            _returnPrincipalWithDeposit(
                loanParamsLocal.loanToken,
                loanLocal.lender,
                loanCloseAmount
            );

        }

        collateralToken = loanParamsLocal.collateralToken;

        _finalizeLoanClose(
            loanLocal,
            loanParamsLocal,
            loanCloseAmount,
            collateralWithdrawAmount,
            receiver
        );

        _emitClosingEvents(
            loanParamsLocal,
            loanLocal,
            loanCloseAmount,
            collateralWithdrawAmount,
            collateralToLoanRate,
            currentMargin,
            3, // closeType
            0 // tradeCloseAmount
        );
    }

    function repayWithDeposit(
        bytes32 loanId,
        address receiver,
        uint256 closeAmount) // denominated in loanToken
        external
        payable
        //usesGasToken
        nonReentrant
        returns (
            uint256 loanCloseAmount,
            uint256 collateralWithdrawAmount,
            address collateralToken
        )
    {
        Loan storage loanLocal = loans[loanId];
        LoanParams storage loanParamsLocal = loanParams[loanLocal.loanParamsId];

        uint256 amountNeeded;
        (loanCloseAmount, amountNeeded) = _settleCloseAmounts(
            loanLocal,
            loanParamsLocal,
            closeAmount,
            receiver,
            false // amountIsCollateral
        );

        if (amountNeeded != 0) {
            _returnPrincipalWithDeposit(
                loanParamsLocal.loanToken,
                loanLocal.lender,
                amountNeeded
            );
        }

        collateralToken = loanParamsLocal.collateralToken;

        collateralWithdrawAmount = _finishRepay(
            loanLocal,
            loanParamsLocal,
            loanCloseAmount,
            0, // tradeCloseAmount
            receiver
        );
    }

    function repayWithCollateral(
        bytes32 loanId,
        address receiver,
        uint256 closeAmount, // denominated in loanToken
        bytes calldata loanDataBytes)
        external
        //usesGasToken
        nonReentrant
        returns (
            uint256 loanCloseAmount,
            uint256 collateralWithdrawAmount,
            address collateralToken
        )
    {
        return _repayWithCollateral(
            loanId,
            receiver,
            closeAmount,
            false, // amountIsCollateral
            loanDataBytes
        );
    }

    function closeTrade(
        bytes32 loanId,
        address receiver,
        uint256 positionCloseAmount, // denominated in collateralToken
        bytes calldata loanDataBytes)
        external
        //usesGasToken
        nonReentrant
        returns (
            uint256 loanCloseAmount,
            uint256 collateralWithdrawAmount,
            address collateralToken
        )
    {
        return _repayWithCollateral(
            loanId,
            receiver,
            positionCloseAmount,
            true, // amountIsCollateral
            loanDataBytes
        );
    }

    function _repayWithCollateral(
        bytes32 loanId,
        address receiver,
        uint256 closeAmount,
        bool amountIsCollateral,
        bytes memory loanDataBytes)
        internal
        returns (
            uint256 loanCloseAmount,
            uint256 collateralWithdrawAmount,
            address collateralToken
        )
    {
        Loan storage loanLocal = loans[loanId];
        LoanParams storage loanParamsLocal = loanParams[loanLocal.loanParamsId];

        uint256 amountNeeded;
        (loanCloseAmount, amountNeeded) = _settleCloseAmounts(
            loanLocal,
            loanParamsLocal,
            closeAmount,
            receiver,
            amountIsCollateral
        );

        if (amountNeeded != 0) {
            _returnPrincipalWithTrade(
                loanLocal,
                loanParamsLocal,
                loanLocal.lender,
                amountNeeded,
                loanDataBytes
            );
        }

        collateralToken = loanParamsLocal.collateralToken;

        collateralWithdrawAmount = _finishRepay(
            loanLocal,
            loanParamsLocal,
            loanCloseAmount,
            amountIsCollateral ? // tradeCloseAmount
                closeAmount :
                0,
            receiver
        );
    }

    function _settleCloseAmounts(
        Loan memory loanLocal,
        LoanParams memory loanParamsLocal,
        uint256 closeAmount,
        address receiver,
        bool amountIsCollateral)
        internal
        returns(uint256 loanCloseAmount, uint256 amountNeeded)
    {
        require(loanLocal.active, "loan is closed");
        require(
            msg.sender == loanLocal.borrower ||
            protocolManagers[msg.sender] ||
            delegatedManagers[loanLocal.id][msg.sender],
            "unauthorized"
        );
        require(loanParamsLocal.id != 0, "loanParams not exists");

        if (amountIsCollateral) {
            (uint256 currentMargin,) = IPriceFeeds(priceFeeds).getCurrentMargin(
                loanParamsLocal.loanToken,
                loanParamsLocal.collateralToken,
                loanLocal.principal,
                loanLocal.collateral
            );

            // convert from collateral to principal
            loanCloseAmount = closeAmount
                .mul(10**20)
                .div(currentMargin);
        } else {
            loanCloseAmount = closeAmount;
        }

        // can't close more than the full principal
        loanCloseAmount = loanLocal.principal < loanCloseAmount ?
            loanLocal.principal :
            loanCloseAmount;
        require(loanCloseAmount != 0, "loanCloseAmount == 0");

        uint256 interestRefund = _settleInterest(
            loanParamsLocal,
            loanLocal,
            loanCloseAmount
        );

        amountNeeded = loanCloseAmount;

        if (amountNeeded >= interestRefund) {
            amountNeeded -= interestRefund;
            interestRefund = 0;
        } else {
            interestRefund -= amountNeeded;
            amountNeeded = 0;
        }

        if (interestRefund != 0) {
            // refund overage
            if (loanParamsLocal.loanToken == address(wethToken)) {
                vaultEtherWithdraw(
                    receiver,
                    interestRefund
                );
            } else {
                vaultWithdraw(
                    loanParamsLocal.loanToken,
                    receiver,
                    interestRefund
                );
            }
        }

        return (loanCloseAmount, amountNeeded);
    }

    // repays principal to lender
    function _returnPrincipalWithDeposit(
        address loanToken,
        address lender,
        uint256 amount)
        internal
    {
        if (amount != 0) {
            if (msg.value == 0) {
                vaultTransfer(
                    loanToken,
                    msg.sender,
                    lender,
                    amount
                );
            } else {
                require(loanToken == address(wethToken), "wrong asset sent");
                require(msg.value >= amount, "not enough ether");
                wethToken.deposit.value(amount)();
                vaultTransfer(
                    loanToken,
                    address(this),
                    lender,
                    amount
                );
                if (msg.value > amount) {
                    // refund overage
                    Address.sendValue(
                        msg.sender,
                        msg.value - amount
                    );
                }
            }
        } else {
            require(msg.value == 0, "wrong asset sent");
        }
    }

    function _returnPrincipalWithTrade(
        Loan storage loanLocal,
        LoanParams storage loanParamsLocal,
        address lender,
        uint256 amountNeeded,
        bytes memory loanDataBytes)
        internal
    {
        // reverts in _swap if amountNeeded can't be bought
        (,uint256 sourceTokenAmountUsed) = _loanSwap(
            loanLocal.borrower,
            loanParamsLocal.collateralToken,
            loanParamsLocal.loanToken,
            loanLocal.collateral,
            amountNeeded, // requiredDestTokenAmount (partial spend of loanLocal.collateral to fill this amount)
            0, // minConversionRate
            false, // isLiquidation
            loanDataBytes
        );
        loanLocal.collateral = loanLocal.collateral
            .sub(sourceTokenAmountUsed);

        vaultWithdraw(
            loanParamsLocal.loanToken,
            lender,
            amountNeeded
        );
    }

    // withdraws collateral to receiver
    function _withdrawCollateral(
        address collateralToken,
        address receiver,
        uint256 amount)
        internal
    {
        if (amount != 0) {
            if (collateralToken == address(wethToken)) {
                vaultEtherWithdraw(
                    receiver,
                    amount
                );
            } else {
                vaultWithdraw(
                    collateralToken,
                    receiver,
                    amount
                );
            }
        }
    }

    function _finalizeLoanClose(
        Loan storage loanLocal,
        LoanParams storage loanParamsLocal,
        uint256 loanCloseAmount,
        uint256 collateralWithdrawAmount,
        address receiver)
        internal
        returns (uint256)
    {
        require(loanCloseAmount != 0, "nothing to close");

        if (loanCloseAmount == loanLocal.principal) {
            loanLocal.principal = 0;
            loanLocal.active = false;
            loanLocal.loanEndTimestamp = block.timestamp;
            loanLocal.pendingTradesId = 0;
            activeLoansSet.remove(loanLocal.id);
            lenderLoanSets[loanLocal.lender].remove(loanLocal.id);
            borrowerLoanSets[loanLocal.borrower].remove(loanLocal.id);
        } else {
            loanLocal.principal = loanLocal.principal
                .sub(loanCloseAmount);
        }

        loanLocal.collateral = loanLocal.collateral
            .sub(collateralWithdrawAmount);

        _withdrawCollateral(
            loanParamsLocal.collateralToken,
            receiver,
            collateralWithdrawAmount
        );
    }

    function _finishRepay(
        Loan storage loanLocal,
        LoanParams storage loanParamsLocal,
        uint256 loanCloseAmount,
        uint256 tradeCloseAmount,
        address receiver)
        internal
        returns (uint256 collateralWithdrawAmount)
    {
        if (loanCloseAmount == loanLocal.principal) {
            collateralWithdrawAmount = loanLocal.collateral;
        } else {
            collateralWithdrawAmount = SafeMath.div(
                SafeMath.mul(loanLocal.collateral, loanCloseAmount),
                loanLocal.principal
            );
        }

        _finalizeLoanClose(
            loanLocal,
            loanParamsLocal,
            loanCloseAmount,
            collateralWithdrawAmount,
            receiver
        );

        (uint256 currentMargin, uint256 collateralToLoanRate) = IPriceFeeds(priceFeeds).getCurrentMargin(
            loanParamsLocal.loanToken,
            loanParamsLocal.collateralToken,
            loanLocal.principal,
            loanLocal.collateral
        );
        require(
            loanLocal.principal == 0 ||
            currentMargin > loanParamsLocal.maintenanceMargin,
            "unhealthy position"
        );

        _emitClosingEvents(
            loanParamsLocal,
            loanLocal,
            loanCloseAmount,
            collateralWithdrawAmount,
            collateralToLoanRate,
            currentMargin,
            tradeCloseAmount == 0 ? // closeType
                0 :
                1,
            tradeCloseAmount
        );
    }

    function _settleInterest(
        LoanParams memory loanParamsLocal,
        Loan memory loanLocal,
        uint256 closePrincipal)
        internal
        returns (uint256)
    {
        uint256 interestRefund;

        LoanInterest storage loanInterestLocal = loanInterest[loanLocal.id];
        LenderInterest storage lenderInterestLocal = lenderInterest[loanLocal.lender][loanParamsLocal.loanToken];

        // pay outstanding interest to lender
        _payInterest(
            lenderInterestLocal,
            loanLocal.lender,
            loanParamsLocal.loanToken
        );

        uint256 owedPerDayRefund;
        if (closePrincipal < loanLocal.principal) {
            owedPerDayRefund = SafeMath.div(
                SafeMath.mul(closePrincipal, loanInterestLocal.owedPerDay),
                loanLocal.principal
            );
        } else {
            owedPerDayRefund = loanInterestLocal.owedPerDay;
        }

        // update stored owedPerDay
        loanInterestLocal.owedPerDay = loanInterestLocal.owedPerDay
            .sub(owedPerDayRefund);
        lenderInterestLocal.owedPerDay = lenderInterestLocal.owedPerDay
            .sub(owedPerDayRefund);

        // update borrower interest
        uint256 interestTime = block.timestamp;
        if (interestTime > loanLocal.loanEndTimestamp) {
            interestTime = loanLocal.loanEndTimestamp;
        }

        interestRefund = loanLocal.loanEndTimestamp
            .sub(interestTime);
        interestRefund = interestRefund
            .mul(owedPerDayRefund);
        interestRefund = interestRefund
            .div(86400);

        if (closePrincipal < loanLocal.principal) {
            loanInterestLocal.depositTotal = loanInterestLocal.depositTotal
                .sub(interestRefund);
        } else {
            loanInterestLocal.depositTotal = 0;
        }
        loanInterestLocal.updatedTimestamp = interestTime;

        // update remaining lender interest values
        lenderInterestLocal.principalTotal = lenderInterestLocal.principalTotal
            .sub(closePrincipal);
        lenderInterestLocal.owedTotal = lenderInterestLocal.owedTotal
            .sub(interestRefund);

        return interestRefund;
    }

    function _emitClosingEvents(
        LoanParams memory loanParamsLocal,
        Loan memory loanLocal,
        uint256 loanCloseAmount,
        uint256 collateralWithdrawAmount,
        uint256 collateralToLoanRate,
        uint256 currentMargin,
        uint256 tradeCloseAmount,
        uint256 closeType)
        internal
    {
        if (closeType == 0) {
            emit Repay(
                loanLocal.id,
                loanLocal.borrower,
                loanLocal.lender,
                loanParamsLocal.loanToken,
                loanParamsLocal.collateralToken,
                loanCloseAmount,
                collateralWithdrawAmount,
                collateralToLoanRate,
                currentMargin
            );
        } else if (closeType == 1) {
            // exitPrice = 1 / collateralToLoanRate
            collateralToLoanRate = SafeMath.div(10**36, collateralToLoanRate);

            // currentLeverage = 100 / currentMargin
            currentMargin = SafeMath.div(10**38, currentMargin);

            emit CloseTrade(
                loanLocal.borrower,                             // trader
                loanParamsLocal.collateralToken,                // baseToken
                loanParamsLocal.loanToken,                      // quoteToken
                loanLocal.lender,                               // lender
                loanLocal.id,                                   // loanId
                tradeCloseAmount,                               // positionCloseSize
                loanCloseAmount,                                // loanCloseAmount
                collateralToLoanRate,                           // exitPrice
                currentMargin                                   // currentLeverage
            );
        } else { // closeType == 3
            emit Liquidate(
                loanLocal.id,
                loanLocal.borrower,
                loanLocal.lender,
                loanParamsLocal.loanToken,
                loanParamsLocal.collateralToken,
                loanCloseAmount,
                collateralWithdrawAmount,
                collateralToLoanRate,
                currentMargin
            );
        }
    }
}
