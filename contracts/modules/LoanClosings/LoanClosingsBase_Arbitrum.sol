/**
 * Copyright 2017-2022, OokiDao. All Rights Reserved.
 * Licensed under the Apache License, Version 2.0.
 */

pragma solidity 0.5.17;
pragma experimental ABIEncoderV2;

import "../../core/State.sol";
import "../../events/LoanClosingsEvents.sol";
import "../../mixins/VaultController.sol";
import "../../mixins/InterestHandler.sol";
import "../../mixins/FeesHelper.sol";
import "../../mixins/LiquidationHelper.sol";
import "../../swaps/SwapsUser.sol";
import "../../interfaces/ILoanPool.sol";
import "../../governance/PausableGuardian.sol";


contract LoanClosingsBase_Arbitrum is State, LoanClosingsEvents, VaultController, InterestHandler, FeesHelper, SwapsUser, LiquidationHelper, PausableGuardian {

    enum CloseTypes {
        Deposit,
        Swap,
        Liquidation
    }

    function _liquidate(
        bytes32 loanId,
        address receiver,
        uint256 closeAmount)
        internal
        pausable
        returns (
            uint256 loanCloseAmount,
            uint256 seizedAmount,
            address seizedToken
        )
    {
        Loan memory loanLocal = loans[loanId];
        require(loanLocal.active, "loan is closed");

        LoanParams memory loanParamsLocal = loanParams[loanLocal.loanParamsId];

        uint256 principalPlusInterest = _settleInterest(loanLocal.lender, loanId)
            .add(loanLocal.principal);

        (uint256 currentMargin, uint256 collateralToLoanRate) = _getCurrentMargin(
            loanParamsLocal.loanToken,
            loanParamsLocal.collateralToken,
            principalPlusInterest,
            loanLocal.collateral,
            false // silentFail
        );
        require(
            currentMargin <= loanParamsLocal.maintenanceMargin,
            "healthy position"
        );

        if (receiver == address(0)) {
            receiver = msg.sender;
        }

        loanCloseAmount = closeAmount;

        (uint256 maxLiquidatable, uint256 maxSeizable) = _getLiquidationAmounts(
            principalPlusInterest,
            loanLocal.collateral,
            currentMargin,
            loanParamsLocal.maintenanceMargin,
            collateralToLoanRate,
            liquidationIncentivePercent[loanParamsLocal.loanToken][loanParamsLocal.collateralToken]
        );

        if (loanCloseAmount < maxLiquidatable) {
            seizedAmount = maxSeizable
                .mul(loanCloseAmount)
                .div(maxLiquidatable);
        } else {
            if (loanCloseAmount > maxLiquidatable) {
                // adjust down the close amount to the max
                loanCloseAmount = maxLiquidatable;
            }
            seizedAmount = maxSeizable;
        }

        require(loanCloseAmount != 0, "nothing to liquidate");

        // liquidator deposits the principal being closed
        _returnPrincipalWithDeposit(
            loanParamsLocal.loanToken,
            loanLocal.lender,
            loanCloseAmount
        );

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

        _closeLoan(
            loanLocal,
            loanParamsLocal.loanToken,
            loanCloseAmount
        );
    }

    function _closeWithDeposit(
        bytes32 loanId,
        address receiver,
        uint256 depositAmount) // denominated in loanToken
        internal
        pausable
        returns (
            uint256 loanCloseAmount,
            uint256 withdrawAmount,
            address withdrawToken
        )
    {
        require(depositAmount != 0, "depositAmount == 0");

        Loan memory loanLocal = loans[loanId];
        _checkAuthorized(
            loanLocal.id,
            loanLocal.active,
            loanLocal.borrower
        );

        if (receiver == address(0)) {
            receiver = msg.sender;
        }

        LoanParams memory loanParamsLocal = loanParams[loanLocal.loanParamsId];

        uint256 principalPlusInterest = _settleInterest(loanLocal.lender, loanId)
            .add(loanLocal.principal);

        // can't close more than the full principal
        loanCloseAmount = depositAmount > principalPlusInterest ?
            principalPlusInterest :
            depositAmount;

        if (loanCloseAmount != 0) {
            _returnPrincipalWithDeposit(
                loanParamsLocal.loanToken,
                loanLocal.lender,
                loanCloseAmount
            );
        }

        if (loanCloseAmount == principalPlusInterest) {
            // collateral is only withdrawn if the loan is closed in full
            withdrawAmount = loanLocal.collateral;
            withdrawToken = loanParamsLocal.collateralToken;
            loanLocal.collateral = 0;

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
        pausable
        returns (
            uint256 loanCloseAmount,
            uint256 withdrawAmount,
            address withdrawToken
        )
    {
        require(swapAmount != 0, "swapAmount == 0");

        Loan memory loanLocal = loans[loanId];
        _checkAuthorized(
            loanLocal.id,
            loanLocal.active,
            loanLocal.borrower
        );

        if (receiver == address(0)) {
            receiver = msg.sender;
        }

        LoanParams memory loanParamsLocal = loanParams[loanLocal.loanParamsId];

        uint256 principalPlusInterest = _settleInterest(loanLocal.lender, loanId)
            .add(loanLocal.principal);

        if (swapAmount > loanLocal.collateral) {
            swapAmount = loanLocal.collateral;
        }

        loanCloseAmount = principalPlusInterest;
        if (swapAmount != loanLocal.collateral) {
            loanCloseAmount = loanCloseAmount
                .mul(swapAmount)
                .div(loanLocal.collateral);
        }
        require(loanCloseAmount != 0, "loanCloseAmount == 0");

        uint256 usedCollateral;
        uint256 collateralToLoanSwapRate;
        (usedCollateral, withdrawAmount, collateralToLoanSwapRate) = _coverPrincipalWithSwap(
            loanLocal,
            loanParamsLocal,
            swapAmount,
            loanCloseAmount,
            returnTokenIsCollateral,
            loanDataBytes
        );

        if (loanCloseAmount != 0) {
            // Repays principal to lender
            vaultWithdraw(
                loanParamsLocal.loanToken,
                loanLocal.lender,
                loanCloseAmount
            );
        }

        if (usedCollateral != 0) {
            loanLocal.collateral = loanLocal.collateral
                .sub(usedCollateral);
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

        _finalizeClose(
            loanLocal,
            loanParamsLocal,
            loanCloseAmount,
            usedCollateral,
            collateralToLoanSwapRate,
            CloseTypes.Swap
        );
    }

    function _updateDepositAmount(
        bytes32 loanId,
        uint256 principalBefore,
        uint256 principalAfter)
        internal
    {
        uint256 depositValueAsLoanToken;
        uint256 depositValueAsCollateralToken;
        bytes32 slot = keccak256(abi.encode(loanId, LoanDepositValueID));
        assembly {
            switch principalAfter
            case 0 {
                sstore(slot, 0)
                sstore(add(slot, 1), 0)
            }
            default {
                depositValueAsLoanToken := div(mul(sload(slot), principalAfter), principalBefore)
                sstore(slot, depositValueAsLoanToken)

                slot := add(slot, 1)
                depositValueAsCollateralToken := div(mul(sload(slot), principalAfter), principalBefore)
                sstore(slot, depositValueAsCollateralToken)
            }
        }

        emit LoanDeposit(
            loanId,
            depositValueAsLoanToken,
            depositValueAsCollateralToken
        );
    }

    function _checkAuthorized(
        bytes32 _id,
        bool _active,
        address _borrower)
        internal
        view
    {
        require(_active, "loan is closed");
        require(
            msg.sender == _borrower ||
            delegatedManagers[_id][msg.sender],
            "unauthorized"
        );
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
        returns (uint256 usedCollateral, uint256 withdrawAmount, uint256 collateralToLoanSwapRate)
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
            if (destTokenAmountReceived > principalNeeded) {
                // better fill than expected, so send excess to borrower
                vaultWithdraw(
                    loanParamsLocal.loanToken,
                    loanLocal.borrower,
                    destTokenAmountReceived - principalNeeded
                );
            }
            withdrawAmount = swapAmount > sourceTokenAmountUsed ?
                swapAmount - sourceTokenAmountUsed :
                0;
        } else {
            require(sourceTokenAmountUsed == swapAmount, "swap error");
            withdrawAmount = destTokenAmountReceived - principalNeeded;
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
            /*if (assetToken == address(wethToken)) {
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
            }*/
            // Arbitrum has issues with eth withdraw from weth
            vaultWithdraw(
                assetToken,
                receiver,
                assetAmount
            );
        }
    }

    function _getCurrentMargin(
        address loanToken,
        address collateralToken,
        uint256 principal,
        uint256 collateral,
        bool silentFail)
        internal
        returns (uint256 currentMargin, uint256 collateralToLoanRate)
    {
        address _priceFeeds = priceFeeds;
        (bool success, bytes memory data) = _priceFeeds.staticcall(
            abi.encodeWithSelector(
                IPriceFeeds(_priceFeeds).getCurrentMargin.selector,
                loanToken,
                collateralToken,
                principal,
                collateral
            )
        );
        if (success) {
            assembly {
                currentMargin := mload(add(data, 32))
                collateralToLoanRate := mload(add(data, 64))
            }
        } else {
            require(silentFail, "margin query failed");
        }
    }

    function _finalizeClose(
        Loan memory loanLocal,
        LoanParams memory loanParamsLocal,
        uint256 loanCloseAmount,
        uint256 collateralCloseAmount,
        uint256 collateralToLoanSwapRate,
        CloseTypes closeType)
        internal
    {
        (uint256 principalBefore, uint256 principalAfter)  = _closeLoan(
            loanLocal,
            loanParamsLocal.loanToken,
            loanCloseAmount
        );

        // this is still called even with full loan close to return collateralToLoanRate
        (uint256 currentMargin, uint256 collateralToLoanRate) = _getCurrentMargin(
            loanParamsLocal.loanToken,
            loanParamsLocal.collateralToken,
            principalAfter,
            loanLocal.collateral,
            true // silentFail
        );

        //// Note: We can safely skip the margin check if closing via closeWithDeposit or if closing the loan in full by any method ////
        require(
            closeType == CloseTypes.Deposit ||
            principalAfter == 0 || // loan fully closed
            currentMargin > loanParamsLocal.maintenanceMargin,
            "unhealthy position"
        );

        _updateDepositAmount(
            loanLocal.id,
            principalBefore,
            principalAfter
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
        Loan memory loanLocal,
        address loanToken,
        uint256 loanCloseAmount)
        internal
        returns (uint256 principalBefore, uint256 principalAfter)
    {
        require(loanCloseAmount != 0, "nothing to close");

        principalBefore = loanLocal.principal;
        uint256 loanInterest = loanInterestTotal[loanLocal.id];

        if (loanCloseAmount == principalBefore.add(loanInterest)) {
            poolPrincipalTotal[loanLocal.lender] = poolPrincipalTotal[loanLocal.lender]
                .sub(principalBefore);
            loanLocal.principal = 0;

            loanInterestTotal[loanLocal.id] = 0;

            loanLocal.active = false;
            loanLocal.endTimestamp = block.timestamp;
            loanLocal.pendingTradesId = 0;
            activeLoansSet.removeBytes32(loanLocal.id);
            lenderLoanSets[loanLocal.lender].removeBytes32(loanLocal.id);
            borrowerLoanSets[loanLocal.borrower].removeBytes32(loanLocal.id);
        } else {
            // interest is paid before principal
            if (loanCloseAmount >= loanInterest) {
                principalAfter = principalBefore.sub(loanCloseAmount - loanInterest);

                loanLocal.principal = principalAfter;
                poolPrincipalTotal[loanLocal.lender] = poolPrincipalTotal[loanLocal.lender]
                    .sub(loanCloseAmount - loanInterest);

                loanInterestTotal[loanLocal.id] = 0;
            } else {
                principalAfter = principalBefore;
                loanInterestTotal[loanLocal.id] = loanInterest - loanCloseAmount;
                loanInterest = loanCloseAmount;
            }
        }

        uint256 poolInterest = poolInterestTotal[loanLocal.lender];
        if (poolInterest > loanInterest) {
            poolInterestTotal[loanLocal.lender] = poolInterest - loanInterest;
        }
        else {
            poolInterestTotal[loanLocal.lender] = 0;
        }

        // pay fee
        _payLendingFee(
            loanLocal.lender,
            loanToken,
            _getLendingFee(loanInterest)
        );

        loans[loanLocal.id] = loanLocal;
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
                collateralToLoanSwapRate = SafeMath.div(WEI_PRECISION * WEI_PRECISION, collateralToLoanSwapRate);
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
