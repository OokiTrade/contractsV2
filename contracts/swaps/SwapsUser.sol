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
        returns (uint256 destTokenAmountReceived, uint256 sourceTokenAmountUsed, uint256 sourceToDestSwapRate)
    {
        (destTokenAmountReceived, sourceTokenAmountUsed) = _swapsCall(
            [
                sourceToken,
                destToken,
                address(this), // receiver
                address(this), // returnToSender
                user
            ],
            [
                minSourceTokenAmount,
                maxSourceTokenAmount,
                requiredDestTokenAmount
            ],
            loanId,
            bypassFee,
            loanDataBytes
        );

        // will revert if swap size too large
        _checkSwapSize(sourceToken, sourceTokenAmountUsed);

        // will revert if disagreement found
        sourceToDestSwapRate = IPriceFeeds(priceFeeds).checkPriceDisagreement(
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
        address[5] memory addrs,
        uint256[3] memory vals,
        bytes32 loanId,
        bool miscBool, // bypassFee
        bytes memory loanDataBytes)
        internal
        returns (uint256, uint256)
    {
        //addrs[0]: sourceToken
        //addrs[1]: destToken
        //addrs[2]: receiver
        //addrs[3]: returnToSender
        //addrs[4]: user
        //vals[0]:  minSourceTokenAmount
        //vals[1]:  maxSourceTokenAmount
        //vals[2]:  requiredDestTokenAmount

        require(vals[0] != 0, "sourceAmount == 0");

        if (vals[1] == 0) {
            vals[1] = vals[0];
        }
        require(vals[0] <= vals[1], "sourceAmount larger than max");

        uint256 destTokenAmountReceived;
        uint256 sourceTokenAmountUsed;

        uint256 tradingFee;
        if (!miscBool) { // bypassFee
            if (vals[2] == 0) {
                // condition: vals[0] will always be used as sourceAmount

                tradingFee = _getTradingFee(vals[0]);
                if (tradingFee != 0) {
                    _payTradingFee(
                        addrs[4], // user
                        loanId,
                        addrs[0], // sourceToken
                        tradingFee
                    );

                    vals[0] = vals[0]
                        .sub(tradingFee);
                }
            } else {
                // condition: unknown sourceAmount will be used

                tradingFee = _getTradingFee(vals[2]);

                if (tradingFee != 0) {
                    vals[2] = vals[2]
                        .add(tradingFee);
                }
            }
        }

        if (loanDataBytes.length == 0) {
            (destTokenAmountReceived, sourceTokenAmountUsed) = _swapsCall_internal(
                addrs,
                vals
            );
        } else {
            revert("invalid state");
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
                addrs[0], // sourceToken
                address(zeroXConnector),
                sourceTokenAmount
            );
            (destTokenAmountReceived, sourceTokenAmountUsed) = zeroXConnector.swap.value(msg.value)(
                addrs[0], // sourceToken
                addrs[1], // destToken
                addrs[2], // receiver
                sourceTokenAmount,
                0,
                loanDataBytes
            );
            */
        }

        if (vals[2] == 0) {
            // there's no minimum destTokenAmount, but all of vals[0] (minSourceTokenAmount) must be spent
            require(sourceTokenAmountUsed == vals[0], "swap too large to fill");

            if (tradingFee != 0) {
                sourceTokenAmountUsed = sourceTokenAmountUsed
                    .add(tradingFee);
            }
        } else {
            // there's a minimum destTokenAmount required, but sourceTokenAmountUsed won't be greater than vals[1] (maxSourceTokenAmount)
            require(sourceTokenAmountUsed <= vals[1], "swap fill too large");
            require(destTokenAmountReceived >= vals[2], "insufficient swap liquidity");

            if (tradingFee != 0) {
                _payTradingFee(
                    addrs[4], // user
                    loanId, // loanId,
                    addrs[1], // destToken
                    tradingFee
                );

                destTokenAmountReceived = destTokenAmountReceived
                    .sub(tradingFee);
            }
        }

        return (destTokenAmountReceived, sourceTokenAmountUsed);
    }

    function _swapsCall_internal(
        address[5] memory addrs,
        uint256[3] memory vals)
        internal
        returns (uint256 destTokenAmountReceived, uint256 sourceTokenAmountUsed)
    {
        bytes memory data = abi.encodeWithSelector(
            ISwapsImpl(swapsImpl).internalSwap.selector,
            addrs[0], // sourceToken
            addrs[1], // destToken
            addrs[2], // receiverAddress
            addrs[3], // returnToSenderAddress
            vals[0],  // minSourceTokenAmount
            vals[1],  // maxSourceTokenAmount
            vals[2]   // requiredDestTokenAmount
        );

        bool success;
        (success, data) = swapsImpl.delegatecall(data);
        require(success, "swap failed");

        assembly {
            destTokenAmountReceived := mload(add(data, 32))
            sourceTokenAmountUsed := mload(add(data, 64))
        }
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
