/**
 * Copyright 2017-2020, bZeroX, LLC. All Rights Reserved.
 * Licensed under the Apache License, Version 2.0.
 */

pragma solidity 0.5.17;

import "../core/State.sol";
import "../feeds/IPriceFeeds.sol";
import "../events/SwapsEvents.sol";
import "../mixins/FeesHelper.sol";
import "./ISwapsImpl.sol";


contract SwapsUser is State, SwapsEvents, FeesHelper {

    function _loanSwap(
        bytes32 loanId,
        address sourceToken,
        address destToken,
        address user,
        uint256 minSourceTokenAmount,
        uint256 maxSourceTokenAmount,
        uint256 requiredDestTokenAmount,
        bool bypassFee,
        bytes memory loanDataBytes)
        internal
        returns (uint256 destTokenAmountReceived, uint256 sourceTokenAmountUsed)
    {
        (destTokenAmountReceived, sourceTokenAmountUsed) = _swapsCall(
            sourceToken,
            destToken,
            address(this), // receiver
            address(this), // returnToSender
            minSourceTokenAmount,
            maxSourceTokenAmount,
            requiredDestTokenAmount,
            bypassFee,
            loanDataBytes
        );

        // will revert if swap size too large
        _checkSwapSize(sourceToken, sourceTokenAmountUsed);

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
        uint256 minSourceTokenAmount,
        uint256 maxSourceTokenAmount,
        uint256 requiredDestTokenAmount,
        bool miscBool, // bypassFee
        bytes memory loanDataBytes)
        internal
        returns (uint256, uint256)
    {
        require(minSourceTokenAmount != 0, "sourceAmount == 0");

        if (maxSourceTokenAmount == 0) {
            maxSourceTokenAmount = minSourceTokenAmount;
        }
        require(minSourceTokenAmount <= maxSourceTokenAmount, "sourceAmount larger than max");

        uint256 destTokenAmountReceived;
        uint256 sourceTokenAmountUsed;

        uint256 tradingFee;
        if (!miscBool) { // bypassFee
            if (requiredDestTokenAmount == 0) {
                // condition: minSourceTokenAmount will always used as sourceAmount

                tradingFee = _getTradingFee(minSourceTokenAmount);
                if (tradingFee != 0) {
                    _payTradingFee(
                        IERC20(sourceToken),
                        tradingFee
                    );

                    minSourceTokenAmount = minSourceTokenAmount
                        .sub(tradingFee);
                }
            } else {
                // condition: unknown sourceAmount will be used

                tradingFee = _getTradingFee(requiredDestTokenAmount);

                if (tradingFee != 0) {
                    requiredDestTokenAmount = requiredDestTokenAmount
                        .add(tradingFee);
                }
            }
        }

        if (loanDataBytes.length == 0) {
            bytes memory data = abi.encodeWithSelector(
                ISwapsImpl(swapsImpl).internalSwap.selector,
                sourceToken,
                destToken,
                receiver, // receiverAddress
                returnToSender, // returnToSenderAddress
                minSourceTokenAmount,
                maxSourceTokenAmount,
                requiredDestTokenAmount
            );

            // reclaiming miscBool to avoid stack too deep error
            (miscBool, data) = swapsImpl.delegatecall(data);
            require(miscBool, "swap failed");
            assembly {
                destTokenAmountReceived := mload(add(data, 32))
                sourceTokenAmountUsed := mload(add(data, 64))
            }
        } else {
            /*
            //keccak256("Swaps_SwapsImplZeroX")
            address swapsImplZeroX;
            assembly {
                swapsImplZeroX := sload(0x129a6cb350d136ca8d0881f83a9141afd5dc8b3c99057f06df01ab75943df952)
            }
            */
            //revert(string(loanDataBytes));
            /*
            vaultWithdraw(
                sourceToken,
                address(zeroXConnector),
                sourceTokenAmount
            );
            (destTokenAmountReceived, sourceTokenAmountUsed) = zeroXConnector.swap.value(msg.value)(
                sourceToken,
                destToken,
                receiver,
                sourceTokenAmount,
                0,
                loanDataBytes
            );
            */
        }

        if (requiredDestTokenAmount == 0) {
            // there's no minimum destTokenAmount, but all of minSourceTokenAmount must be spent
            require(sourceTokenAmountUsed == minSourceTokenAmount, "swap too large to fill");

            if (tradingFee != 0) {
                sourceTokenAmountUsed = sourceTokenAmountUsed
                    .add(tradingFee);
            }
        } else {
            // there's a minimum destTokenAmount required, but sourceTokenAmountUsed won't be greater than maxSourceTokenAmount
            require(sourceTokenAmountUsed <= maxSourceTokenAmount, "swap fill too large");
            require(destTokenAmountReceived >= requiredDestTokenAmount, "insufficient swap liquidity");

            if (tradingFee != 0) {
                _payTradingFee(
                    IERC20(destToken),
                    tradingFee
                );

                destTokenAmountReceived = destTokenAmountReceived
                    .sub(tradingFee);
            }
        }

        return (destTokenAmountReceived, sourceTokenAmountUsed);
    }

    function _swapsExpectedReturn(
        address sourceToken,
        address destToken,
        uint256 sourceTokenAmount)
        internal
        view
        returns (uint256)
    {
        uint256 tradingFee = _getTradingFee(sourceTokenAmount);
        if (tradingFee != 0) {
            sourceTokenAmount = sourceTokenAmount
                .sub(tradingFee);
        }

        uint256 sourceToDestRate = ISwapsImpl(swapsImpl).internalExpectedRate(
            sourceToken,
            destToken,
            sourceTokenAmount
        );
        uint256 sourceToDestPrecision = IPriceFeeds(priceFeeds).queryPrecision(
            sourceToken,
            destToken
        );

        return sourceTokenAmount
            .mul(sourceToDestRate)
            .div(sourceToDestPrecision);
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
