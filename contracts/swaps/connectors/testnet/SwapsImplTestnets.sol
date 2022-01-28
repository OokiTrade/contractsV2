/**
 * Copyright 2017-2022, OokiDao. All Rights Reserved.
 * Licensed under the Apache License, Version 2.0.
 */

pragma solidity 0.5.17;

import "../../../core/State.sol";
import "@openzeppelin-2.5.0/token/ERC20/SafeERC20.sol";
import "../../ISwapsImpl.sol";
import "../../../../interfaces/IPriceFeeds.sol";
import "../../../testhelpers/TestToken.sol";


contract SwapsImplTestnets is State, ISwapsImpl {
    using SafeERC20 for IERC20;

    function dexSwap(
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
                .div(precision)
                .mul(1000) // inject a little swap slippage
                .div(1005);
        } else {
            destTokenAmountReceived = requiredDestTokenAmount;
            sourceTokenAmountUsed = requiredDestTokenAmount
                .mul(precision)
                .div(tradeRate)
                .mul(1005) // inject a little swap slippage
                .div(1000);
            require(sourceTokenAmountUsed <= maxSourceTokenAmount, "destAmount too great");
        }

        TestToken(sourceTokenAddress).burn(sourceTokenAmountUsed);
        TestToken(destTokenAddress).mint(address(this), destTokenAmountReceived);

        if (returnToSenderAddress != address(this) && sourceTokenAmountUsed < maxSourceTokenAmount) {
            // send unused source token back
            IERC20(sourceTokenAddress).safeTransfer(
                returnToSenderAddress,
                maxSourceTokenAmount-sourceTokenAmountUsed
            );
        }
    }

    function dexExpectedRate(
        address sourceTokenAddress,
        address destTokenAddress,
        uint256 sourceTokenAmount)
        public
        view
        returns (uint256)
    {
        address _priceFeeds = priceFeeds;
        if (_priceFeeds == address(0)) {
            //keccak256("TestNet_localPriceFeeds")
            assembly {
                _priceFeeds := sload(0x42b587029048e5d48be95db5da189bcafe09be3a4fbb99206a1c8f4ced7d89b4)
            }
        }
        (uint256 expectedRate,) = IPriceFeeds(_priceFeeds).queryRate(
            sourceTokenAddress,
            destTokenAddress
        );

        return expectedRate;
    }

    function setSwapApprovals(
        address[] calldata tokens)
        external
    {
    
    }

    function localPriceFeed()
        external
        view
        returns (address feed)
    {
        assembly {
            feed := sload(0x42b587029048e5d48be95db5da189bcafe09be3a4fbb99206a1c8f4ced7d89b4)
        }
    }

    function setLocalPriceFeedContract(
        address newContract)
        external
        onlyOwner
    {
        //keccak256("TestNet_localPriceFeeds")
        assembly {
            sstore(0x42b587029048e5d48be95db5da189bcafe09be3a4fbb99206a1c8f4ced7d89b4, newContract)
        }
    }
}