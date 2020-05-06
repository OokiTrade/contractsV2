/**
 * Copyright 2017-2020, bZeroX, LLC. All Rights Reserved.
 * Licensed under the Apache License, Version 2.0.
 */

pragma solidity 0.5.17;
pragma experimental ABIEncoderV2;

import "../core/State.sol";

import "../mixins/VaultController.sol";
import "../mixins/InterestUser.sol";
import "../modifiers/GasTokenUser.sol";
import "../swaps/SwapsUser.sol";


contract LoanClosings is State, VaultController, InterestUser, GasTokenUser, SwapsUser {

    event Repay(
        bytes32 indexed loanId,
        address indexed borrower,
        address indexed loanToken,
        address collateralToken,
        uint256 repayAmount,
        uint256 collateralRefunded,
        uint256 collateralToLoanRate,
        uint256 currentMargin
    );

    constructor() public {}

    function()
        external
    {
        revert("fallback not allowed");
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
            uint256 collateralRefunded,
            address collateralToken
        )
    {
        Loan storage loanLocal = loans[loanId];
        LoanParams storage loanParamsLocal = loanParams[loanLocal.loanParamsId];

        loanCloseAmount = _closeWithTrade(
            loanLocal,
            loanParamsLocal,
            receiver,
            positionCloseAmount,
            false, // isTorqueLoan
            loanDataBytes
        );

        collateralRefunded = _finalizeLoan(
            loanLocal,
            loanParamsLocal,
            loanCloseAmount,
            receiver
        );

        collateralToken = loanParamsLocal.collateralToken;
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
            uint256 collateralRefunded,
            address collateralToken
        )
    {
        Loan storage loanLocal = loans[loanId];
        LoanParams storage loanParamsLocal = loanParams[loanLocal.loanParamsId];

        loanCloseAmount = _closeWithTrade(
            loanLocal,
            loanParamsLocal,
            receiver,
            closeAmount,
            true, // isTorqueLoan
            loanDataBytes
        );

        collateralRefunded = _finalizeLoan(
            loanLocal,
            loanParamsLocal,
            loanCloseAmount,
            receiver
        );

        collateralToken = loanParamsLocal.collateralToken;
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
            uint256 collateralRefunded,
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
            true // isTorqueLoan
        );

        if (amountNeeded != 0) {
            // payer repays principal to lender
            if (msg.value == 0) {
                vaultTransfer(
                    loanParamsLocal.loanToken,
                    payer,
                    loanLocal.lender,
                    amountNeeded
                );
            } else {
                require(msg.sender == payer, "payer mismatch");
                require(loanParamsLocal.loanToken == address(wethToken), "wrong asset sent");
                require(msg.value >= amountNeeded, "not enough ether");
                Address.sendValue(
                    loanLocal.lender,
                    amountNeeded
                );
                if (msg.value > amountNeeded) {
                    // refund overage
                    Address.sendValue(
                        msg.sender,
                        msg.value - amountNeeded
                    );
                }
            }
        } else {
            require(msg.value == 0, "wrong asset sent");
        }

        collateralRefunded = _finalizeLoan(
            loanLocal,
            loanParamsLocal,
            loanCloseAmount,
            receiver
        );

        collateralToken = loanParamsLocal.collateralToken;
    }

    function _closeWithTrade(
        Loan storage loanLocal,
        LoanParams storage loanParamsLocal,
        address receiver,
        uint256 closeAmount,
        bool isTorqueLoan,
        bytes memory loanDataBytes)
        internal
        returns (uint256)
    {
        (uint256 actualCloseAmount, uint256 amountNeeded) = _settleCloseAmounts(
            loanLocal,
            loanParamsLocal,
            closeAmount,
            msg.sender, // payer
            receiver,
            isTorqueLoan
        );

        if (amountNeeded != 0) {
            // reverts in _swap if amountNeeded can't be bought
            (,uint256 sourceTokenAmountUsed) = _loanSwap(
                loanLocal.borrower,
                loanParamsLocal.collateralToken,
                loanParamsLocal.loanToken,
                loanLocal.collateral,
                amountNeeded, // requiredDestTokenAmount
                0, // minConversionRate
                false, // isLiquidation
                loanDataBytes
            );
            loanLocal.collateral = loanLocal.collateral
                .sub(sourceTokenAmountUsed);
        }

        return actualCloseAmount;
    }

    function _finalizeLoan(
        Loan storage loanLocal,
        LoanParams storage loanParamsLocal,
        uint256 actualCloseAmount,
        address receiver)
        internal
        returns (uint256)
    {
        uint256 collateralRefunded;

        if (actualCloseAmount == loanLocal.principal) {
            collateralRefunded = loanLocal.collateral;

            loanLocal.collateral = 0;

            loanLocal.principal = 0;

            loanLocal.active = false;

            loanLocal.loanEndTimestamp = block.timestamp;

            loanLocal.pendingTradesId = 0;

            loansSet.remove(loanLocal.id);
        } else {
            collateralRefunded = SafeMath.div(
                SafeMath.mul(loanLocal.collateral, actualCloseAmount),
                loanLocal.principal
            );

            loanLocal.collateral = loanLocal.collateral
                .sub(collateralRefunded);

            loanLocal.principal = loanLocal.principal
                .sub(actualCloseAmount);
        }

        if (collateralRefunded != 0) {
            // refund collateral
            if (loanParamsLocal.collateralToken == address(wethToken)) {
                vaultEtherWithdraw(
                    receiver,
                    collateralRefunded
                );
            } else {
                vaultWithdraw(
                    loanParamsLocal.collateralToken,
                    receiver,
                    collateralRefunded
                );
            }
        }

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
            actualCloseAmount,
            collateralRefunded,
            collateralToLoanRate,
            currentMargin
        );

        return collateralRefunded;
    }

    function _settleCloseAmounts(
        Loan memory loanLocal,
        LoanParams memory loanParamsLocal,
        uint256 closeAmount,
        address payer,
        address receiver,
        bool isTorqueLoan)
        internal
        returns(uint256, uint256)
    {
        require(closeAmount != 0, "closeAmount is 0");
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


        // require(closeAmount != 0, "closeAmount is 0"); <-- allow 0 closeAmoumt
/*
        Loan storage loanLocal = loans[loanIds[loanParamsLocalHash][borrower]];
        LoanParams memory loanParamsLocal = orders[loanParamsLocalHash];
        require(loanLocal.active &&
            loanLocal.principal != 0 &&
            loanParamsLocal.loanToken != address(0),
            "loan not open"
        );
*/
/*
        address receiver_ = receiver;
        if (receiver_ == address(0) || receiver_ == address(this)) {
            receiver_ = address(wethHelper);
        }
*/
        uint256 actualCloseAmount = closeAmount;
        uint256 amountNeeded;

        if (!isTorqueLoan) {
            (uint256 currentMargin,) = IPriceFeeds(priceFeeds).getCurrentMargin(
                loanParamsLocal.loanToken,
                loanParamsLocal.collateralToken,
                loanLocal.principal,
                loanLocal.collateral
            );
            /*require(
                currentMargin > loanParamsLocal.maintenanceMargin,
                "unhealthy position"
            );*/

            // convert from collateral to principal
            actualCloseAmount = actualCloseAmount
                .mul(10**20)
                .div(currentMargin);
        }

        // can't close more than the full principal
        actualCloseAmount = loanLocal.principal < actualCloseAmount ?
            loanLocal.principal :
            actualCloseAmount;

        amountNeeded = actualCloseAmount;

        uint256 interestRefund;
        /*
        todo!
//here -> make sure to do this:
        lenderInterestLocal.principalTotal = lenderInterestLocal.principalTotal
            .sub(actualCloseAmount);

        (uint256 interestRefund,) = _settleInterest(
            loanParamsLocal,
            loanLocal,
            actualCloseAmount,
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

        return (actualCloseAmount, amountNeeded);
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
