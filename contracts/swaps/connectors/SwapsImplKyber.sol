/**
 * Copyright 2017-2021, bZeroX, LLC <https://bzx.network/>. All Rights Reserved.
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

    address public constant kyberContract = 0x818E6FECD516Ecc3849DAf6845e3EC868087B755; // mainnet
    //address public constant kyberContract = 0x692f391bCc85cefCe8C237C01e1f636BbD70EA4D; // kovan
    //address public constant kyberContract = 0x818E6FECD516Ecc3849DAf6845e3EC868087B755; // ropsten


    function dexSwap(
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
        require(txnData.length != 0, "kyber payload error");

        IERC20 sourceToken = IERC20(sourceTokenAddress);
        address _thisAddress = address(this);

        uint256 sourceBalanceBefore = sourceToken.balanceOf(_thisAddress);

        /* the following code is to allow the Kyber trade to fail silently and not revert if it does, preventing a "bubble up" */
        (bool success, bytes memory returnData) = kyberContract.call(txnData);
        require(success, "kyber swap failed");

        assembly {
            destTokenAmountReceived := mload(add(returnData, 32))
        }
        sourceTokenAmountUsed = sourceBalanceBefore.sub(sourceToken.balanceOf(_thisAddress));

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
        if (sourceTokenAddress == destTokenAddress) {
            expectedRate = WEI_PRECISION;
        } else if (sourceTokenAmount != 0) {
            (bool success, bytes memory data) = kyberContract.staticcall(
                abi.encodeWithSelector(
                    0x809a9e55, // keccak("getExpectedRate(address,address,uint256)")
                    sourceTokenAddress,
                    destTokenAddress,
                    sourceTokenAmount
                )
            );
            assembly {
                if eq(success, 1) {
                    expectedRate := mload(add(data, 32))
                }
            }
        }

        return expectedRate;
    }

    function setSwapApprovals(
        address[] memory tokens)
        public
    {
        for (uint256 i = 0; i < tokens.length; i++) {
            IERC20(tokens[i]).safeApprove(kyberContract, 0);
            IERC20(tokens[i]).safeApprove(kyberContract, uint256(-1));
        }
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
                .add(WEI_PERCENT_PRECISION);

            estimatedSourceAmount = requiredDestTokenAmount
                .mul(sourceToDestPrecision)
                .div(dexExpectedRate(
                    sourceTokenAddress,
                    destTokenAddress,
                    minSourceTokenAmount
                ));
            if (estimatedSourceAmount == 0) {
                return "";
            }

            estimatedSourceAmount = estimatedSourceAmount // buffer yields more source
                .mul(bufferMultiplier)
                .div(WEI_PERCENT_PRECISION);

            if (estimatedSourceAmount > maxSourceTokenAmount) {
                estimatedSourceAmount = maxSourceTokenAmount;
            }
        } else {
            estimatedSourceAmount = minSourceTokenAmount;
        }

        return abi.encodeWithSelector(
            0x29589f61, // keccak("tradeWithHint(address,uint256,address,address,uint256,uint256,address,bytes)")
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
