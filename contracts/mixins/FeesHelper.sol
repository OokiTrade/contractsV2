/**
 * Copyright 2017-2022, OokiDao. All Rights Reserved.
 * Licensed under the Apache License, Version 2.0.
 */

pragma solidity 0.5.17;

import "../core/State.sol";
import "@openzeppelin-2.5.0/token/ERC20/SafeERC20.sol";
import "../../interfaces/IPriceFeeds.sol";
import "./VaultController.sol";
import "../events/FeesEvents.sol";
import "../utils/MathUtil.sol";

contract FeesHelper is State, VaultController, FeesEvents {
    using SafeERC20 for IERC20;
    using MathUtil for uint256;

    // calculate trading fee
    function _getTradingFee(
        uint256 feeTokenAmount)
        internal
        view
        returns (uint256)
    {
        return feeTokenAmount
            .mul(tradingFeePercent)
            .divCeil(WEI_PERCENT_PRECISION);
    }

    // calculate loan origination fee
    function _getBorrowingFee(
        uint256 feeTokenAmount)
        internal
        view
        returns (uint256)
    {
        return feeTokenAmount
            .mul(borrowingFeePercent)
            .divCeil(WEI_PERCENT_PRECISION);
    }

    // calculate lender (interest) fee
    function _getLendingFee(
        uint256 feeTokenAmount)
        internal
        view
        returns (uint256)
    {
        return feeTokenAmount
            .mul(lendingFeePercent)
            .divCeil(WEI_PERCENT_PRECISION);
    }

    // settle trading fee
    function _payTradingFee(
        address user,
        bytes32 loanId,
        address feeToken,
        uint256 tradingFee)
        internal
    {
        if (tradingFee != 0) {
            tradingFeeTokensHeld[feeToken] = tradingFeeTokensHeld[feeToken]
                .add(tradingFee);

            emit PayTradingFee(
                user,
                feeToken,
                loanId,
                tradingFee
            );
        }
    }

    // settle loan origination fee
    function _payBorrowingFee(
        address user,
        bytes32 loanId,
        address feeToken,
        uint256 borrowingFee)
        internal
    {
        if (borrowingFee != 0) {
            borrowingFeeTokensHeld[feeToken] = borrowingFeeTokensHeld[feeToken]
                .add(borrowingFee);

            emit PayBorrowingFee(
                user,
                feeToken,
                loanId,
                borrowingFee
            );
        }
    }

    // settle lender (interest) fee
    function _payLendingFee(
        address lender,
        address feeToken,
        uint256 lendingFee)
        internal
    {
        if (lendingFee != 0) {
            lendingFeeTokensHeld[feeToken] = lendingFeeTokensHeld[feeToken]
                .add(lendingFee);

            vaultTransfer(
                feeToken,
                lender,
                address(this),
                lendingFee
            );

            emit PayLendingFee(
                lender,
                feeToken,
                lendingFee
            );
        }
    }
}
