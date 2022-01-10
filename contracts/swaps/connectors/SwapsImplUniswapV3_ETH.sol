/**
 * Copyright 2017-2021, bZeroX, LLC. All Rights Reserved.
 * Licensed under the Apache License, Version 2.0.
 */

pragma solidity 0.5.17;
pragma experimental ABIEncoderV2;
import "../../core/State.sol";
import "@openzeppelin-2.5.0/token/ERC20/SafeERC20.sol";
import "../ISwapsImpl.sol";
import "../../interfaces/IUniswapV3SwapRouter.sol";
import "../../interfaces/IUniswapQuoter.sol";
import "../../mixins/Path.sol";

contract SwapsImplUniswapV3_ETH is State, ISwapsImpl {
    using SafeERC20 for IERC20;
    using Path for bytes;
    using BytesLib for bytes;
    address public constant uniswapSwapRouter =
        0xE592427A0AEce92De3Edee1F18E0157C05861564; //mainnet
    address public constant uniswapQuoteContract =
        0xb27308f9F90D607463bb33eA1BeBb41C27CE5AB6; //mainnet

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
        returns (uint256)
    {
        uint256 amountOut = IUniswapQuoter(uniswapQuoteContract).quoteExactInput(
            path,
            amountIn
        );
        if (amountOut == 0) {
            amountOut = uint256(-1);
        }
        return amountOut;
    }

    function _getAmountIn(uint256 amountOut, bytes memory path)
        public
        returns (uint256)
    {
        uint256 amountIn = IUniswapQuoter(uniswapQuoteContract).quoteExactOutput(
            path,
            amountOut
        );
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
            IUniswapV3SwapRouter.ExactOutputParams[] memory exactParams = abi
                .decode(payload, (IUniswapV3SwapRouter.ExactOutputParams[]));
            bytes[] memory encodedTXs = new bytes[](exactParams.length);
            uint256 totalAmountsOut = 0;
            uint256 totalAmountsInMax = 0;
            for (uint256 uniqueOutputParam = 0; uniqueOutputParam < exactParams.length; uniqueOutputParam++) {
                require(receiverAddress == exactParams[uniqueOutputParam].recipient);
                address tokenIn = exactParams[uniqueOutputParam].path.toAddress(0);
                require(tokenIn == destTokenAddress, "improper destination");
                require(
                    exactParams[uniqueOutputParam].path.toAddress(
                        exactParams[uniqueOutputParam].path.length - 20
                    ) == sourceTokenAddress,
                    "improper source"
                );
                exactParams[uniqueOutputParam].amountOut = requiredDestTokenAmount
                    .mul(exactParams[uniqueOutputParam].amountOut)
                    .div(100);
                exactParams[uniqueOutputParam].amountInMaximum = maxSourceTokenAmount
                    .mul(exactParams[uniqueOutputParam].amountInMaximum)
                    .div(100);
                totalAmountsOut = totalAmountsOut.add(exactParams[uniqueOutputParam].amountOut);
                totalAmountsInMax = totalAmountsInMax.add(
                    exactParams[uniqueOutputParam].amountInMaximum
                );

                encodedTXs[uniqueOutputParam] = abi.encodeWithSelector(
                    IUniswapV3SwapRouter(uniswapSwapRouter)
                        .exactOutput
                        .selector,
                    exactParams[uniqueOutputParam]
                );
            }
			if(totalAmountsOut<requiredDestTokenAmount){
                exactParams[0].amountOut = exactParams[0]
                    .amountOut
                    .add(requiredDestTokenAmount.sub(totalAmountsOut)); //adds displacement to first swap set
			}
			if(totalAmountsInMax < maxSourceTokenAmount){
                exactParams[0].amountInMaximum = exactParams[0]
                    .amountInMaximum
                    .add(maxSourceTokenAmount.sub(totalAmountsInMax)); //adds displacement to first swap set		
			}
			totalAmountsOut = totalAmountsOut.add(requiredDestTokenAmount.sub(totalAmountsOut)); //correcting value
			totalAmountsInMax = totalAmountsInMax.add(maxSourceTokenAmount.sub(totalAmountsInMax)); //correcting value 
			encodedTXs[0] = abi.encodeWithSelector(
				IUniswapV3SwapRouter(uniswapSwapRouter).exactOutput.selector,
				exactParams[0]
			);
            require(
                totalAmountsOut == requiredDestTokenAmount &&
                    totalAmountsInMax == maxSourceTokenAmount
            ); //redundant check

            bytes[] memory trueAmountsIn = IUniswapV3SwapRouter(
                uniswapSwapRouter
            ).multicall(encodedTXs);

            uint256 totaledAmountIn = 0;
            for (uint256 uniqueAmountIn = 0; uniqueAmountIn < trueAmountsIn.length; uniqueAmountIn++) {
                uint256 tempAmountIn = abi.decode(trueAmountsIn[uniqueAmountIn], (uint256));
                totaledAmountIn = totaledAmountIn + tempAmountIn;
            }
            sourceTokenAmountUsed = totaledAmountIn;
            destTokenAmountReceived = requiredDestTokenAmount;
        } else {
            IUniswapV3SwapRouter.ExactInputParams[] memory exactParams = abi
                .decode(payload, (IUniswapV3SwapRouter.ExactInputParams[]));
            bytes[] memory encodedTXs = new bytes[](exactParams.length);
            uint256 totalAmounts = 0;
            for (uint256 uniqueInputParam = 0; uniqueInputParam < exactParams.length; uniqueInputParam++) {
                require(receiverAddress == exactParams[uniqueInputParam].recipient);
                address tokenIn = exactParams[uniqueInputParam].path.toAddress(0);
                require(tokenIn == sourceTokenAddress, "improper route");
                address tokenOut = exactParams[uniqueInputParam].path.toAddress(
                    exactParams[uniqueInputParam].path.length - 20
                );
                require(tokenOut == destTokenAddress, "improper destination");
                exactParams[uniqueInputParam].amountIn = exactParams[uniqueInputParam]
                    .amountIn
                    .mul(minSourceTokenAmount)
                    .div(100); //amountIn on data is % of funds to use per route. Total should add to source token amount or else it fails. take into consideration rounding
                totalAmounts = totalAmounts.add(exactParams[uniqueInputParam].amountIn);
                encodedTXs[uniqueInputParam] = abi.encodeWithSelector(
                    IUniswapV3SwapRouter(uniswapSwapRouter).exactInput.selector,
                    exactParams[uniqueInputParam]
                );
            }
			if(totalAmounts<minSourceTokenAmount){
                exactParams[0].amountIn = exactParams[0]
                    .amountIn
                    .add(minSourceTokenAmount.sub(totalAmounts)); //adds displacement to first swap set
                totalAmounts = totalAmounts.add(minSourceTokenAmount.sub(totalAmounts));
                encodedTXs[0] = abi.encodeWithSelector(
                    IUniswapV3SwapRouter(uniswapSwapRouter).exactInput.selector,
                    exactParams[0]
                );
			}
            sourceTokenAmountUsed = totalAmounts;
            require(
                totalAmounts == minSourceTokenAmount,
                "improper swap amounts"
            );
            bytes[] memory trueAmountsOut = IUniswapV3SwapRouter(
                uniswapSwapRouter
            ).multicall(encodedTXs);
            uint256 totaledAmountOut = 0;
            for (uint256 uniqueAmountOut = 0; uniqueAmountOut < trueAmountsOut.length; uniqueAmountOut++) {
                uint256 tempAmountOut = abi.decode(
                    trueAmountsOut[uniqueAmountOut],
                    (uint256)
                );
                totaledAmountOut = totaledAmountOut + tempAmountOut;
            }
            destTokenAmountReceived = totaledAmountOut;
        }
    }
}
