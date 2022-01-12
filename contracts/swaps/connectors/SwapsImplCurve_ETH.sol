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

contract SwapsImplCurve_ETH is State, ISwapsImpl {
    using SafeERC20 for IERC20;
    using Path for bytes;
    using BytesLib for bytes;
    address public constant PoolRegistry =
        0x18E317A7D70d8fBf8e6E893616b52390EbBdb629; //set to address for monitoring Curve pools
    bytes4 public constant ExchangeUnderlyingSig =
        bytes4(
            keccak256("exchange_underlying(uint256,uint256,uint256,uint256)")
        );
    bytes4 public constant ExchangeSig =
        bytes4(keccak256("exchange(uint256,uint256,uint256,uint256)"));
    bytes4 public constant GetDySig =
        bytes4(keccak256("get_dy(uint256,uint256,uint256)"));
    bytes4 public constant GetDyUnderlyingSig =
        bytes4(keccak256("get_dy_underlying(uint256,uint256,uint256)"));

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
        (bytes4 sig, address curvePool, uint128 tokenIn, uint128 tokenOut) = abi
            .decode(path, (bytes4, address, uint128, uint128));
        uint256 amountOut;
        if (sig == GetDySig || sig == ExchangeSig) {
            amountOut = ICurve(curvePool).get_dy(
                int128(tokenOut),
                int128(tokenIn),
                amountIn
            );
        } else if (sig == GetDyUnderlyingSig || sig == ExchangeUnderlyingSig) {
            amountOut = ICurve(curvePool).get_dy_underlying(
                int128(tokenOut),
                int128(tokenIn),
                amountIn
            );
        } else {
            revert("Unsupported Signature");
        }
        if (amountOut == 0) {
            amountOut = uint256(-1);
        }
        return amountOut;
    }

    function _getAmountIn(uint256 amountOut, bytes memory path)
        public
        returns (uint256)
    {
        (bytes4 sig, address curvePool, uint128 tokenIn, uint128 tokenOut) = abi
            .decode(path, (bytes4, address, uint128, uint128));
        uint256 amountIn;
        if (sig == GetDySig || sig == ExchangeSig) {
            amountIn = ICurve(curvePool).get_dy(
                int128(tokenOut),
                int128(tokenIn),
                amountOut
            );
        } else if (sig == GetDyUnderlyingSig || sig == ExchangeUnderlyingSig) {
            amountIn = ICurve(curvePool).get_dy_underlying(
                int128(tokenOut),
                int128(tokenIn),
                amountOut
            );
        } else {
            revert("Unsupported Signature");
        }
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

    function _getDexNumber(address pool, uint256 tokenID)
        internal
        returns (address)
    {
        address token = address(0);
        if (ICurvePoolRegistration(PoolRegistry).getPoolType(pool) == 0) {
            token = ICurve(pool).underlying_coins(tokenID);
        } else {
            token = ICurve(pool).coins(tokenID);
        }
        return token;
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
            (
                bytes4 sig,
                address curvePool,
                uint128 tokenIn,
                uint128 tokenOut
            ) = abi.decode(payload, (bytes4, address, uint128, uint128));
            require(
                ICurvePoolRegistration(PoolRegistry).CheckPoolValidity(
                    curvePool
                )
            );
            require(sourceTokenAddress == _getDexNumber(curvePool, tokenIn));
            require(destTokenAddress == _getDexNumber(curvePool, tokenOut));
            (uint256 amountIn, ) = dexAmountIn(
                payload,
                requiredDestTokenAmount
            );
            require(amountIn <= sourceTokenAmount, "too much");
            if (sig == ExchangeUnderlyingSig) {
                ICurve(curvePool).exchange_underlying(
                    int128(tokenIn),
                    int128(tokenOut),
                    amountIn,
                    1
                );
            } else if (sig == ExchangeSig) {
                ICurve(curvePool).exchange(
                    int128(tokenIn),
                    int128(tokenOut),
                    amountIn,
                    1
                );
            } else {
                revert("Unsupported Signature");
            }
            if (receiverAddress != address(this)) {
                IERC20(destTokenAddress).safeTransfer(
                    receiverAddress,
                    requiredDestTokenAmount
                );
            }
            sourceTokenAmountUsed = amountIn;
            destTokenAmountReceived = requiredDestTokenAmount;
        } else {
            (
                bytes4 sig,
                address curvePool,
                uint128 tokenIn,
                uint128 tokenOut
            ) = abi.decode(payload, (bytes4, address, uint128, uint128));
            require(
                ICurvePoolRegistration(PoolRegistry).CheckPoolValidity(
                    curvePool
                )
            );

            require(
                sourceTokenAddress == _getDexNumber(curvePool, tokenIn),
                "source token number off"
            );
            require(
                destTokenAddress == _getDexNumber(curvePool, tokenOut),
                "dest token number off"
            );

            (uint256 recv, ) = dexAmountOut(payload, minSourceTokenAmount);
            if (sig == ExchangeUnderlyingSig) {
                ICurve(curvePool).exchange_underlying(
                    int128(tokenIn),
                    int128(tokenOut),
                    minSourceTokenAmount,
                    1
                );
            } else if (sig == ExchangeSig) {
                ICurve(curvePool).exchange(
                    int128(tokenIn),
                    int128(tokenOut),
                    minSourceTokenAmount,
                    1
                );
            } else {
                revert("Unsupported Signature");
            }
            if (receiverAddress != address(this)) {
                IERC20(destTokenAddress).safeTransfer(receiverAddress, recv);
            }
            sourceTokenAmountUsed = minSourceTokenAmount;
            destTokenAmountReceived = recv;
        }
    }
}
