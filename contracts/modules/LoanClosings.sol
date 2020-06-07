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

    enum CloseTypes {
        Deposit,
        Swap,
        Liquidation
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
        _setTarget(this.liquidate.selector, target);
        _setTarget(this.closeWithDeposit.selector, target);
        _setTarget(this.closeWithSwap.selector, target);
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
            uint256 seizedAmount,
            address seizedToken
        )
    {
        require(closeAmount != 0, "closeAmount == 0");

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
            seizedAmount = SafeMath.div(
                SafeMath.mul(maxSeizable, loanCloseAmount),
                maxLiquidatable
            );
        } else if (loanCloseAmount > maxLiquidatable) {
            // adjust down the close amount to the max
            loanCloseAmount = maxLiquidatable;
            seizedAmount = maxSeizable;
            require(loanCloseAmount != 0, "nothing to liquidate");
        }

        uint256 loanCloseAmountLessInterest = _settleInterestToPrincipal(
            loanLocal,
            loanParamsLocal,
            loanCloseAmount,
            loanLocal.borrower
        );
        if (loanCloseAmount > loanCloseAmountLessInterest) {
            // full interest refund goes to borrower
            _withdrawAsset(
                loanParamsLocal.loanToken,
                loanLocal.borrower,
                loanCloseAmount - loanCloseAmountLessInterest
            );
        }

        if (loanCloseAmount != 0) {
            _returnPrincipalWithDeposit(
                loanParamsLocal.loanToken,
                loanLocal.lender,
                loanCloseAmount
            );

        }

        seizedToken = loanParamsLocal.collateralToken;

        if (seizedAmount != 0) {
            loanLocal.collateral = loanLocal.collateral
                .sub(seizedAmount);

            _withdrawAsset(
                seizedToken,
                receiver,
                seizedAmount
            );
        }

        _closeLoan(
            loanLocal,
            loanCloseAmount
        );

        _emitClosingEvents(
            loanParamsLocal,
            loanLocal,
            loanCloseAmount,
            seizedAmount,
            collateralToLoanRate,
            currentMargin,
            CloseTypes.Liquidation
        );
    }

    function closeWithDeposit(
        bytes32 loanId,
        address receiver,
        uint256 depositAmount) // denominated in loanToken
        external
        payable
        //usesGasToken
        nonReentrant
        returns (
            uint256 loanCloseAmount,
            uint256 withdrawAmount,
            address withdrawToken
        )
    {
        require(depositAmount != 0, "depositAmount == 0");

        Loan storage loanLocal = loans[loanId];
        LoanParams storage loanParamsLocal = loanParams[loanLocal.loanParamsId];
        _checkAuthorized(
            loanLocal,
            loanParamsLocal
        );

        // can't close more than the full principal
        loanCloseAmount = depositAmount > loanLocal.principal ?
            loanLocal.principal :
            depositAmount;

        uint256 loanCloseAmountLessInterest = _settleInterestToPrincipal(
            loanLocal,
            loanParamsLocal,
            loanCloseAmount,
            receiver
        );

        if (loanCloseAmountLessInterest != 0) {
            _returnPrincipalWithDeposit(
                loanParamsLocal.loanToken,
                loanLocal.lender,
                loanCloseAmountLessInterest
            );
        }

        if (loanCloseAmount == loanLocal.principal) {
            withdrawAmount = loanLocal.collateral;
        } else {
            withdrawAmount = loanLocal.collateral
                .mul(loanCloseAmount)
                .div(loanLocal.principal);
        }

        withdrawToken = loanParamsLocal.collateralToken;

        if (withdrawAmount != 0) {
            loanLocal.collateral = loanLocal.collateral
                .sub(withdrawAmount);

            _withdrawAsset(
                withdrawToken,
                receiver,
                withdrawAmount
            );
        }

        _closeLoan(
            loanLocal,
            loanCloseAmount
        );

        _finalizeClose(
            loanLocal,
            loanParamsLocal,
            loanCloseAmount,
            withdrawAmount, // collateralCloseAmount,
            CloseTypes.Deposit
        );
    }

    function closeWithSwap(
        bytes32 loanId,
        address receiver,
        uint256 swapAmount, // denominated in collateralToken
        bool returnTokenIsCollateral, // true: withdraws collateralToken, false: withdraws loanToken
        bytes memory loanDataBytes)
        public
        //usesGasToken
        nonReentrant
        returns (
            uint256 loanCloseAmount,
            uint256 withdrawAmount,
            address withdrawToken
        )
    {
        require(swapAmount != 0, "swapAmount == 0");

        Loan storage loanLocal = loans[loanId];
        LoanParams storage loanParamsLocal = loanParams[loanLocal.loanParamsId];
        _checkAuthorized(
            loanLocal,
            loanParamsLocal
        );

        swapAmount = swapAmount > loanLocal.collateral ?
            loanLocal.collateral :
            swapAmount;

        /*if (swapAmount < loanLocal.collateral) {
            // determine about of loan to payback by converting from collateral to principal
            (uint256 currentMargin, uint256 collateralToLoanRate) = IPriceFeeds(priceFeeds).getCurrentMargin(
                loanParamsLocal.loanToken,
                loanParamsLocal.collateralToken,
                loanLocal.principal,
                loanLocal.collateral
            );
            require(currentMargin != 0, "collateral insufficient");

            // convert from collateral to principal
            loanCloseAmount = swapAmount
                .mul(collateralToLoanRate)
                .mul(100)
                .div(currentMargin);

            // can't close more than the full principal
            loanCloseAmount = loanCloseAmount > loanLocal.principal ?
                loanLocal.principal :
                loanCloseAmount;
        } else {
            loanCloseAmount = loanLocal.principal;
        }
        require(loanCloseAmount != 0, "loanCloseAmount == 0");*/

        uint256 loanCloseAmountLessInterest;
        if (swapAmount == loanLocal.collateral || returnTokenIsCollateral) {
            loanCloseAmount = swapAmount == loanLocal.collateral ?
                loanLocal.principal :
                loanLocal.principal
                    .mul(swapAmount)
                    .div(loanLocal.collateral);
            require(loanCloseAmount != 0, "loanCloseAmount == 0");

            loanCloseAmountLessInterest = _settleInterestToPrincipal(
                loanLocal,
                loanParamsLocal,
                loanCloseAmount,
                receiver
            );
        } else {
            // loanCloseAmount is calculated after swap
            loanCloseAmountLessInterest = 0;
        }

        uint256 returnedToLenderAmount;
        (returnedToLenderAmount, withdrawAmount) = _returnPrincipalWithSwap(
            loanLocal,
            loanParamsLocal,
            swapAmount,
            loanCloseAmountLessInterest,
            returnTokenIsCollateral,
            loanDataBytes
        );

        if (loanCloseAmountLessInterest == 0) {
            // condition: swapAmount != loanLocal.collateral && !returnTokenIsCollateral

            loanCloseAmount = returnedToLenderAmount;

            loanCloseAmountLessInterest = _settleInterestToPrincipal(
                loanLocal,
                loanParamsLocal,
                returnedToLenderAmount,
                receiver
            );

            // the interest that would apply to the principal needs to go to the borrower
            withdrawAmount = withdrawAmount
                .add(loanCloseAmount)
                .sub(loanCloseAmountLessInterest);
        }

        withdrawToken = returnTokenIsCollateral ?
            loanParamsLocal.collateralToken :
            loanParamsLocal.loanToken;

        if (withdrawAmount != 0) {
            _withdrawAsset(
                withdrawToken,
                receiver,
                withdrawAmount
            );
        }

        _closeLoan(
            loanLocal,
            loanCloseAmount
        );

        _finalizeClose(
            loanLocal,
            loanParamsLocal,
            loanCloseAmount,
            swapAmount, // collateralCloseAmount,
            CloseTypes.Swap
        );
    }

    function _checkAuthorized(
        Loan memory loanLocal,
        LoanParams memory loanParamsLocal)
        internal
        view
    {
        require(loanLocal.active, "loan is closed");
        require(
            msg.sender == loanLocal.borrower ||
            delegatedManagers[loanLocal.id][msg.sender],
            "unauthorized"
        );
        require(loanParamsLocal.id != 0, "loanParams not exists");
    }

    function _settleInterestToPrincipal(
        Loan memory loanLocal,
        LoanParams memory loanParamsLocal,
        uint256 loanCloseAmount,
        address receiver)
        internal
        returns (uint256)
    {
        uint256 loanCloseAmountLessInterest = loanCloseAmount;

        uint256 interestRefundToBorrower = _settleInterest(
            loanParamsLocal,
            loanLocal,
            loanCloseAmountLessInterest
        );

        uint256 interestAppliedToPrincipal;
        if (loanCloseAmountLessInterest >= interestRefundToBorrower) {
            // apply all of borrower interest refund torwards principal
            interestAppliedToPrincipal = interestRefundToBorrower;

            // principal needed is reduced by this amount
            loanCloseAmountLessInterest -= interestRefundToBorrower;

            // no interest refund remaining
            interestRefundToBorrower = 0;
        } else {
            // principal fully covered by excess interest
            interestAppliedToPrincipal = loanCloseAmountLessInterest;

            // amount refunded is reduced by this amount
            interestRefundToBorrower -= loanCloseAmountLessInterest;

            // principal fully covered by excess interest
            loanCloseAmountLessInterest = 0;

            if (interestRefundToBorrower != 0) {
                // refund overage
                _withdrawAsset(
                    loanParamsLocal.loanToken,
                    receiver,
                    interestRefundToBorrower
                );
            }
        }

        if (interestAppliedToPrincipal != 0) {
            vaultWithdraw(
                loanParamsLocal.loanToken,
                loanLocal.lender,
                interestAppliedToPrincipal
            );
        }

        return loanCloseAmountLessInterest;
    }

    // repays principal to lender
    function _returnPrincipalWithDeposit(
        address loanToken,
        address lender,
        uint256 principalNeeded)
        internal
    {
        if (principalNeeded != 0) {
            if (msg.value == 0) {
                vaultTransfer(
                    loanToken,
                    msg.sender,
                    lender,
                    principalNeeded
                );
            } else {
                require(loanToken == address(wethToken), "wrong asset sent");
                require(msg.value >= principalNeeded, "not enough ether");
                wethToken.deposit.value(principalNeeded)();
                vaultTransfer(
                    loanToken,
                    address(this),
                    lender,
                    principalNeeded
                );
                if (msg.value > principalNeeded) {
                    // refund overage
                    Address.sendValue(
                        msg.sender,
                        msg.value - principalNeeded
                    );
                }
            }
        } else {
            require(msg.value == 0, "wrong asset sent");
        }
    }

    function _returnPrincipalWithSwap(
        Loan storage loanLocal,
        LoanParams storage loanParamsLocal,
        uint256 swapAmount,
        uint256 principalNeeded,
        bool returnTokenIsCollateral,
        bytes memory loanDataBytes)
        internal
        returns (uint256 returnedToLenderAmount, uint256 withdrawAmount)
    {
        uint256 tmpSwapAmount;
        uint256 tmpPrincipalNeeded;
        if (returnTokenIsCollateral) {
            tmpSwapAmount = loanLocal.collateral;
            tmpPrincipalNeeded = principalNeeded;
        } else {
            tmpSwapAmount = swapAmount;
            tmpPrincipalNeeded = 0;
        }

        (uint256 destTokenAmountReceived, uint256 sourceTokenAmountUsed) = _loanSwap(
            loanLocal.id,
            loanParamsLocal.collateralToken,
            loanParamsLocal.loanToken,
            loanLocal.borrower,
            tmpSwapAmount,
            tmpPrincipalNeeded,
            0, // minConversionRate
            false, // bypassFee
            loanDataBytes
        );
        require(destTokenAmountReceived >= principalNeeded, "insufficient dest amount");
        require(sourceTokenAmountUsed <= tmpSwapAmount, "excessive source amount");

        if (returnTokenIsCollateral) {
            returnedToLenderAmount = principalNeeded;

            if (destTokenAmountReceived > returnedToLenderAmount) {

                // better fill than expected, so send excess to borrower
                vaultWithdraw(
                    loanParamsLocal.loanToken,
                    loanLocal.borrower,
                    destTokenAmountReceived - returnedToLenderAmount
                );
            }
            withdrawAmount = swapAmount > sourceTokenAmountUsed ?
                swapAmount - sourceTokenAmountUsed :
                0;
        } else {
            require(sourceTokenAmountUsed == swapAmount, "swap error");

            if (swapAmount == loanLocal.collateral) {
                // sourceTokenAmountUsed == swapAmount == loanLocal.collateral

                returnedToLenderAmount = principalNeeded;
                withdrawAmount = destTokenAmountReceived - principalNeeded;
            
            } else {
                // sourceTokenAmountUsed == swapAmount < loanLocal.collateral

                if (destTokenAmountReceived >= loanLocal.principal) {
                    // edge case where swap covers full principal

                    returnedToLenderAmount = loanLocal.principal;
                    withdrawAmount = destTokenAmountReceived - loanLocal.principal;

                    // excess collateral refunds to the borrower
                    vaultWithdraw(
                        loanParamsLocal.collateralToken,
                        loanLocal.borrower,
                        loanLocal.collateral - sourceTokenAmountUsed
                    );
                    sourceTokenAmountUsed = loanLocal.collateral;
                } else {
                    returnedToLenderAmount = destTokenAmountReceived;
                    withdrawAmount = 0;
                }
            }
        }

        loanLocal.collateral = loanLocal.collateral
            .sub(
                sourceTokenAmountUsed > swapAmount ?
                    sourceTokenAmountUsed :
                    swapAmount
            );

        // repays principal to lender
        vaultWithdraw(
            loanParamsLocal.loanToken,
            loanLocal.lender,
            returnedToLenderAmount
        );
    }

    // withdraws asset to receiver
    function _withdrawAsset(
        address assetToken,
        address receiver,
        uint256 assetAmount)
        internal
    {
        if (assetAmount != 0) {
            if (assetToken == address(wethToken)) {
                vaultEtherWithdraw(
                    receiver,
                    assetAmount
                );
            } else {
                vaultWithdraw(
                    assetToken,
                    receiver,
                    assetAmount
                );
            }
        }
    }

    function _finalizeClose(
        Loan storage loanLocal,
        LoanParams storage loanParamsLocal,
        uint256 loanCloseAmount,
        uint256 collateralCloseAmount,
        CloseTypes closeType)
        internal
    {
        // this is still called even with full loan close to return collateralToLoanRate
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
            collateralCloseAmount,
            collateralToLoanRate,
            currentMargin,
            closeType
        );
    }

    function _closeLoan(
        Loan storage loanLocal,
        uint256 loanCloseAmount)
        internal
        returns (uint256)
    {
        require(loanCloseAmount != 0, "nothing to close");

        if (loanCloseAmount == loanLocal.principal) {
            loanLocal.principal = 0;
            loanLocal.active = false;
            loanLocal.endTimestamp = block.timestamp;
            loanLocal.pendingTradesId = 0;
            activeLoansSet.remove(loanLocal.id);
            lenderLoanSets[loanLocal.lender].remove(loanLocal.id);
            borrowerLoanSets[loanLocal.borrower].remove(loanLocal.id);
        } else {
            loanLocal.principal = loanLocal.principal
                .sub(loanCloseAmount);
        }
    }

    function _settleInterest(
        LoanParams memory loanParamsLocal,
        Loan memory loanLocal,
        uint256 closePrincipal)
        internal
        returns (uint256)
    {
        // pay outstanding interest to lender
        _payInterest(
            loanLocal.lender,
            loanParamsLocal.loanToken
        );

        LoanInterest storage loanInterestLocal = loanInterest[loanLocal.id];
        LenderInterest storage lenderInterestLocal = lenderInterest[loanLocal.lender][loanParamsLocal.loanToken];

        uint256 owedPerDayRefund;
        if (closePrincipal < loanLocal.principal) {
            owedPerDayRefund = loanInterestLocal.owedPerDay
                .mul(closePrincipal)
                .div(loanLocal.principal);
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
        if (interestTime > loanLocal.endTimestamp) {
            interestTime = loanLocal.endTimestamp;
        }

        uint256 interestRefundToBorrower = loanLocal.endTimestamp
            .sub(interestTime);
        interestRefundToBorrower = interestRefundToBorrower
            .mul(owedPerDayRefund);
        interestRefundToBorrower = interestRefundToBorrower
            .div(86400);

        if (closePrincipal < loanLocal.principal) {
            loanInterestLocal.depositTotal = loanInterestLocal.depositTotal
                .sub(interestRefundToBorrower);
        } else {
            loanInterestLocal.depositTotal = 0;
        }
        loanInterestLocal.updatedTimestamp = interestTime;

        // update remaining lender interest values
        lenderInterestLocal.principalTotal = lenderInterestLocal.principalTotal
            .sub(closePrincipal);
        lenderInterestLocal.owedTotal = lenderInterestLocal.owedTotal
            .sub(interestRefundToBorrower);

        return interestRefundToBorrower;
    }

    function _emitClosingEvents(
        LoanParams memory loanParamsLocal,
        Loan memory loanLocal,
        uint256 loanCloseAmount,
        uint256 collateralCloseAmount,
        uint256 collateralToLoanRate,
        uint256 currentMargin,
        CloseTypes closeType)
        internal
    {
        if (closeType == CloseTypes.Deposit) {
            emit CloseWithDeposit(
                loanLocal.id,
                loanLocal.borrower,
                loanLocal.lender,
                loanParamsLocal.loanToken,
                loanParamsLocal.collateralToken,
                loanCloseAmount,
                collateralCloseAmount,
                collateralToLoanRate,
                currentMargin
            );
        } else if (closeType == CloseTypes.Swap) {
            // exitPrice = 1 / collateralToLoanRate
            if (collateralToLoanRate != 0) {
                collateralToLoanRate = SafeMath.div(10**36, collateralToLoanRate);
            }

            // currentLeverage = 100 / currentMargin
            if (currentMargin != 0) {
                currentMargin = SafeMath.div(10**38, currentMargin);
            }

            emit CloseWithSwap(
                loanLocal.borrower,                             // trader
                loanParamsLocal.collateralToken,                // baseToken
                loanParamsLocal.loanToken,                      // quoteToken
                loanLocal.lender,                               // lender
                loanLocal.id,                                   // loanId
                collateralCloseAmount,                          // positionCloseSize
                loanCloseAmount,                                // loanCloseAmount
                collateralToLoanRate,                           // exitPrice
                currentMargin                                   // currentLeverage
            );
        } else { // closeType == CloseTypes.Liquidation
            emit Liquidate(
                loanLocal.id,
                loanLocal.borrower,
                loanLocal.lender,
                loanParamsLocal.loanToken,
                loanParamsLocal.collateralToken,
                loanCloseAmount,
                collateralCloseAmount,
                collateralToLoanRate,
                currentMargin
            );
        }
    }
}
