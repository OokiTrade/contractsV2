/**
 * Copyright 2017-2022, OokiDao. All Rights Reserved.
 * Licensed under the Apache License, Version 2.0.
 */

pragma solidity 0.5.17;

import "../../core/State.sol";
import "../../interfaces/IUniswapV2Router.sol";
import "@openzeppelin-2.5.0/token/ERC20/SafeERC20.sol";
import "../ISwapsImpl.sol";

contract SwapsImplUniswapV2_ETH is State, ISwapsImpl {
    using SafeERC20 for IERC20;

    // mainnet
    //address public constant uniswapRouter = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;   // uniswap
    address public constant uniswapRouter =
        0xd9e1cE17f2641f24aE83637ab66a2cca9C378B9F; // sushiswap
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
            requiredDestTokenAmount
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

    function dexAmountOut(
        bytes memory payload,
        uint256 amountIn
    ) public returns (uint256 amountOut, address midToken) {
		(address sourceTokenAddress, address destTokenAddress) = abi.decode(payload,(address,address));
        if (sourceTokenAddress == destTokenAddress) {
            amountOut = amountIn;
        } else if (amountIn != 0) {
            uint256 tmpValue;

            address[] memory path = new address[](2);
            path[0] = sourceTokenAddress;
            path[1] = destTokenAddress;
            amountOut = _getAmountOut(amountIn, path);

            path = new address[](3);
            path[0] = sourceTokenAddress;
            path[2] = destTokenAddress;

            if (
                sourceTokenAddress != address(wethToken) &&
                destTokenAddress != address(wethToken)
            ) {
                path[1] = address(wethToken);
                tmpValue = _getAmountOut(amountIn, path);
                if (tmpValue > amountOut) {
                    amountOut = tmpValue;
                    midToken = address(wethToken);
                }
            }

            if (sourceTokenAddress != dai && destTokenAddress != dai) {
                path[1] = dai;
                tmpValue = _getAmountOut(amountIn, path);
                if (tmpValue > amountOut) {
                    amountOut = tmpValue;
                    midToken = dai;
                }
            }

            if (sourceTokenAddress != usdc && destTokenAddress != usdc) {
                path[1] = usdc;
                tmpValue = _getAmountOut(amountIn, path);
                if (tmpValue > amountOut) {
                    amountOut = tmpValue;
                    midToken = usdc;
                }
            }

            if (sourceTokenAddress != usdt && destTokenAddress != usdt) {
                path[1] = usdt;
                tmpValue = _getAmountOut(amountIn, path);
                if (tmpValue > amountOut) {
                    amountOut = tmpValue;
                    midToken = usdt;
                }
            }
        }
    }

    function dexAmountOutFormatted(
        bytes memory payload,
        uint256 amountIn)
        public
        returns (uint256 amountOut, address midToken)
    {
	    return dexAmountOut(payload, amountIn);
	}

    function dexAmountIn(
        bytes memory payload,
        uint256 amountOut
    ) public returns (uint256 amountIn, address midToken) {
		(address sourceTokenAddress, address destTokenAddress) = abi.decode(payload,(address,address));
        if (sourceTokenAddress == destTokenAddress) {
            amountIn = amountOut;
        } else if (amountOut != 0) {
            uint256 tmpValue;

            address[] memory path = new address[](2);
            path[0] = sourceTokenAddress;
            path[1] = destTokenAddress;
            amountIn = _getAmountIn(amountOut, path);

            path = new address[](3);
            path[0] = sourceTokenAddress;
            path[2] = destTokenAddress;

            if (
                sourceTokenAddress != address(wethToken) &&
                destTokenAddress != address(wethToken)
            ) {
                path[1] = address(wethToken);
                tmpValue = _getAmountIn(amountOut, path);
                if (tmpValue < amountIn) {
                    amountIn = tmpValue;
                    midToken = address(wethToken);
                }
            }

            if (sourceTokenAddress != dai && destTokenAddress != dai) {
                path[1] = dai;
                tmpValue = _getAmountIn(amountOut, path);
                if (tmpValue < amountIn) {
                    amountIn = tmpValue;
                    midToken = dai;
                }
            }

            if (sourceTokenAddress != usdc && destTokenAddress != usdc) {
                path[1] = usdc;
                tmpValue = _getAmountIn(amountOut, path);
                if (tmpValue < amountIn) {
                    amountIn = tmpValue;
                    midToken = usdc;
                }
            }

            if (sourceTokenAddress != usdt && destTokenAddress != usdt) {
                path[1] = usdt;
                tmpValue = _getAmountIn(amountOut, path);
                if (tmpValue < amountIn) {
                    amountIn = tmpValue;
                    midToken = usdt;
                }
            }

            if (amountIn == uint256(-1)) {
                amountIn = 0;
            }
        }
    }

    function dexAmountInFormatted(
        bytes memory payload,
        uint256 amountOut)
        public
        returns (uint256 amountIn, address midToken)
    {
        return dexAmountIn(payload, amountOut);
	}

    function _getAmountOut(uint256 amountIn, address[] memory path)
        public
        view
        returns (uint256 amountOut)
    {
        (bool success, bytes memory data) = uniswapRouter.staticcall(
            abi.encodeWithSelector(
                0xd06ca61f, // keccak("getAmountsOut(uint256,address[])")
                amountIn,
                path
            )
        );
        if (success) {
            uint256 len = data.length;
            assembly {
                amountOut := mload(add(data, len)) // last amount value array
            }
        }
    }

    function _getAmountIn(uint256 amountOut, address[] memory path)
        public
        view
        returns (uint256 amountIn)
    {
        (bool success, bytes memory data) = uniswapRouter.staticcall(
            abi.encodeWithSelector(
                0x1f00ca74, // keccak("getAmountsIn(uint256,address[])")
                amountOut,
                path
            )
        );
        if (success) {
            uint256 len = data.length;
            assembly {
                amountIn := mload(add(data, 96)) // first amount value in array
            }
        }
        if (amountIn == 0) {
            amountIn = uint256(-1);
        }
    }

    function setSwapApprovals(address[] memory tokens) public {
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
        uint256 requiredDestTokenAmount
    )
        internal
        returns (uint256 sourceTokenAmountUsed, uint256 destTokenAmountReceived)
    {
        address midToken;
        if (requiredDestTokenAmount != 0) {
            (sourceTokenAmountUsed, midToken) = dexAmountIn(
                abi.encode(sourceTokenAddress,destTokenAddress),
                requiredDestTokenAmount
            );
            if (sourceTokenAmountUsed == 0) {
                return (0, 0);
            }
            require(
                sourceTokenAmountUsed <= maxSourceTokenAmount,
                "source amount too high"
            );
        } else {
            sourceTokenAmountUsed = minSourceTokenAmount;
            (destTokenAmountReceived, midToken) = dexAmountOut(
                abi.encode(sourceTokenAddress,destTokenAddress),
                sourceTokenAmountUsed
            );
            if (destTokenAmountReceived == 0) {
                return (0, 0);
            }
        }

        address[] memory path;
        if (midToken != address(0)) {
            path = new address[](3);
            path[0] = sourceTokenAddress;
            path[1] = midToken;
            path[2] = destTokenAddress;
        } else {
            path = new address[](2);
            path[0] = sourceTokenAddress;
            path[1] = destTokenAddress;
        }

        uint256[] memory amounts = IUniswapV2Router(uniswapRouter)
            .swapExactTokensForTokens(
                sourceTokenAmountUsed,
                1, // amountOutMin
                path,
                receiverAddress,
                block.timestamp
            );

        destTokenAmountReceived = amounts[amounts.length - 1];
    }
}
