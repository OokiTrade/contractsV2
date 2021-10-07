/**
 * Copyright 2017-2021, bZeroX, LLC. All Rights Reserved.
 * Licensed under the Apache License, Version 2.0.
 */

pragma solidity 0.6.0;
pragma experimental ABIEncoderV2;
import "../../core/State.sol";
import "../../openzeppelin/SafeERC20.sol";
import "../ISwapsImpl.sol";
import "../v3Interfaces/ICurve.sol";
import "../../mixins/Path.sol";

contract SwapsImpl3Curve_ETH is State, ISwapsImpl {
    using SafeERC20 for IERC20;
    using Path for bytes;
    using BytesLib for bytes;
    address public constant curveSwapRouter =
        0xE592427A0AEce92De3Edee1F18E0157C05861564; //mainnet
    address public constant uniswapQuoteContract =
        0xb27308f9F90D607463bb33eA1BeBb41C27CE5AB6; //mainnet
    address public constant DAI = 0x6B175474E89094C44Da98b954EedeAC495271d0F;
    address public constant USDC = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
    address public constant USDT = 0xdAC17F958D2ee523a2206206994597C13D831ec7;
    uint128 public constant DAI_NUMBER = 0;
    uint128 public constant USDC_NUMBER = 1;
    uint128 public constant USDT_NUMBER = 2;

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
        override
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
        (sourceTokenAmountUsed, destTokenAmountReceived) = _swapWithCurve(
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
    ) public view override returns (uint256 expectedRate) {
        revert("unsupported");
    }

    function dexAmountOut(bytes memory route, uint256 amountIn)
        public
        override
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
        override
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
        (uint128 tokenIn, uint128 tokenOut) = abi.decode(
            path,
            (uint128, uint128)
        );
        uint256 amountOut = ICurve(curveSwapRouter).get_dy(
            tokenIn,
            tokenOut,
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
        (uint128 tokenIn, uint128 tokenOut) = abi.decode(
            path,
            (uint128, uint128)
        );
        uint256 amountIn = ICurve(curveSwapRouter).get_dy(
            tokenOut,
            tokenIn,
            amountOut
        );
        if (amountIn == 0) {
            amountIn = uint256(-1);
        }
        return amountIn;
    }

    function setSwapApprovals(address[] memory tokens) public override {
        for (uint256 i = 0; i < tokens.length; i++) {
            IERC20(tokens[i]).safeApprove(curveSwapRouter, 0);
            IERC20(tokens[i]).safeApprove(curveSwapRouter, uint256(-1));
        }
    }

    function _getDexNumber(address token) internal view returns (uint128) {
        if (token == DAI) {
            return DAI_NUMBER;
        }
        if (token == USDC) {
            return USDC_NUMBER;
        }
        if (token == USDT) {
            return USDT_NUMBER;
        }
    }

    function _swapWithCurve(
        address sourceTokenAddress,
        address destTokenAddress,
        address receiverAddress,
        uint256 minSourceTokenAmount,
        uint256 sourceTokenAmount,
        uint256 requiredDestTokenAmount,
        bytes memory payload
    )
        internal
        returns (uint256 sourceTokenAmountUsed, uint256 destTokenAmountReceived)
    {
        if (requiredDestTokenAmount != 0) {
            (uint128 tokenIn, uint128 tokenOut) = abi.decode(
                payload,
                (uint128, uint128)
            );
            require(tokenIn == _getDexNumber(sourceTokenAddress));
            require(tokenOut == _getDexNumber(destTokenAddress));
            (uint256 amountIn, ) = dexAmountIn(
                payload,
                requiredDestTokenAmount
            );
            require(
                amountIn >= minSourceTokenAmount &&
                    amountIn <= sourceTokenAmount
            );
            ICurve(curveSwapRouter).exchange(tokenIn, tokenOut, amountIn, 1);
            if (receiverAddress != address(this)) {
                IERC20(destTokenAddress).safeTransfer(
                    receiverAddress,
                    requiredDestTokenAmount
                );
            }
            sourceTokenAmountUsed = amountIn;
            destTokenAmountReceived = requiredDestTokenAmount;
        } else {
            (uint128 tokenIn, uint128 tokenOut) = abi.decode(
                payload,
                (uint128, uint128)
            );
            require(tokenIn == _getDexNumber(sourceTokenAddress));
            require(tokenOut == _getDexNumber(destTokenAddress));
            (uint256 recv, ) = dexAmountOut(payload, minSourceTokenAmount);
            ICurve(curveSwapRouter).exchange(
                tokenIn,
                tokenOut,
                minSourceTokenAmount,
                1
            );
            if (receiverAddress != address(this)) {
                IERC20(destTokenAddress).safeTransfer(receiverAddress, recv);
            }
            sourceTokenAmountUsed = minSourceTokenAmount;
            destTokenAmountReceived = recv;
        }
    }
}
