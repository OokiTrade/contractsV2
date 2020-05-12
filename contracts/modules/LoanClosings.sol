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
import "../modifiers/GasTokenUser.sol";
import "../swaps/SwapsUser.sol";


contract LoanClosings is State, LoanClosingsEvents, VaultController, InterestUser, GasTokenUser, SwapsUser, LiquidationHelper {

    constructor() public {}

    function()
        external
    {
        revert("fallback not allowed");
    }

    // closeTrade(bytes32,address,uint256,bytes)
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
            loanParamsLocal.initialMargin,
            loanParamsLocal.maintenanceMargin,
            collateralToLoanRate
        );

        if (loanCloseAmount < maxLiquidatable) {
            collateralWithdrawAmount = SafeMath.div(
                SafeMath.mul(maxSeizable, loanCloseAmount),
                maxLiquidatable
            );
        } else {
            require(loanCloseAmount == maxLiquidatable, "close amount too large");
        }

        if (loanCloseAmount != 0) {
            _returnPrincipalWithDeposit(
                loanParamsLocal.loanToken,
                msg.sender, // payer
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

        emit Liquidate(
            loanLocal.id,
            loanLocal.borrower,
            loanParamsLocal.loanToken,
            loanParamsLocal.collateralToken,
            closeAmount,
            collateralWithdrawAmount,
            collateralToLoanRate,
            currentMargin
        );
    }

    // repayWithDeposit(bytes32,address,address,uint256)
    function repayWithDeposit(
        bytes32 loanId,
        address payer,
        address receiver,
        uint256 closeAmount) // denominated in loanToken
        external
        payable
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
            payer,
            receiver,
            false // amountIsCollateral
        );

        if (amountNeeded != 0) {
            _returnPrincipalWithDeposit(
                loanParamsLocal.loanToken,
                payer,
                loanLocal.lender,
                amountNeeded
            );
        }

        collateralToken = loanParamsLocal.collateralToken;

        collateralWithdrawAmount = _finishRepay(
            loanLocal,
            loanParamsLocal,
            loanCloseAmount,
            receiver
        );
    }

    // closeTrade(bytes32,address,uint256,bytes)
    function closeTrade(
        bytes32 loanId,
        address receiver,
        uint256 positionCloseAmount, // denominated in collateralToken
        bytes calldata loanDataBytes)
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
        return _repayWithCollateral(
            loanId,
            receiver,
            positionCloseAmount,
            true, // amountIsCollateral
            loanDataBytes
        );
    }

    // repayWithCollateral(bytes32,address,uint256,bytes)
    function repayWithCollateral(
        bytes32 loanId,
        address receiver,
        uint256 closeAmount, // denominated in loanToken
        bytes calldata loanDataBytes)
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
        return _repayWithCollateral(
            loanId,
            receiver,
            loanCloseAmount,
            false, // amountIsCollateral
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
            msg.sender, // payer
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
            receiver
        );
    }

    function _settleCloseAmounts(
        Loan memory loanLocal,
        LoanParams memory loanParamsLocal,
        uint256 closeAmount,
        address payer,
        address receiver,
        bool amountIsCollateral)
        internal
        returns(uint256 loanCloseAmount, uint256 amountNeeded)
    {
        require(loanLocal.active, "loan is closed");
        require(
            (
                (
                    msg.sender == loanLocal.borrower || delegatedManagers[loanLocal.id][msg.sender]
                ) && msg.sender == payer
            ) || protocolManagers[msg.sender],
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


        amountNeeded = loanCloseAmount;

        uint256 interestRefund;
        /*
        todo!
//here -> make sure to do this:
        lenderInterestLocal.principalTotal = lenderInterestLocal.principalTotal
            .sub(loanCloseAmount);

        (uint256 interestRefund,) = _settleInterest(
            loanParamsLocal,
            loanLocal,
            loanCloseAmount,
            true, // sendToOracle
            true  // refundToCollateral
        );
        if (interestRefund != 0) {
            loanLocal.positionTokenAmountFilled = loanLocal.positionTokenAmountFilled
                .add(interestRefund);
        }*/

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

    // payer repays principal to lender
    function _returnPrincipalWithDeposit(
        address loanToken,
        address payer,
        address lender,
        uint256 amount)
        internal
    {
        if (amount != 0) {
            if (msg.value == 0) {
                vaultTransfer(
                    loanToken,
                    payer,
                    lender,
                    amount
                );
            } else {
                require(msg.sender == payer, "payer mismatch");
                require(loanToken == address(wethToken), "wrong asset sent");
                require(msg.value >= amount, "not enough ether");
                Address.sendValue(
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
            currentMargin > loanParamsLocal.maintenanceMargin,
            "unhealthy position"
        );

        emit Repay(
            loanLocal.id,
            loanLocal.borrower,
            loanParamsLocal.loanToken,
            loanParamsLocal.collateralToken,
            loanCloseAmount,
            collateralWithdrawAmount,
            collateralToLoanRate,
            currentMargin
        );
    }

    /*function _settleInterest(
        LoanParams memory loanParamsLocal,
        Loan storage loanLocal,
        uint256 closeAmount,
        bool sendToOracle,
        bool refundToCollateral) // will refund to collateral if appropriate
        internal
        returns (uint256 loanAmountBought, uint256 positionAmountSold)
    {
        LoanInterest storage loanInterestLocal = loanInterest[loanLocal.id];
        if (loanInterestLocal.owedPerDay == 0) {
            return (0, 0);
        }

        uint256 owedPerDayRefund;
        if (closeAmount < loanLocal.principal) {
            owedPerDayRefund = SafeMath.div(
                SafeMath.mul(closeAmount, loanInterestLocal.owedPerDay),
                loanLocal.principal
            );
        } else {
            owedPerDayRefund = loanInterestLocal.owedPerDay;
        }

        LenderInterest storage lenderInterestLocal = lenderInterest[loanLocal.lender][loanParamsLocal.loanToken];
        // pay outstanding interest to lender
        _payInterest(
            lenderInterestLocal,
            loanLocal.lender,
            loanParamsLocal.loanToken
        );
        lenderInterestLocal.owedPerDay = lenderInterestLocal.owedPerDay
            .add(owedPerDayRefund);


        // update borrower interest
        uint256 interestTime = block.timestamp;
        if (interestTime > loanLocal.loanEndTimestamp) {
            interestTime = loanLocal.loanEndTimestamp;
        }

        uint256 totalInterestToRefund = loanLocal.loanEndTimestamp
            .sub(interestTime);
        totalInterestToRefund = totalInterestToRefund
            .mul(owedPerDayRefund);
        totalInterestToRefund = totalInterestToRefund
            .div(86400);

        loanInterestLocal.updatedTimestamp = interestTime;
        if (closeAmount < loanLocal.principal) {
            loanInterestLocal.owedPerDay = loanInterestLocal.owedPerDay.sub(owedPerDayRefund);
            loanInterestLocal.depositTotal = loanInterestLocal.depositTotal.sub(totalInterestToRefund);
        } else {
            loanInterestLocal.owedPerDay = 0;
            loanInterestLocal.depositTotal = 0;
        }

        if (totalInterestToRefund != 0) {
            tokenInterestOwed[lender][loanParamsLocal.interestTokenAddress] = totalInterestToRefund < tokenInterestOwed[lender][loanParamsLocal.interestTokenAddress] ?
                tokenInterestOwed[lender][loanParamsLocal.interestTokenAddress].sub(totalInterestToRefund) :
                0;

            if (refundToCollateral &&
                loanParamsLocal.interestTokenAddress == loanParamsLocal.loanToken) {

                if (loanParamsLocal.loanToken == loanLocal.positionTokenAddressFilled) {
                    // payback part of the loan using the interest
                    loanAmountBought = totalInterestToRefund;
                    totalInterestToRefund = 0;
                } else if (loanParamsLocal.interestTokenAddress != loanLocal.collateralTokenFilled) {
                    // we will attempt to pay the borrower back in collateral token
                    if (loanLocal.positionTokenAmountFilled != 0 &&
                        loanLocal.collateralTokenFilled == loanLocal.positionTokenAddressFilled) {

                        (uint256 sourceToDestRate, uint256 sourceToDestPrecision,) = OracleInterface(oracleAddresses[loanParamsLocal.oracleAddress]).getTradeData(
                            loanParamsLocal.interestTokenAddress,
                            loanLocal.collateralTokenFilled,
                            uint256(-1) // get best rate
                        );
                        positionAmountSold = totalInterestToRefund
                            .mul(sourceToDestRate);
                        positionAmountSold = positionAmountSold
                            .div(sourceToDestPrecision);

                        if (positionAmountSold != 0) {
                            if (loanLocal.positionTokenAmountFilled >= positionAmountSold) {
                                loanLocal.positionTokenAmountFilled = loanLocal.positionTokenAmountFilled
                                    .sub(positionAmountSold);

                                // closeAmount always >= totalInterestToRefund at this point, so set used amount
                                loanAmountBought = totalInterestToRefund;
                                totalInterestToRefund = 0;
                            } else {
                                loanAmountBought = loanLocal.positionTokenAmountFilled
                                    .mul(sourceToDestPrecision);
                                loanAmountBought = loanAmountBought
                                    .div(sourceToDestRate);

                                if (loanAmountBought > totalInterestToRefund)
                                    loanAmountBought = totalInterestToRefund;

                                positionAmountSold = loanLocal.positionTokenAmountFilled;
                                totalInterestToRefund = totalInterestToRefund.sub(loanAmountBought);
                                loanLocal.positionTokenAmountFilled = 0;
                            }

                            if (positionAmountSold != 0) {
                                if (!BZxVault(vaultContract).withdrawToken(
                                    loanLocal.collateralTokenFilled,
                                    loanLocal.borrower,
                                    positionAmountSold
                                )) {
                                    revert("_settleInterest: withdrawToken interest failed");
                                }
                            }
                        }
                    }
                }
            }

            if (totalInterestToRefund != 0) {
                // refund interest as is if we weren't able to swap for collateral token above
                if (!BZxVault(vaultContract).withdrawToken(
                    loanParamsLocal.interestTokenAddress,
                    loanLocal.borrower,
                    totalInterestToRefund
                )) {
                    revert("_settleInterest: withdrawToken interest failed");
                }
            }
        }
    }*/
}
