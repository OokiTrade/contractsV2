/**
 * Copyright 2017-2021, bZeroX, LLC. All Rights Reserved.
 * Licensed under the Apache License, Version 2.0.
 */

pragma solidity 0.6.0;
pragma experimental ABIEncoderV2;
import "../../core/State.sol";
import "../../openzeppelin/SafeERC20.sol";
import "../ISwapsImpl.sol";
import "../v3Interfaces/IUniswapV3SwapRouter.sol";
import "../v3Interfaces/uniswapQuoter.sol";
import "../../mixins/Path.sol";

contract SwapsImplUniswapV3_ETH is State, ISwapsImpl {
    using SafeERC20 for IERC20;
    using Path for bytes;
    using BytesLib for bytes;
    address public uniswapSwapRouter;
    address public uniswapQuoteContract;

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
        require(
            supportedTokens[sourceTokenAddress] &&
                supportedTokens[destTokenAddress],
            "invalid tokens"
        );

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

        if (
            returnToSenderAddress != _thisAddress &&
            sourceTokenAmountUsed < maxSourceTokenAmount
        ) {
            // send unused source token back
            sourceToken.safeTransfer(
                returnToSenderAddress,
                maxSourceTokenAmount - sourceTokenAmountUsed
            );
        }
    }

    function dexExpectedRate(
        address sourceTokenAddress,
        address destTokenAddress,
        uint256 sourceTokenAmount
    ) public view returns (uint256 expectedRate) {
        revert("unsupported");
    }

    function dexAmountOut(bytes memory route, uint256 amountIn)
        public
        view
        returns (uint256 amountOut, address midToken)
    {
        if (amountIn == 0) {
            amountOut = 0;
        } else if (amountIn != 0) {
            amountOut = _getAmountOut(amountIn, route);
        }
    }

    function dexAmountIn(bytes memory route, uint256 amountOut)
        public
        view
        returns (uint256 amountIn, address midToken)
    {
        if (amountOut != 0) {
            amountIn = _getAmountIn(amountOut, route);

            if (amountIn == uint256(-1)) {
                amountIn = 0;
            }
        } else {
            amountIn = 0;
        }
    }

    function _getAmountOut(uint256 amountIn, bytes memory path)
        public
        view
        returns (uint256)
    {
        (uint256 amountOut, , , ) = uniswapQuoter(uniswapQuoteContract)
            .quoteExactInput(path, amountIn);
        if (amountOut == 0) {
            amountOut = uint256(-1);
        }
        return amountOut;
    }

    function _getAmountIn(uint256 amountOut, bytes memory path)
        public
        view
        returns (uint256)
    {
        (uint256 amountIn, , , ) = uniswapQuoter(uniswapQuoteContract)
            .quoteExactOutput(path, amountOut);
        if (amountIn == 0) {
            amountIn = uint256(-1);
        }
        return amountIn;
    }

    function setSwapApprovals(address[] memory tokens) public {
        for (uint256 i = 0; i < tokens.length; i++) {
            IERC20(tokens[i]).safeApprove(uniswapSwapRouter, 0);
            IERC20(tokens[i]).safeApprove(uniswapSwapRouter, uint256(-1));
        }
    }

    function _swapWithUni(
        address sourceTokenAddress,
        address destTokenAddress,
        address receiverAddress,
        uint256 minSourceTokenAmount,
        uint256 maxSourceTokenAmount,
        uint256 requiredDestTokenAmount,
        bytes memory payload
    )
        internal
        returns (uint256 sourceTokenAmountUsed, uint256 destTokenAmountReceived)
    {
        if (requiredDestTokenAmount != 0) {
            (
                bytes[] memory routes,
                uint256[] memory amountsIn,
                uint256[] memory amountsOut
            ) = abi.decode(payload, (bytes[], uint256[], uint256[]));
            require(routes.length == amounts.length);
            bytes[] memory encodedTXs = new bytes[](amounts.length);
            uint256 totalAmountsOut = 0;
            uint256 totalAmountsInMax = 0;
            for (uint256 x = 0; x < amountsIn.length; x++) {
                (, address tokenIn, ) = routes[x].decodeFirstPool();
                require(tokenIn == sourceTokenAddress, "improper route");
                address tokenOut = routes[x].toAddress(routes[x].length - 20);
                require(tokenOut == destTokenAddress, "improper destination");
                IUniswapV3SwapRouter.ExactOutputParams
                    memory swapParams = IUniswapV3SwapRouter.ExactOutputParams({
                        path: routes[x],
                        recipient: receiverAddress,
                        deadline: block.timestamp,
                        amountOut: amountsOut[x],
                        amountInMaximum: amountsIn[x]
                    });
                totalAmountsOut = totalAmountsOut + amountsOut[x];
                totalAmountsInMax = totalAmountsInMax + amountsIn[x];
                encodedTXs[x] = abi.encodeWithSelector(
                    IUniswapV3SwapRouter(uniswapSwapRouter)
                        .exactOutput
                        .selector,
                    swapParams
                );
            }
            require(
                totalAmountsOut == requiredDestTokenAmount &&
                    totalAmountsInMax <= maxSourceTokenAmount
            );
            bytes[] memory trueAmountsIn = IUniswapV3SwapRouter(
                uniswapSwapRouter
            ).multicall(encodedTXs);
            uint256 totaledAmountIn = 0;
            for (uint256 x = 0; x < trueAmountsIn.length; x++) {
                totaledAmountIn =
                    totaledAmountIn +
                    abi.decode(trueAmountsIn[x], (uint256));
            }
            sourceTokenAmountUsed = totaledAmountIn;
            destTokenAmountReceived = requiredDestTokenAmount;
        } else {
            (bytes[] memory routes, uint256[] memory amounts) = abi.decode(
                payload,
                (bytes[], uint256[])
            );
            require(routes.length == amounts.length);
            bytes[] memory encodedTXs = new bytes[](amounts.length);
            uint256 totalAmounts = 0;
            for (uint256 x = 0; x < amounts.length; x++) {
                (, address tokenIn, ) = routes[x].decodeFirstPool();
                require(tokenIn == sourceTokenAddress, "improper route");
                address tokenOut = routes[x].toAddress(routes[x].length - 20);
                require(tokenOut == destTokenAddress, "improper destination");
                IUniswapV3SwapRouter.ExactInputParams
                    memory swapParams = IUniswapV3SwapRouter.ExactInputParams({
                        path: routes[x],
                        recipient: receiverAddress,
                        deadline: block.timestamp,
                        amountIn: amounts[x],
                        amountOutMinimum: 1
                    });
                totalAmounts = totalAmounts + amounts[x];
                encodedTXs[x] = abi.encodeWithSelector(
                    IUniswapV3SwapRouter(uniswapSwapRouter).exactInput.selector,
                    swapParams
                );
            }
            sourceTokenAmountUsed = totalAmounts;
            require(totalAmounts <= maxSourceTokenAmount);
            bytes[] memory trueAmountsOut = IUniswapV3SwapRouter(
                uniswapSwapRouter
            ).multicall(encodedTXs);
            uint256 totaledAmountOut = 0;
            for (uint256 x = 0; x < trueAmountsOut.length; x++) {
                totaledAmountOut =
                    totaledAmountOut +
                    abi.decode(trueAmountsOut[x], (uint256));
            }
            destTokenAmountReceived = totaledAmountOut;
        }
    }
}
