/**
 * Copyright 2017-2020, bZeroX, LLC. All Rights Reserved.
 * Licensed under the Apache License, Version 2.0.
 */

pragma solidity 0.5.17;

import "../core/State.sol";
import "../feeds/IPriceFeeds.sol";
import "../events/SwapsEvents.sol";
import "./ISwapsImpl.sol";


contract SwapsUser is State, SwapsEvents {

    function _loanSwap(
        bytes32 loanId,
        address sourceToken,
        address destToken,
        address user,
        uint256 sourceTokenAmount,
        uint256 requiredDestTokenAmount,
        uint256 minConversionRate,
        bool /*isLiquidation*/,
        bytes memory loanDataBytes)
        internal
        returns (uint256 destTokenAmountReceived, uint256 sourceTokenAmountUsed)
    {
        // will revert if swap size too large
        if (requiredDestTokenAmount == 0) {
            _checkSwapSize(sourceToken, sourceTokenAmount);
        } else {
            _checkSwapSize(destToken, requiredDestTokenAmount);
        }

        (destTokenAmountReceived, sourceTokenAmountUsed) = _swapsCall(
            sourceToken,
            destToken,
            address(this), // receiver
            address(this), // returnToSender
            sourceTokenAmount,
            requiredDestTokenAmount,
            minConversionRate,
            loanDataBytes
        );

        // will revert if disagreement found
        IPriceFeeds(priceFeeds).checkPriceDisagreement(
            sourceToken,
            destToken,
            sourceTokenAmountUsed,
            destTokenAmountReceived,
            maxDisagreement
        );

        emit LoanSwap(
            loanId,
            sourceToken,
            destToken,
            user,
            sourceTokenAmountUsed,
            destTokenAmountReceived
        );
    }

    function _swapsCall(
        address sourceToken,
        address destToken,
        address receiver,
        address returnToSender,
        uint256 sourceTokenAmount,
        uint256 requiredDestTokenAmount,
        uint256 minConversionRate,
        bytes memory loanDataBytes)
        internal
        returns (uint256, uint256)
    {
        uint256 destTokenAmountReceived;
        uint256 sourceTokenAmountUsed;

        /*vaultWithdraw(
            sourceToken,
            loanDataBytes.length == 0 ?
                swapsImpl :
                swapsImpl,//address(zeroXConnector),
            sourceTokenAmount
        );*/

        if (loanDataBytes.length == 0) {
            (bool success, bytes memory returnData) = swapsImpl.delegatecall(
                abi.encodeWithSelector(
                    ISwapsImpl(swapsImpl).internalSwap.selector,
                    sourceToken,
                    destToken,
                    receiver, // receiverAddress
                    returnToSender, // returnToSenderAddress
                    sourceTokenAmount,
                    requiredDestTokenAmount,
                    minConversionRate
                )
            );
            require(success, "swap failed");
            assembly {
                destTokenAmountReceived := mload(add(returnData, 32))
                sourceTokenAmountUsed := mload(add(returnData, 64))
            }

            if (requiredDestTokenAmount == 0) {
                // there's no minimum destTokenAmount, but all sourceTokenAmount must be spent
                require(sourceTokenAmountUsed == sourceTokenAmount, "swap too large to fill");
            } else {
                // there's a minimum destTokenAmount required, but not all of the sourceTokenAmount must be spent
                require(destTokenAmountReceived >= requiredDestTokenAmount, "insufficient swap liquidity");
            }
        } else {
            revert(string(loanDataBytes));
            /*(destTokenAmountReceived, sourceTokenAmountUsed) = zeroXConnector.swap.value(msg.value)(
                sourceToken,
                destToken,
                receiver,
                sourceTokenAmount,
                0,
                loanDataBytes
            );*/
        }

        return (destTokenAmountReceived, sourceTokenAmountUsed);
    }

    function _checkSwapSize(
        address tokenAddress,
        uint256 amount)
        internal
        view
    {
        uint256 _maxSwapSize = maxSwapSize;
        if (_maxSwapSize != 0) {
            uint256 amountInEth;
            if (tokenAddress == address(wethToken)) {
                amountInEth = amount;
            } else {
                amountInEth = IPriceFeeds(priceFeeds).amountInEth(tokenAddress, amount);
            }
            require(amountInEth <= _maxSwapSize, "swap too large");
        }
    }
}
