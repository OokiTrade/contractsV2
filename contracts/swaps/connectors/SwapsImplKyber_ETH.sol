/**
 * Copyright 2017-2021, bZxDao. All Rights Reserved.
 * Licensed under the Apache License, Version 2.0.
 */

pragma solidity 0.5.17;
pragma experimental ABIEncoderV2;

import "../../core/State.sol";
import "../../interfaces/IKyber.sol";
import "../ISwapsImpl.sol";

contract SwapsImplKyber_ETH is State, ISwapsImpl {
    IKyber public constant KYBER_ROUTER =
        IKyber(0x1c87257F5e8609940Bc751a07BB085Bb7f8cDBE6); // Kyber

    struct Params {
        address[] poolPaths;
        IERC20[] tokens;
        uint256 percentage;
        uint256[] results;
    }

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
            returnToSenderAddress != address(this) &&
            sourceTokenAmountUsed < maxSourceTokenAmount
        ) {
            // send unused source token back
            IERC20(sourceTokenAddress).transfer(
                returnToSenderAddress,
                maxSourceTokenAmount - sourceTokenAmountUsed //doesnt over or underflow as sourceTokenAmountUsed is strictly less than maxSourceTokenAmount
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

    function dexAmountOut(bytes memory payload, uint256 amountIn)
        public
        returns (uint256 amountOut, address midToken)
    {
        (address[] memory pools, address[] memory tokensInitial) = abi.decode(
            payload,
            (address[], address[])
        );
        IERC20[] memory tokens = new IERC20[](tokensInitial.length);
        for (uint256 x = 0; x < tokensInitial.length; x++) {
            tokens[x] = IERC20(tokensInitial[x]);
        }
        amountOut = _getAmountOut(amountIn, pools, tokens);
    }

    function dexAmountOutFormatted(bytes memory payload, uint256 amountIn) //TODO: not format compliant, will come in next iteration
        public
        returns (uint256 amountOut, address midToken)
    {
        return dexAmountIn(payload, amountIn);
    }

    function dexAmountIn(bytes memory payload, uint256 amountOut)
        public
        returns (uint256 amountIn, address midToken)
    {
        (address[] memory pools, address[] memory tokensInitial) = abi.decode(
            payload,
            (address[], address[])
        );
        IERC20[] memory tokens = new IERC20[](tokensInitial.length);
        for (uint256 x = 0; x < tokensInitial.length; x++) {
            tokens[x] = IERC20(tokensInitial[x]);
        }
        amountIn = _getAmountIn(amountOut, pools, tokens);
    }

    function dexAmountInFormatted(bytes memory payload, uint256 amountOut) //TODO: not format compliant, will come in next iteration
        public
        returns (uint256 amountIn, address midToken)
    {
        return dexAmountIn(payload, amountOut);
    }

    function _getAmountOut(
        uint256 amountIn,
        address[] memory pools,
        IERC20[] memory tokens
    ) public view returns (uint256 amountOut) {
        return
            KYBER_ROUTER.getAmountsOut(amountIn, pools, tokens)[
                tokens.length - 1
            ];
    }

    function _getAmountIn(
        uint256 amountOut,
        address[] memory pools,
        IERC20[] memory tokens
    ) public view returns (uint256 amountIn) {
        return KYBER_ROUTER.getAmountsOut(amountOut, pools, tokens)[0];
    }

    function setSwapApprovals(address[] memory tokens) public {
        for (uint256 i = 0; i < tokens.length; i++) {
            IERC20(tokens[i]).approve(address(KYBER_ROUTER), 0);
            IERC20(tokens[i]).approve(address(KYBER_ROUTER), uint256(-1));
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
        Params[] memory swaps = abi.decode(payload, (Params[]));
        if (requiredDestTokenAmount != 0) {
            for (uint256 i = 0; i < swaps.length; i++) {
                require(
                    address(swaps[i].tokens[0]) == sourceTokenAddress &&
                        address(swaps[i].tokens[swaps[i].tokens.length - 1]) ==
                        destTokenAddress,
                    "incorrect input/output tokens"
                );
                swaps[i].results = KYBER_ROUTER.swapTokensForExactTokens(
                    requiredDestTokenAmount.mul(swaps[i].percentage).div(100),
                    maxSourceTokenAmount.mul(swaps[i].percentage).div(100),
                    swaps[i].poolPaths,
                    swaps[i].tokens,
                    receiverAddress,
                    block.timestamp
                );
                sourceTokenAmountUsed = swaps[i].results[0].add(
                    sourceTokenAmountUsed
                );
                destTokenAmountReceived = swaps[i]
                    .results[swaps[i].results.length - 1]
                    .add(destTokenAmountReceived);
            }
            if (requiredDestTokenAmount != destTokenAmountReceived) {
                sourceTokenAmountUsed = (
                    KYBER_ROUTER.swapTokensForExactTokens(
                        requiredDestTokenAmount.sub(destTokenAmountReceived),
                        maxSourceTokenAmount.sub(sourceTokenAmountUsed),
                        swaps[0].poolPaths,
                        swaps[0].tokens,
                        receiverAddress,
                        block.timestamp
                    )[0]
                ).add(sourceTokenAmountUsed);
                destTokenAmountReceived = requiredDestTokenAmount;
            }
        } else {
            for (uint256 i = 0; i < swaps.length; i++) {
                require(
                    address(swaps[i].tokens[0]) == sourceTokenAddress &&
                        address(swaps[i].tokens[swaps[i].tokens.length - 1]) ==
                        destTokenAddress,
                    "incorrect input/output tokens"
                );
                swaps[i].results = KYBER_ROUTER.swapExactTokensForTokens(
                    minSourceTokenAmount.mul(swaps[i].percentage).div(100),
                    1,
                    swaps[i].poolPaths,
                    swaps[i].tokens,
                    receiverAddress,
                    block.timestamp
                );
                destTokenAmountReceived = swaps[i]
                    .results[swaps[i].results.length - 1]
                    .add(destTokenAmountReceived);
                sourceTokenAmountUsed = swaps[i].results[0].add(
                    sourceTokenAmountUsed
                );
            }
            if (sourceTokenAmountUsed != minSourceTokenAmount) {
                destTokenAmountReceived = (
                    KYBER_ROUTER.swapExactTokensForTokens(
                        minSourceTokenAmount.sub(sourceTokenAmountUsed),
                        1,
                        swaps[0].poolPaths,
                        swaps[0].tokens,
                        receiverAddress,
                        block.timestamp
                    )[swaps[0].tokens.length - 1]
                ).add(destTokenAmountReceived);
                sourceTokenAmountUsed = minSourceTokenAmount;
            }
        }
    }
}
