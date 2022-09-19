/**
 * Copyright 2017-2022, OokiDao. All Rights Reserved.
 * Licensed under the Apache License, Version 2.0.
 */

pragma solidity ^0.8.0;

import "../../core/State.sol";
import "../../mixins/VaultController.sol";
import "../../swaps/SwapsUser.sol";
import "../../swaps/ISwapsImpl.sol";
import "../../governance/PausableGuardian_0_8.sol";


contract SwapsExternal is State, VaultController, SwapsUser, PausableGuardian_0_8 {
    using SafeERC20 for IERC20;
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
        bytes memory swapData)
        public
        payable
        nonReentrant
        pausable
        returns (uint256 destTokenAmountReceived, uint256 sourceTokenAmountUsed)
    {
        return _swapExternal(
            sourceToken,
            destToken,
            receiver,
            returnToSender,
            sourceTokenAmount,
            requiredDestTokenAmount,
            swapData
        );
    }

    function _swapExternal(
        address sourceToken,
        address destToken,
        address receiver,
        address returnToSender,
        uint256 sourceTokenAmount,
        uint256 requiredDestTokenAmount,
        bytes memory swapData)
        internal
        returns (uint256 destTokenAmountReceived, uint256 sourceTokenAmountUsed)
    {
        require(sourceTokenAmount != 0, "sourceTokenAmount == 0");

        if (msg.value != 0) {
            if (sourceToken == address(0)) {
                sourceToken = address(wethToken);
            } else {
                require(sourceToken == address(wethToken), "sourceToken mismatch");
            }
            require(msg.value == sourceTokenAmount, "sourceTokenAmount mismatch");
            wethToken.deposit{value:sourceTokenAmount}();
        } else {
            IERC20 sourceTokenContract = IERC20(sourceToken);

            uint256 balanceBefore = sourceTokenContract.balanceOf(address(this));

            sourceTokenContract.safeTransferFrom(
                msg.sender,
                address(this),
                sourceTokenAmount
            );

            // explicit balance check so that we can support deflationary tokens
            sourceTokenAmount = sourceTokenContract.balanceOf(address(this)) - balanceBefore;
        }

        (destTokenAmountReceived, sourceTokenAmountUsed) = _swapsCall(
            [
                sourceToken,
                destToken,
                address(this),
                returnToSender,
                msg.sender // user
            ],
            [
                sourceTokenAmount, // minSourceTokenAmount
                sourceTokenAmount, // maxSourceTokenAmount
                requiredDestTokenAmount
            ],
            0, // loanId (not tied to a specific loan)
            false, // bypassFee
            swapData
        );

        IERC20(destToken).safeTransfer(receiver, destTokenAmountReceived);

        emit ExternalSwap(
            msg.sender, // user
            sourceToken,
            destToken,
            sourceTokenAmountUsed,
            destTokenAmountReceived
        );
    }

    function getSwapExpectedReturn(
        address trader,
        address sourceToken,
        address destToken,
        uint256 tokenAmount,
        bytes calldata payload,
        bool isGetAmountOut)
        external
        returns (uint256)
    {
        return _swapsExpectedReturn(
            trader,
            sourceToken,
            destToken,
            tokenAmount,
            payload,
            isGetAmountOut
        );
    }
}
