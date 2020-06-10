/**
 * Copyright 2017-2020, bZeroX, LLC. All Rights Reserved.
 * Licensed under the Apache License, Version 2.0.
 */

pragma solidity 0.5.17;

import "../../../core/State.sol";
import "../../../openzeppelin/SafeERC20.sol";
import "../../ISwapsImpl.sol";
import "../../../feeds/IPriceFeeds.sol";
import "../../../testhelpers/TestToken.sol";


contract SwapsImplLocal is State, ISwapsImpl {
    using SafeERC20 for IERC20;

    function internalSwap(
        address sourceTokenAddress,
        address destTokenAddress,
        address /*receiverAddress*/,
        address returnToSenderAddress,
        uint256 minSourceTokenAmount,
        uint256 maxSourceTokenAmount,
        uint256 requiredDestTokenAmount)
        public
        returns (uint256 destTokenAmountReceived, uint256 sourceTokenAmountUsed)
    {
        require(sourceTokenAddress != destTokenAddress, "source == dest");
        require(sourceTokenAddress != address(wethToken) && destTokenAddress != address(wethToken),
            "WETH swaps not supported on testnet"
        );

        (uint256 tradeRate, uint256 precision) = IPriceFeeds(priceFeeds).queryRate(
            sourceTokenAddress,
            destTokenAddress
        );

        if (requiredDestTokenAmount == 0) {
            sourceTokenAmountUsed = minSourceTokenAmount;
            destTokenAmountReceived = minSourceTokenAmount
                .mul(tradeRate)
                .div(precision);
        } else {
            destTokenAmountReceived = requiredDestTokenAmount;
            sourceTokenAmountUsed = requiredDestTokenAmount
                .mul(precision)
                .div(tradeRate);
            require(sourceTokenAmountUsed <= minSourceTokenAmount, "destAmount too great");
        }

        TestToken(sourceTokenAddress).burn(address(this), sourceTokenAmountUsed);
        TestToken(destTokenAddress).mint(address(this), destTokenAmountReceived);

        if (returnToSenderAddress != address(this)) {
            if (sourceTokenAmountUsed < maxSourceTokenAmount) {
                // send unused source token back
                IERC20(sourceTokenAddress).safeTransfer(
                    returnToSenderAddress,
                    maxSourceTokenAmount-sourceTokenAmountUsed
                );
            }
        }
    }

    function internalExpectedRate(
        address sourceTokenAddress,
        address destTokenAddress,
        uint256 sourceTokenAmount)
        public
        view
        returns (uint256)
    {
        (uint256 sourceToDestRate, uint256 sourceToDestPrecision) = IPriceFeeds(priceFeeds).queryRate(
            sourceTokenAddress,
            destTokenAddress
        );

        return sourceTokenAmount
            .mul(sourceToDestRate)
            .div(sourceToDestPrecision);
    }
}