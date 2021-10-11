/**
 * Copyright 2017-2021, bZeroX, LLC. All Rights Reserved.
 * Licensed under the Apache License, Version 2.0.
 */

pragma solidity 0.5.17;
pragma experimental ABIEncoderV2;
import "../../core/State.sol";
import "@openzeppelin-2.5.0/token/ERC20/SafeERC20.sol";
import "../ISwapsImpl.sol";
import "../../interfaces/ICurve.sol";
import "../../mixins/Path.sol";
import "../../interfaces/ICurvePoolRegistration.sol";

contract SwapsImpl3Curve_ETH is State, ISwapsImpl {
    using SafeERC20 for IERC20;
    using Path for bytes;
    using BytesLib for bytes;
    address public constant PoolRegistry =
        0xbEbc44782C7dB0a1A60Cb6fe97d0b483032FF1C7; //mainnet

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
        (address curvePool, uint128 tokenIn, uint128 tokenOut) = abi.decode(
            path,
            (address, uint128, uint128)
        );
        uint256 amountOut = ICurve(curvePool).get_dy(
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
        (address curvePool, uint128 tokenIn, uint128 tokenOut) = abi.decode(
            path,
            (address, uint128, uint128)
        );
        uint256 amountIn = ICurve(curvePool).get_dy(
            tokenOut,
            tokenIn,
            amountOut
        );
        if (amountIn == 0) {
            amountIn = uint256(-1);
        }
        return amountIn;
    }

    function setSwapApprovals(address[] memory tokens) public {
        require(
            ICurvePoolRegistration(PoolRegistry).CheckPoolValidity(tokens[0])
        );
        for (uint256 i = 1; i < tokens.length; i++) {
            IERC20(tokens[i]).safeApprove(tokens[0], 0);
            IERC20(tokens[i]).safeApprove(tokens[0], uint256(-1));
        }
    }

    function _getDexNumber(address pool, address token)
        internal
        view
        returns (uint128)
    {
        return ICurvePoolRegistration(PoolRegistry).GetTokenPoolID(pool, token);
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
            (address curvePool, uint128 tokenIn, uint128 tokenOut) = abi.decode(
                payload,
                (address, uint128, uint128)
            );
            require(
                ICurvePoolRegistration(PoolRegistry).CheckPoolValidity(
                    curvePool
                )
            );
            require(tokenIn == _getDexNumber(curvePool, sourceTokenAddress));
            require(tokenOut == _getDexNumber(curvePool, destTokenAddress));
            (uint256 amountIn, ) = dexAmountIn(
                payload,
                requiredDestTokenAmount
            );
            require(
                amountIn >= minSourceTokenAmount &&
                    amountIn <= sourceTokenAmount
            );
            ICurve(curvePool).exchange(tokenIn, tokenOut, amountIn, 1);
            if (receiverAddress != address(this)) {
                IERC20(destTokenAddress).safeTransfer(
                    receiverAddress,
                    requiredDestTokenAmount
                );
            }
            sourceTokenAmountUsed = amountIn;
            destTokenAmountReceived = requiredDestTokenAmount;
        } else {
            (address curvePool, uint128 tokenIn, uint128 tokenOut) = abi.decode(
                payload,
                (address, uint128, uint128)
            );
            require(tokenIn == _getDexNumber(curvePool, sourceTokenAddress));
            require(tokenOut == _getDexNumber(curvePool, destTokenAddress));
            (uint256 recv, ) = dexAmountOut(payload, minSourceTokenAmount);
            ICurve(curvePool).exchange(
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
