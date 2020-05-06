/**
 * Copyright 2017-2020, bZeroX, LLC. All Rights Reserved.
 * Licensed under the Apache License, Version 2.0.
 */

pragma solidity 0.5.17;

import "../core/State.sol";
import "../mixins/VaultController.sol";
import "../feeds/IPriceFeeds.sol";
import "./SwapsEvents.sol";
import "./ISwapsImpl.sol";


contract SwapsUser is State, VaultController, SwapsEvents {

    function _loanSwap(
        address user,
        address sourceToken,
        address destToken,
        uint256 sourceTokenAmount,
        uint256 requiredDestTokenAmount,
        uint256 minConversionRate,
        bool /*isLiquidation*/,
        bytes memory loanDataBytes)
        internal
        returns (uint256 destTokenAmountReceived, uint256 sourceTokenAmountUsed)
    {
        (destTokenAmountReceived, sourceTokenAmountUsed) = _swapsCall(
            sourceToken,
            destToken,
            address(this), // receiver
            address(this), // returnToSender
            sourceTokenAmount,
            requiredDestTokenAmount,
            0, // minConversionRate,
            loanDataBytes
        );


/*
    if (maxDestTokenAmount < 10**28) {
        _checkSwapSize(destTokenAddress, maxDestTokenAmount);
    } else {
        _checkSwapSize(sourceTokenAddress, estimatedSourceAmount);
    }
function _checkSwapSize(
    address tokenAddress,
    uint256 amount)
    internal
    view
{
    uint256 amountInEth;
    if (tokenAddress == address(wethToken)) {
        amountInEth = amount;
    } else {
        (uint toEthRate,) = _querySaneRate(
            tokenAddress,
            address(wethToken)
        );
        amountInEth = amount
            .mul(toEthRate)
            .div(_getDecimalPrecision(tokenAddress, address(wethToken)));
    }
    require(amountInEth <= maxSwapSize, "trade too large");
}
*/
        // will revert if disagreement found
        IPriceFeeds(priceFeeds).checkPriceDisagreement(
            sourceToken,
            destToken,
            sourceTokenAmountUsed,
            destTokenAmountReceived,
            maxDisagreement
        );

        emit Swap(
            user,
            sourceToken,
            destToken,
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
}
