/**
 * Copyright 2017-2020, bZeroX, LLC. All Rights Reserved.
 * Licensed under the Apache License, Version 2.0.
 */

pragma solidity 0.5.17;
pragma experimental ABIEncoderV2;

import "../../core/State.sol";
import "../../events/LoanClosingsEvents.sol";
import "../../mixins/VaultController.sol";
import "../../mixins/InterestUser.sol";
import "../../mixins/LiquidationHelper.sol";
import "../../swaps/SwapsUser.sol";
import "../../interfaces/ILoanPool.sol";
import "../../connectors/gastoken/GasTokenUser.sol";


contract LoanClosingsBase is State, LoanClosingsEvents, VaultController, InterestUser, GasTokenUser, SwapsUser, LiquidationHelper {

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
        external;

    function _liquidate(
        bytes32 loanId,
        address receiver,
        uint256 closeAmount)
        internal
        returns (
            uint256 loanCloseAmount,
            uint256 seizedAmount,
            address seizedToken
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
            seizedAmount = maxSeizable
                .mul(loanCloseAmount)
                .div(maxLiquidatable);
        } else if (loanCloseAmount > maxLiquidatable) {
            // adjust down the close amount to the max
            loanCloseAmount = maxLiquidatable;
            seizedAmount = maxSeizable;
        } else {
            seizedAmount = maxSeizable;
        }

        require(loanCloseAmount != 0, "nothing to liquidate");

        // liquidator deposits the principal being closed
        _returnPrincipalWithDeposit(
            loanParamsLocal.loanToken,
            address(this),
            loanCloseAmount
        );

        // a portion of the principal is repaid to the lender out of interest refunded
        uint256 loanCloseAmountLessInterest = _settleInterestToPrincipal(
            loanLocal,
            loanParamsLocal,
            loanCloseAmount,
            loanLocal.borrower
        );

        if (loanCloseAmount > loanCloseAmountLessInterest) {
            // full interest refund goes to the borrower
            _withdrawAsset(
                loanParamsLocal.loanToken,
                loanLocal.borrower,
                loanCloseAmount - loanCloseAmountLessInterest
            );
        }

        if (loanCloseAmountLessInterest != 0) {
            // The lender always gets back an ERC20 (even WETH), so we call withdraw directly rather than
            // use the _withdrawAsset helper function
            vaultWithdraw(
                loanParamsLocal.loanToken,
                loanLocal.lender,
                loanCloseAmountLessInterest
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
            0, // collateralToLoanSwapRate
            currentMargin,
            CloseTypes.Liquidation
        );
    }

    function _rollover(
        bytes32 loanId,
        uint256 startingGas,
        bytes memory loanDataBytes)
        internal
    {
        Loan storage loanLocal = loans[loanId];
        LoanParams storage loanParamsLocal = loanParams[loanLocal.loanParamsId];

        require(loanLocal.active, "loan is closed");
        require(loanParamsLocal.id != 0, "loanParams not exists");
        require(
            block.timestamp > loanLocal.endTimestamp.sub(3600),
            "healthy position"
        );
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
                .div(86400);
        }

        uint256 maxDuration = loanParamsLocal.maxLoanTerm;

        if (maxDuration != 0) {
            // fixed-term loan, so need to query iToken for latest variable rate
            uint256 owedPerDay = loanLocal.principal
                .mul(ILoanPool(loanLocal.lender).borrowInterestRate())
                .div(365 * 10**20);

            lenderInterestLocal.owedPerDay = lenderInterestLocal.owedPerDay
                .add(owedPerDay);
            lenderInterestLocal.owedPerDay = lenderInterestLocal.owedPerDay
                .sub(loanInterestLocal.owedPerDay);

            loanInterestLocal.owedPerDay = owedPerDay;
        } else {
            // loanInterestLocal.owedPerDay doesn't change
            maxDuration = 2628000; // approx. 1 month
        }

        if (backInterestTime >= maxDuration) {
            maxDuration = backInterestTime
                .add(86400); // adds an extra 24 hours
        }

        // update loan end time
        loanLocal.endTimestamp = loanLocal.endTimestamp
            .add(maxDuration);

        uint256 interestAmountRequired = loanLocal.endTimestamp
            .sub(block.timestamp);
        interestAmountRequired = interestAmountRequired
            .mul(loanInterestLocal.owedPerDay);
        interestAmountRequired = interestAmountRequired
            .div(86400);

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
            loanDataBytes
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

        uint256 gasRebate = _gasUsed(startingGas)
            .mul(
                IPriceFeeds(priceFeeds).getFastGasPrice(loanParamsLocal.collateralToken) * 2
            );

        if (gasRebate != 0) {
            // pay out gas rebate to caller
            loanLocal.collateral = loanLocal.collateral
                .sub(gasRebate);

            _withdrawAsset(
                loanParamsLocal.collateralToken,
                msg.sender,
                gasRebate
            );
        }

        (uint256 currentMargin,) = IPriceFeeds(priceFeeds).getCurrentMargin(
            loanParamsLocal.loanToken,
            loanParamsLocal.collateralToken,
            loanLocal.principal,
            loanLocal.collateral
        );
        require(
            currentMargin > 3 ether, // ensure there's more than 3% margin remaining
            "unhealthy position"
        );
    }

    function _closeWithDeposit(
        bytes32 loanId,
        address receiver,
        uint256 depositAmount) // denominated in loanToken
        internal
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

        _finalizeClose(
            loanLocal,
            loanParamsLocal,
            loanCloseAmount,
            withdrawAmount, // collateralCloseAmount
            0, // collateralToLoanSwapRate
            CloseTypes.Deposit
        );
    }

    function _closeWithSwap(
        bytes32 loanId,
        address receiver,
        uint256 swapAmount,
        bool returnTokenIsCollateral,
        bytes memory loanDataBytes)
        internal
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
            // loanCloseAmount is calculated after swap; for this case we want to swap the entire source amount
            // and determine the loanCloseAmount and withdraw amount based on that
            loanCloseAmountLessInterest = 0;
        }

        uint256 coveredPrincipal;
        uint256 usedCollateral;
        // swapAmount repurposed for collateralToLoanSwapRate to avoid stack too deep error
        (coveredPrincipal, usedCollateral, withdrawAmount, swapAmount) = _coverPrincipalWithSwap(
            loanLocal,
            loanParamsLocal,
            swapAmount,
            loanCloseAmountLessInterest,
            returnTokenIsCollateral,
            loanDataBytes
        );

        if (loanCloseAmountLessInterest == 0) {
            // condition prior to swap: swapAmount != loanLocal.collateral && !returnTokenIsCollateral

            // amounts that is closed
            loanCloseAmount = coveredPrincipal;
            if (coveredPrincipal != loanLocal.principal) {
                loanCloseAmount = loanCloseAmount
                    .mul(usedCollateral)
                    .div(loanLocal.collateral);
            }
            require(loanCloseAmount != 0, "loanCloseAmount == 0");

            // amount that is returned to the lender
            loanCloseAmountLessInterest = _settleInterestToPrincipal(
                loanLocal,
                loanParamsLocal,
                loanCloseAmount,
                receiver
            );

            // remaining amount withdrawn to the receiver
            withdrawAmount = withdrawAmount
                .add(coveredPrincipal)
                .sub(loanCloseAmountLessInterest);
        } else {
            loanCloseAmountLessInterest = coveredPrincipal;
        }

        require(loanCloseAmountLessInterest != 0, "closeAmount is 0 after swap");

        if (usedCollateral != 0) {
            loanLocal.collateral = loanLocal.collateral
                .sub(usedCollateral);
        }

        // Repays principal to lender
        // The lender always gets back an ERC20 (even WETH), so we call withdraw directly rather than
        // use the _withdrawAsset helper function
        vaultWithdraw(
            loanParamsLocal.loanToken,
            loanLocal.lender,
            loanCloseAmountLessInterest
        );

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

        _finalizeClose(
            loanLocal,
            loanParamsLocal,
            loanCloseAmount,
            usedCollateral,
            swapAmount, // collateralToLoanSwapRate
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
            // The lender always gets back an ERC20 (even WETH), so we call withdraw directly rather than
            // use the _withdrawAsset helper function
            vaultWithdraw(
                loanParamsLocal.loanToken,
                loanLocal.lender,
                interestAppliedToPrincipal
            );
        }

        return loanCloseAmountLessInterest;
    }

    // The receiver always gets back an ERC20 (even WETH)
    function _returnPrincipalWithDeposit(
        address loanToken,
        address receiver,
        uint256 principalNeeded)
        internal
    {
        if (principalNeeded != 0) {
            if (msg.value == 0) {
                vaultTransfer(
                    loanToken,
                    msg.sender,
                    receiver,
                    principalNeeded
                );
            } else {
                require(loanToken == address(wethToken), "wrong asset sent");
                require(msg.value >= principalNeeded, "not enough ether");
                wethToken.deposit.value(principalNeeded)();
                if (receiver != address(this)) {
                    vaultTransfer(
                        loanToken,
                        address(this),
                        receiver,
                        principalNeeded
                    );
                }
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

    function _coverPrincipalWithSwap(
        Loan memory loanLocal,
        LoanParams memory loanParamsLocal,
        uint256 swapAmount,
        uint256 principalNeeded,
        bool returnTokenIsCollateral,
        bytes memory loanDataBytes)
        internal
        returns (uint256 coveredPrincipal, uint256 usedCollateral, uint256 withdrawAmount, uint256 collateralToLoanSwapRate)
    {
        uint256 destTokenAmountReceived;
        uint256 sourceTokenAmountUsed;
        (destTokenAmountReceived, sourceTokenAmountUsed, collateralToLoanSwapRate) = _doCollateralSwap(
            loanLocal,
            loanParamsLocal,
            swapAmount,
            principalNeeded,
            returnTokenIsCollateral,
            loanDataBytes
        );

        if (returnTokenIsCollateral) {
            coveredPrincipal = principalNeeded;

            if (destTokenAmountReceived > coveredPrincipal) {
                // better fill than expected, so send excess to borrower
                _withdrawAsset(
                    loanParamsLocal.loanToken,
                    loanLocal.borrower,
                    destTokenAmountReceived - coveredPrincipal
                );
            }
            withdrawAmount = swapAmount > sourceTokenAmountUsed ?
                swapAmount - sourceTokenAmountUsed :
                0;
        } else {
            require(sourceTokenAmountUsed == swapAmount, "swap error");

            if (swapAmount == loanLocal.collateral) {
                // sourceTokenAmountUsed == swapAmount == loanLocal.collateral

                coveredPrincipal = principalNeeded;
                withdrawAmount = destTokenAmountReceived - principalNeeded;

            } else {
                // sourceTokenAmountUsed == swapAmount < loanLocal.collateral

                if (destTokenAmountReceived >= loanLocal.principal) {
                    // edge case where swap covers full principal

                    coveredPrincipal = loanLocal.principal;
                    withdrawAmount = destTokenAmountReceived - loanLocal.principal;

                    // excess collateral refunds to the borrower
                    _withdrawAsset(
                        loanParamsLocal.collateralToken,
                        loanLocal.borrower,
                        loanLocal.collateral - sourceTokenAmountUsed
                    );
                    sourceTokenAmountUsed = loanLocal.collateral;
                } else {
                    coveredPrincipal = destTokenAmountReceived;
                    withdrawAmount = 0;
                }
            }
        }

        usedCollateral = sourceTokenAmountUsed > swapAmount ?
            sourceTokenAmountUsed :
            swapAmount;
    }

    function _doCollateralSwap(
        Loan memory loanLocal,
        LoanParams memory loanParamsLocal,
        uint256 swapAmount,
        uint256 principalNeeded,
        bool returnTokenIsCollateral,
        bytes memory loanDataBytes)
        internal
        returns (uint256 destTokenAmountReceived, uint256 sourceTokenAmountUsed, uint256 collateralToLoanSwapRate)
    {
        (destTokenAmountReceived, sourceTokenAmountUsed, collateralToLoanSwapRate) = _loanSwap(
            loanLocal.id,
            loanParamsLocal.collateralToken,
            loanParamsLocal.loanToken,
            loanLocal.borrower,
            swapAmount, // minSourceTokenAmount
            loanLocal.collateral, // maxSourceTokenAmount
            returnTokenIsCollateral ?
                principalNeeded :  // requiredDestTokenAmount
                0,
            false, // bypassFee
            loanDataBytes
        );
        require(destTokenAmountReceived >= principalNeeded, "insufficient dest amount");
        require(sourceTokenAmountUsed <= loanLocal.collateral, "excessive source amount");
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
        uint256 collateralToLoanSwapRate,
        CloseTypes closeType)
        internal
    {
        _closeLoan(
            loanLocal,
            loanCloseAmount
        );

        address _priceFeeds = priceFeeds;
        uint256 currentMargin;
        uint256 collateralToLoanRate;

        // this is still called even with full loan close to return collateralToLoanRate
        (bool success, bytes memory data) = _priceFeeds.staticcall(
            abi.encodeWithSelector(
                IPriceFeeds(_priceFeeds).getCurrentMargin.selector,
                loanParamsLocal.loanToken,
                loanParamsLocal.collateralToken,
                loanLocal.principal,
                loanLocal.collateral
            )
        );
        assembly {
            if eq(success, 1) {
                currentMargin := mload(add(data, 32))
                collateralToLoanRate := mload(add(data, 64))
            }
        }
        //// Note: We can safely skip the margin check if closing via closeWithDeposit or if closing the loan in full by any method ////
        require(
            closeType == CloseTypes.Deposit ||
            loanLocal.principal == 0 || // loan fully closed
            currentMargin > loanParamsLocal.maintenanceMargin,
            "unhealthy position"
        );

        _emitClosingEvents(
            loanParamsLocal,
            loanLocal,
            loanCloseAmount,
            collateralCloseAmount,
            collateralToLoanRate,
            collateralToLoanSwapRate,
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
            activeLoansSet.removeBytes32(loanLocal.id);
            lenderLoanSets[loanLocal.lender].removeBytes32(loanLocal.id);
            borrowerLoanSets[loanLocal.borrower].removeBytes32(loanLocal.id);
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

        uint256 interestTime = block.timestamp;
        if (interestTime > loanLocal.endTimestamp) {
            interestTime = loanLocal.endTimestamp;
        }

        _settleFeeRewardForInterestExpense(
            loanInterestLocal,
            loanLocal.id,
            loanParamsLocal.loanToken,
            loanLocal.borrower,
            interestTime
        );

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

        // update remaining lender interest values
        lenderInterestLocal.principalTotal = lenderInterestLocal.principalTotal
            .sub(closePrincipal);

        uint256 owedTotal = lenderInterestLocal.owedTotal;
        lenderInterestLocal.owedTotal = owedTotal > interestRefundToBorrower ?
            owedTotal - interestRefundToBorrower :
            0;

        return interestRefundToBorrower;
    }

    function _emitClosingEvents(
        LoanParams memory loanParamsLocal,
        Loan memory loanLocal,
        uint256 loanCloseAmount,
        uint256 collateralCloseAmount,
        uint256 collateralToLoanRate,
        uint256 collateralToLoanSwapRate,
        uint256 currentMargin,
        CloseTypes closeType)
        internal
    {
        if (closeType == CloseTypes.Deposit) {
            emit CloseWithDeposit(
                loanLocal.borrower,                             // user (borrower)
                loanLocal.lender,                               // lender
                loanLocal.id,                                   // loanId
                msg.sender,                                     // closer
                loanParamsLocal.loanToken,                      // loanToken
                loanParamsLocal.collateralToken,                // collateralToken
                loanCloseAmount,                                // loanCloseAmount
                collateralCloseAmount,                          // collateralCloseAmount
                collateralToLoanRate,                           // collateralToLoanRate
                currentMargin                                   // currentMargin
            );
        } else if (closeType == CloseTypes.Swap) {
            // exitPrice = 1 / collateralToLoanSwapRate
            if (collateralToLoanSwapRate != 0) {
                collateralToLoanSwapRate = SafeMath.div(10**36, collateralToLoanSwapRate);
            }

            // currentLeverage = 100 / currentMargin
            if (currentMargin != 0) {
                currentMargin = SafeMath.div(10**38, currentMargin);
            }

            emit CloseWithSwap(
                loanLocal.borrower,                             // user (trader)
                loanLocal.lender,                               // lender
                loanLocal.id,                                   // loanId
                loanParamsLocal.collateralToken,                // collateralToken
                loanParamsLocal.loanToken,                      // loanToken
                msg.sender,                                     // closer
                collateralCloseAmount,                          // positionCloseSize
                loanCloseAmount,                                // loanCloseAmount
                collateralToLoanSwapRate,                       // exitPrice (1 / collateralToLoanSwapRate)
                currentMargin                                   // currentLeverage
            );
        } else { // closeType == CloseTypes.Liquidation
            emit Liquidate(
                loanLocal.borrower,                             // user (borrower)
                msg.sender,                                     // liquidator
                loanLocal.id,                                   // loanId
                loanLocal.lender,                               // lender
                loanParamsLocal.loanToken,                      // loanToken
                loanParamsLocal.collateralToken,                // collateralToken
                loanCloseAmount,                                // loanCloseAmount
                collateralCloseAmount,                          // collateralCloseAmount
                collateralToLoanRate,                           // collateralToLoanRate
                currentMargin                                   // currentMargin
            );
        }
    }
}
