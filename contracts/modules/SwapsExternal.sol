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
        _setTarget(this.getSwapExpectedReturn.selector, target);
    }

    function swapExternal(
        address sourceToken,
        address destToken,
        address receiver,
        address returnToSender,
        uint256 sourceTokenAmount,
        uint256 requiredDestTokenAmount,
        bytes calldata swapData)
        external
        payable
        returns (uint256 destTokenAmountReceived, uint256 sourceTokenAmountUsed)
    {
        require(sourceTokenAmount != 0, "sourceTokenAmount == 0");

        if (msg.value != 0) {
            require(sourceToken == address(0) || sourceToken == address(wethToken), "sourceToken mismatch");
            require(msg.value == sourceTokenAmount, "sourceTokenAmount mismatch");
            wethToken.deposit.value(sourceTokenAmount)();
        } else {
            IERC20(sourceToken).safeTransferFrom(
                msg.sender,
                address(this),
                sourceTokenAmount
            );
        }

        if (destToken == address(0)) {
            destToken = address(0x00eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee); // Kyber ETH designation
        }

        (destTokenAmountReceived, sourceTokenAmountUsed) = _swapsCall(
            sourceToken,
            destToken,
            receiver,
            returnToSender,
            sourceTokenAmount, // minSourceTokenAmount
            sourceTokenAmount, // maxSourceTokenAmount
            requiredDestTokenAmount,
            false, // bypassFee
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

    function getSwapExpectedReturn(
        address sourceToken,
        address destToken,
        uint256 sourceTokenAmount)
        external
        view
        returns (uint256)
    {
        return _swapsExpectedReturn(
            sourceToken,
            destToken,
            sourceTokenAmount
        );
    }
}