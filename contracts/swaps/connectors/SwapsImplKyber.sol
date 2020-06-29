/**
 * Copyright 2017-2020, bZeroX, LLC. All Rights Reserved.
 * Licensed under the Apache License, Version 2.0.
 */

pragma solidity 0.5.17;

import "../../core/State.sol";
import "../../feeds/IPriceFeeds.sol";
import "../../openzeppelin/SafeERC20.sol";
import "../ISwapsImpl.sol";


contract SwapsImplKyber is State, ISwapsImpl {
    using SafeERC20 for IERC20;

    address internal constant feeWallet = 0x13ddAC8d492E463073934E2a101e419481970299;

    //address public constant kyberContract = 0x818E6FECD516Ecc3849DAf6845e3EC868087B755; // mainnet
    address public constant kyberContract = 0x692f391bCc85cefCe8C237C01e1f636BbD70EA4D; // kovan
    //address public constant kyberContract = 0x818E6FECD516Ecc3849DAf6845e3EC868087B755; // ropsten


    function internalSwap(
        address sourceTokenAddress,
        address destTokenAddress,
        address receiverAddress,
        address returnToSenderAddress,
        uint256 minSourceTokenAmount,
        uint256 maxSourceTokenAmount,
        uint256 requiredDestTokenAmount)
        public
        returns (uint256 destTokenAmountReceived, uint256 sourceTokenAmountUsed)
    {
        require(sourceTokenAddress != destTokenAddress, "source == dest");
        require(supportedTokens[sourceTokenAddress] && supportedTokens[destTokenAddress], "invalid tokens");

        bytes memory txnData = _getSwapTxnData(
            sourceTokenAddress,
            destTokenAddress,
            receiverAddress,
            minSourceTokenAmount,
            maxSourceTokenAmount,
            requiredDestTokenAmount
        );

        if (txnData.length != 0) {
            // re-up the Kyber spend approval if needed
            uint256 tempAllowance = IERC20(sourceTokenAddress).allowance(address(this), kyberContract);
            if (tempAllowance < maxSourceTokenAmount) {
                IERC20(sourceTokenAddress).safeApprove(
                    kyberContract,
                    uint256(-1)
                );
            }

            uint256 sourceBalanceBefore = IERC20(sourceTokenAddress).balanceOf(address(this));

            /* the following code is to allow the Kyber trade to fail silently and not revert if it does, preventing a "bubble up" */
            (bool success, bytes memory returnData) = kyberContract.call.gas(gasleft())(txnData);
            require(success, "kyber swap failed");

            assembly {
                destTokenAmountReceived := mload(add(returnData, 32))
            }
            sourceTokenAmountUsed = sourceBalanceBefore.sub(IERC20(sourceTokenAddress).balanceOf(address(this)));

        } else {
            revert("kyber payload error");
        }

        if (returnToSenderAddress != address(this)) {
            if (sourceTokenAmountUsed < maxSourceTokenAmount) {
                // send unused source token back
                IERC20(sourceTokenAddress).safeTransfer(
                    returnToSenderAddress,
                    maxSourceTokenAmount-sourceTokenAmountUsed
                );
            }
        }
    }

    function internalExpectedRate(
        address sourceTokenAddress,
        address destTokenAddress,
        uint256 sourceTokenAmount)
        public
        view
        returns (uint256)
    {
        uint256 expectedRate;
        if (sourceTokenAddress == destTokenAddress) {
            expectedRate = 10**18;
        } else {
            if (sourceTokenAmount != 0) {
                (bool result, bytes memory data) = kyberContract.staticcall(
                    abi.encodeWithSignature(
                        "getExpectedRate(address,address,uint256)",
                        sourceTokenAddress,
                        destTokenAddress,
                        sourceTokenAmount
                    )
                );

                assembly {
                    switch result
                    case 0 {
                        expectedRate := 0
                    }
                    default {
                        expectedRate := mload(add(data, 32))
                    }
                }
            } else {
                expectedRate = 0;
            }
        }

        return expectedRate;
    }

    function _getSwapTxnData(
        address sourceTokenAddress,
        address destTokenAddress,
        address receiverAddress,
        uint256 minSourceTokenAmount,
        uint256 maxSourceTokenAmount,
        uint256 requiredDestTokenAmount)
        internal
        view
        returns (bytes memory)
    {
        uint256 estimatedSourceAmount;
        if (requiredDestTokenAmount != 0) {
            uint256 sourceToDestPrecision = IPriceFeeds(priceFeeds).queryPrecision(
                sourceTokenAddress,
                destTokenAddress
            );
            if (sourceToDestPrecision == 0) {
                return "";
            }

            uint256 bufferMultiplier = sourceBufferPercent
                .add(10**20);

            estimatedSourceAmount = requiredDestTokenAmount
                .mul(sourceToDestPrecision)
                .div(internalExpectedRate(
                    sourceTokenAddress,
                    destTokenAddress,
                    minSourceTokenAmount
                ));
            estimatedSourceAmount = estimatedSourceAmount // buffer yields more source
                .mul(bufferMultiplier)
                .div(10**20);

            if (estimatedSourceAmount == 0) {
                return "";
            }

            if (estimatedSourceAmount > maxSourceTokenAmount) {
                estimatedSourceAmount = maxSourceTokenAmount;
            }
        } else {
            estimatedSourceAmount = minSourceTokenAmount;
        }

        return abi.encodeWithSignature(
            "tradeWithHint(address,uint256,address,address,uint256,uint256,address,bytes)",
            sourceTokenAddress,
            estimatedSourceAmount,
            destTokenAddress,
            receiverAddress,
            requiredDestTokenAmount == 0 || requiredDestTokenAmount > 10**28 ? // maxDestAmount
                10**28 :
                requiredDestTokenAmount,
            0, // minConversionRate
            feeWallet,
            "" // hint
        );
    }
}
