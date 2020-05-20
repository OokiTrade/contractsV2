/**
 * Copyright 2017-2020, bZeroX, LLC. All Rights Reserved.
 * Licensed under the Apache License, Version 2.0.
 */

pragma solidity 0.5.17;

import "../core/State.sol";
import "../openzeppelin/SafeERC20.sol";
import "./ISwapsImpl.sol";


contract SwapsImplKyber is State, ISwapsImpl {
    using SafeERC20 for IERC20;

    address internal constant feeWallet = 0x13ddAC8d492E463073934E2a101e419481970299;

    // address public constant kyberContract = 0x818E6FECD516Ecc3849DAf6845e3EC868087B755; // mainnet
    address public constant kyberContract = 0x692f391bCc85cefCe8C237C01e1f636BbD70EA4D; // kovan
    // address public constant kyberContract = 0x818E6FECD516Ecc3849DAf6845e3EC868087B755; // ropsten


    function internalSwap(
        address sourceTokenAddress,
        address destTokenAddress,
        address receiverAddress,
        address returnToSenderAddress,
        uint256 sourceTokenAmount,
        uint256 requiredDestTokenAmount,
        uint256 minConversionRate)
        public
        returns (uint256 destTokenAmountReceived, uint256 sourceTokenAmountUsed)
    {
        require(sourceTokenAmount != 0, "sourceAmount == 0");
        require(sourceTokenAddress != destTokenAddress, "source == dest");
        require(supportedTokens[sourceTokenAddress] && supportedTokens[destTokenAddress], "invalid tokens");

        bytes memory txnData = _getSwapTxnData(
            sourceTokenAddress,
            destTokenAddress,
            receiverAddress,
            sourceTokenAmount,
            requiredDestTokenAmount,
            minConversionRate
        );

        if (txnData.length != 0) {
            // re-up the Kyber spend approval if needed
            uint256 tempAllowance = IERC20(sourceTokenAddress).allowance(address(this), kyberContract);
            if (tempAllowance < sourceTokenAmount) {
                if (tempAllowance != 0) {
                    // reset approval to 0
                    IERC20(sourceTokenAddress).safeApprove(
                        kyberContract,
                        0
                    );
                }

                IERC20(sourceTokenAddress).safeApprove(
                    kyberContract,
                    10**28
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
            if (sourceTokenAmountUsed < sourceTokenAmount) {
                // send unused source token back
                IERC20(sourceTokenAddress).safeTransfer(
                    returnToSenderAddress,
                    sourceTokenAmount-sourceTokenAmountUsed
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

        if (sourceTokenAddress == address(0x00eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee)) {
            sourceTokenAddress = address(wethToken);
        }
        if (destTokenAddress == address(0x00eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee)) {
            destTokenAddress = address(wethToken);
        }

        if (sourceTokenAddress == destTokenAddress) {
            expectedRate = 10**18;
        } else {
            if (sourceTokenAmount != 0) {
                require(supportedTokens[sourceTokenAddress] && supportedTokens[destTokenAddress], "invalid tokens");

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
        uint256 sourceTokenAmount,
        uint256 requiredDestTokenAmount,
        uint256 minConversionRate)
        internal
        view
        returns (bytes memory)
    {
        uint256 estimatedSourceAmount;
        if (requiredDestTokenAmount != 0) {
            /*uint256 maxSrcAllowed = maxSourceAmountAllowed[sourceTokenAddress];
            (uint256 slippageRate,) = internalExpectedRate(
                sourceTokenAddress,
                destTokenAddress,
                sourceTokenAmount < maxSrcAllowed || maxSrcAllowed == 0 ?
                    sourceTokenAmount :
                    maxSrcAllowed
            );
            if (slippageRate == 0) {
                return "";
            }

            uint256 sourceToDestPrecision = _getDecimalPrecision(sourceTokenAddress, destTokenAddress);

            maxSourceTokenAmount = requiredDestTokenAmount
                .mul(sourceToDestPrecision)
                .div(slippageRate)
                .mul(11).div(10); // include 1% safety buffer
            if (maxSourceTokenAmount == 0) {
                return "";
            }

            // max can't exceed what we sent in
            if (maxSourceTokenAmount > sourceTokenAmount) {
                maxSourceTokenAmount = sourceTokenAmount;
            }*/

            estimatedSourceAmount = internalExpectedRate(
                destTokenAddress,
                sourceTokenAddress,
                requiredDestTokenAmount.mul(
                    maxNormalSlippagePercent // add slippage amount
                        .add(10**20)
                        .div(10**20)
                )
            );
            if (estimatedSourceAmount == 0) {
                return "";
            }

            // max can't exceed what we sent in
            if (estimatedSourceAmount > sourceTokenAmount) {
                estimatedSourceAmount = sourceTokenAmount;
            }
        } else {
            estimatedSourceAmount = sourceTokenAmount;
        }

        return abi.encodeWithSignature(
            "tradeWithHint(address,uint256,address,address,uint256,uint256,address,bytes)",
            sourceTokenAddress,
            estimatedSourceAmount,
            destTokenAddress,
            receiverAddress,
            requiredDestTokenAmount,
            minConversionRate,
            feeWallet,
            "" // hint
        );
    }
}
