/**
 * Copyright 2017-2020, bZeroX, LLC. All Rights Reserved.
 * Licensed under the Apache License, Version 2.0.
 */

pragma solidity 0.5.17;
pragma experimental ABIEncoderV2;

import "../core/State.sol";
import "../mixins/VaultController.sol";
import "../swaps/SwapsUser.sol";
import "../swaps/ISwapsImpl.sol";


contract SwapsExternal is State, VaultController, SwapsUser {

    constructor() public {}

    function()
        external
    {
        revert("fallback not allowed");
    }

    function initialize(
        address target)
        external
        onlyOwner
    {
        _setTarget(this.swapExternal.selector, target);
        _setTarget(this.setSupportedSwapTokensBatch.selector, target);
        _setTarget(this.getExpectedSwapRate.selector, target);
    }

    // TODO: add support for ether source
    function swapExternal(
        address sourceToken,
        address destToken,
        address receiver,
        address returnToSender,
        uint256 sourceTokenAmount,
        uint256 requiredDestTokenAmount,
        uint256 minConversionRate,
        bytes calldata swapData)
        external
        returns (uint256 destTokenAmountReceived, uint256 sourceTokenAmountUsed)
    {
        IERC20(sourceToken).safeTransferFrom(
            msg.sender,
            address(this),
            sourceTokenAmount
        );

        if (destToken == address(0)) {
            destToken = address(0x00eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee); // Kyber ETH designation
        }

        (destTokenAmountReceived, sourceTokenAmountUsed) = _swapsCall(
            sourceToken,
            destToken,
            receiver,
            returnToSender,
            sourceTokenAmount,
            requiredDestTokenAmount,
            minConversionRate,
            swapData
        );

        emit ExternalSwap(
            msg.sender, // user
            sourceToken,
            destToken,
            sourceTokenAmountUsed,
            destTokenAmountReceived
        );
    }

    function setSupportedSwapTokensBatch(
        address[] calldata tokens,
        bool[] calldata toggles)
        external
        onlyOwner
    {
        require(tokens.length == toggles.length, "count mismatch");

        for (uint256 i = 0; i < tokens.length; i++) {
            supportedTokens[tokens[i]] = toggles[i];
        }
    }

    function getExpectedSwapRate(
        address sourceTokenAddress,
        address destTokenAddress,
        uint256 sourceTokenAmount)
        external
        view
        returns (uint256)
    {
        uint256 expectedRate;
        (bool success, bytes memory returnData) = swapsImpl.staticcall(
            abi.encodeWithSelector(
                ISwapsImpl(swapsImpl).internalExpectedRate.selector,
                sourceTokenAddress,
                destTokenAddress,
                sourceTokenAmount
            )
        );
        require(success, "rate call failed");
        assembly {
            expectedRate := mload(add(returnData, 32))
        }
        return expectedRate;
    }
}