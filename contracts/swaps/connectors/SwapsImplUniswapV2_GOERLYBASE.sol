/**
 * Copyright 2017-2022, OokiDao. All Rights Reserved.
 * Licensed under the Apache License, Version 2.0.
 */

pragma solidity 0.5.17;

import "../../core/State.sol";
import "../../interfaces/IUniswapV2Router.sol";
import "@openzeppelin-2.5.0/token/ERC20/SafeERC20.sol";
import "../ISwapsImpl.sol";

import "../../../interfaces/IPriceFeeds.sol";
import "../../testhelpers/TestToken.sol";

contract SwapsImplUniswapV2_GOERLYBASE is State, ISwapsImpl {
    using SafeERC20 for IERC20;

    event Logger(string name, uint256 value);
    event LoggerAddress(string name, address value);

    function dexSwap(
        address sourceTokenAddress,
        address destTokenAddress,
        address receiverAddress,
        address returnToSenderAddress,
        uint256 minSourceTokenAmount,
        uint256 maxSourceTokenAmount,
        uint256 requiredDestTokenAmount,
        bytes memory payload
    )
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
        emit LoggerAddress("sourceTokenAddress", sourceTokenAddress);
        emit LoggerAddress("destTokenAddress", destTokenAddress);

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

        emit Logger("sourceTokenAmountUsed", sourceTokenAmountUsed);
        emit Logger("destTokenAmountReceived", destTokenAmountReceived);
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
        uint256 sourceTokenAmount
    ) public view returns (uint256 expectedRate) {
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

    function dexAmountOut(bytes memory payload, uint256 amountIn)
        public
        returns (uint256 amountOut, address midToken)
    {

    }

    function dexAmountOutFormatted(bytes memory payload, uint256 amountIn)
        public
        returns (uint256 amountOut, address midToken)
    {
        return dexAmountOut(payload, amountIn);
    }

    function dexAmountIn(bytes memory payload, uint256 amountOut)
        public
        returns (uint256 amountIn, address midToken)
    {

    }

    function dexAmountInFormatted(bytes memory payload, uint256 amountOut)
        public
        returns (uint256 amountIn, address midToken)
    {
        return dexAmountIn(payload, amountOut);
    }


    function setSwapApprovals(address[] memory tokens) public {

    }

    function revokeApprovals(address[] memory tokens) public {

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
