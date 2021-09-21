/**
 * Copyright 2017-2021, bZeroX, LLC. All Rights Reserved.
 * Licensed under the Apache License, Version 2.0.
 */

pragma solidity 0.5.17;

import "../../core/State.sol";
import "../../interfaces/IUniswapV2Router.sol";
import "../../openzeppelin/SafeERC20.sol";
import "../ISwapsImpl.sol";
import "../v3Interfaces/IUniswapV3SwapRouter.sol";
import "../v3Interfaces/uniswapQuoter.sol";

contract SwapsImplUniswapV3_ETH is State, ISwapsImpl {
    using SafeERC20 for IERC20;

    // mainnet
    //address public constant uniswapRouter = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;   // uniswap
    address public constant uniswapRouter = 0xd9e1cE17f2641f24aE83637ab66a2cca9C378B9F;     // sushiswap
    address public constant dai = 0x6B175474E89094C44Da98b954EedeAC495271d0F;
    address public constant usdc = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
    address public constant usdt = 0xdAC17F958D2ee523a2206206994597C13D831ec7;


    function dexSwap(
        address sourceTokenAddress,
        address destTokenAddress,
        address receiverAddress,
        address returnToSenderAddress,
        uint256 minSourceTokenAmount,
        uint256 maxSourceTokenAmount,
        uint256 requiredDestTokenAmount,
		bytes memory payload)
        public
        returns (uint256 destTokenAmountReceived, uint256 sourceTokenAmountUsed)
    {
        require(sourceTokenAddress != destTokenAddress, "source == dest");
        require(supportedTokens[sourceTokenAddress] && supportedTokens[destTokenAddress], "invalid tokens");

        IERC20 sourceToken = IERC20(sourceTokenAddress);
        address _thisAddress = address(this);

        (sourceTokenAmountUsed, destTokenAmountReceived) = _swapWithUni(
            sourceTokenAddress,
            destTokenAddress,
            receiverAddress,
            minSourceTokenAmount,
            maxSourceTokenAmount,
            requiredDestTokenAmount,
			payload
        );

        if (returnToSenderAddress != _thisAddress && sourceTokenAmountUsed < maxSourceTokenAmount) {
            // send unused source token back
            sourceToken.safeTransfer(
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
        returns (uint256 expectedRate)
    {
        revert("unsupported");
    }

    function dexAmountOut(
        bytes memory route,
        uint256 amountIn)
        public
        view
        returns (uint256 amountOut)
    {
        if (amountIn == 0) {
            amountOut = 0;
        } else if (amountIn != 0) {
            amountOut = _getAmountOut(amountIn, route);
        }
    }

    function dexAmountIn(
        bytes memory route,
        uint256 amountOut)
        public
        view
        returns (uint256 amountIn)
    {
        if (amountOut != 0) {
            amountIn = _getAmountIn(amountOut, route);
			
            if (amountIn == uint256(-1)) {
                amountIn = 0;
            }
        }else{
			amountIn = 0;
		}
    }

    function _getAmountOut(
        uint256 amountIn,
        address[] memory path)
        public
        view
        returns (uint256 amountOut)
    {
        amountOut = uniswapQuoter.quoteExactInput(path,amountIn);
        if (amountOut == 0) {
            amountOut = uint256(-1);
        }
    }

    function _getAmountIn(
        uint256 amountOut,
        bytes memory path)
        public
        view
        returns (uint256 amountIn)
    {
        amountIn = uniswapQuoter.quoteExactOutput(path,amoutOut);
        if (amountIn == 0) {
            amountIn = uint256(-1);
        }
    }

    function setSwapApprovals(
        address[] memory tokens)
        public
    {
        for (uint256 i = 0; i < tokens.length; i++) {
            IERC20(tokens[i]).safeApprove(uniswapRouter, 0);
            IERC20(tokens[i]).safeApprove(uniswapRouter, uint256(-1));
        }
    }

    function _swapWithUni(
        address sourceTokenAddress,
        address destTokenAddress,
        address receiverAddress,
        uint256 minSourceTokenAmount,
        uint256 maxSourceTokenAmount,
        uint256 requiredDestTokenAmount,
		bytes memory payload)
        internal
        returns (uint256 sourceTokenAmountUsed, uint256 destTokenAmountReceived)
    {
        IERC20 destToken = IERC20(destTokenAddress);
		uint256 startingBalance = destToken.balanceOf(receiverAddress);
        if (requiredDestTokenAmount != 0) {
            (sourceTokenAmountUsed) = dexAmountIn(
                payload,
                requiredDestTokenAmount
            );
            if (sourceTokenAmountUsed == 0) {
                return (0, 0);
            }
            require(sourceTokenAmountUsed <= maxSourceTokenAmount, "source amount too high");
        } else {
            sourceTokenAmountUsed = minSourceTokenAmount;
            (destTokenAmountReceived) = dexAmountOut(
                payload,
                sourceTokenAmountUsed
            );
            if (destTokenAmountReceived == 0) {
                return (0, 0);
            }
        }
        IUniswapV3SwapRouter.ExactInputParams memory swapParams =
            IUniswapV3SwapRouter.ExactInputParams({
                path: payload,
                recipient: receiverAddress,
                deadline: block.timestamp,
                amountIn: sourceTokenAmountUsed,
                amountOutMinimum: 1
            });
		
        destTokenAmountReceived = IUniswapV3SwapRouter(uniswapRouter).exactInput(swapParams);
		require(destToken.balanceOf(receiverAddress)-startingBalance==destTokenAmountReceived,"improper receive token");
    }
}
