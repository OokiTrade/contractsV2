/**
 * Copyright 2017-2022, OokiDao. All Rights Reserved.
 * Licensed under the Apache License, Version 2.0.
 */

pragma solidity 0.5.17;
pragma experimental ABIEncoderV2;

import "../core/State.sol";
import "../../interfaces/IPriceFeeds.sol";
import "../events/SwapsEvents.sol";
import "../mixins/FeesHelper.sol";
import "./ISwapsImpl.sol";
import "../interfaces/IDexRecords.sol";
import "../mixins/Flags.sol";

contract SwapsUser is State, SwapsEvents, FeesHelper, Flags {
    function _loanSwap(
        bytes32 loanId,
        address sourceToken,
        address destToken,
        address user,
        uint256 minSourceTokenAmount,
        uint256 maxSourceTokenAmount,
        uint256 requiredDestTokenAmount,
        bool bypassFee,
        bytes memory loanDataBytes
    )
        internal
        returns (
            uint256 destTokenAmountReceived,
            uint256 sourceTokenAmountUsed,
            uint256 sourceToDestSwapRate
        )
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
        bytes memory loanDataBytes
    ) internal returns (uint256, uint256) {
        //addrs[0]: sourceToken
        //addrs[1]: destToken
        //addrs[2]: receiver
        //addrs[3]: returnToSender
        //addrs[4]: user
        //vals[0]:  minSourceTokenAmount
        //vals[1]:  maxSourceTokenAmount
        //vals[2]:  requiredDestTokenAmount

        require(vals[0] != 0, "sourceAmount == 0");

        uint256 destTokenAmountReceived;
        uint256 sourceTokenAmountUsed;

        uint256 tradingFee;
        if (!miscBool) {
            // bypassFee
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

                    vals[0] = vals[0].sub(tradingFee);
                }
            } else {
                // condition: unknown sourceAmount will be used

                tradingFee = _getTradingFee(vals[2]);

                if (tradingFee != 0) {
                    vals[2] = vals[2].add(tradingFee);
                }
            }
        }

        if (vals[1] == 0) {
            vals[1] = vals[0];
        } else {
            require(vals[0] <= vals[1], "min greater than max");
        }
        if (loanDataBytes.length == 0) {
            (
                destTokenAmountReceived,
                sourceTokenAmountUsed
            ) = _swapsCall_internal(addrs, vals, "");
        } else {
            (uint128 flags, bytes[] memory payload) = abi.decode(
                loanDataBytes,
                (uint128, bytes[])
            );
            if (flags & DEX_SELECTOR_FLAG != 0) {
                (
                    destTokenAmountReceived,
                    sourceTokenAmountUsed
                ) = _swapsCall_internal(addrs, vals, payload[0]);
            } else {
                (
                    destTokenAmountReceived,
                    sourceTokenAmountUsed
                ) = _swapsCall_internal(addrs, vals, "");
            }
        }
        if (vals[2] == 0) {
            // there's no minimum destTokenAmount, but all of vals[0] (minSourceTokenAmount) must be spent, and amount spent can't exceed vals[0]
            require(
                sourceTokenAmountUsed == vals[0],
                "swap too large to fill"
            );

            if (tradingFee != 0) {
                sourceTokenAmountUsed = sourceTokenAmountUsed + tradingFee; // will never overflow
            }
        } else {
            // there's a minimum destTokenAmount required, but sourceTokenAmountUsed won't be greater than vals[1] (maxSourceTokenAmount)
            require(sourceTokenAmountUsed <= vals[1], "swap fill too large");
            require(
                destTokenAmountReceived >= vals[2],
                "insufficient swap liquidity"
            );

            if (tradingFee != 0) {
                _payTradingFee(
                    addrs[4], // user
                    loanId, // loanId,
                    addrs[1], // destToken
                    tradingFee
                );

                destTokenAmountReceived = destTokenAmountReceived - tradingFee; // will never overflow
            }
        }

        return (destTokenAmountReceived, sourceTokenAmountUsed);
    }

    function _swapsCall_internal(
        address[5] memory addrs,
        uint256[3] memory vals,
        bytes memory loanDataBytes
    )
        internal
        returns (uint256 destTokenAmountReceived, uint256 sourceTokenAmountUsed)
    {
        bytes memory data;
        address swapImplAddress;
        bytes memory swapData;
        uint256 dexNumber = 1;
        if (loanDataBytes.length != 0) {
            (dexNumber, swapData) = abi.decode(
                loanDataBytes,
                (uint256, bytes)
            );
        }

        swapImplAddress = IDexRecords(swapsImpl).retrieveDexAddress(
            dexNumber
        );
        
        data = abi.encodeWithSelector(
            ISwapsImpl(swapImplAddress).dexSwap.selector,
            addrs[0], // sourceToken
            addrs[1], // destToken
            addrs[2], // receiverAddress
            addrs[3], // returnToSenderAddress
            vals[0], // minSourceTokenAmount
            vals[1], // maxSourceTokenAmount
            vals[2], // requiredDestTokenAmount
            swapData
        );

        bool success;
        (success, data) = swapImplAddress.delegatecall(data);

        if (!success) {
            assembly {
                let ptr := mload(0x40)
                let size := returndatasize
                returndatacopy(ptr, 0, size)
                revert(ptr, size)
            }
        }
        (destTokenAmountReceived, sourceTokenAmountUsed) = abi.decode(
            data,
            (uint256, uint256)
        );
    }

    function _swapsExpectedReturn(
        address sourceToken,
        address destToken,
        uint256 sourceTokenAmount,
        bytes memory payload
    ) internal returns (uint256 expectedReturn) {
        uint256 tradingFee = _getTradingFee(sourceTokenAmount);
        if (tradingFee != 0) {
            sourceTokenAmount = sourceTokenAmount.sub(tradingFee);
        }
        address swapImplAddress;
        bytes memory dataToSend;
        uint256 dexNumber = 1;
        if (payload.length == 0) {
            dataToSend = abi.encode(sourceToken, destToken);
        } else {
            (uint128 flag, bytes[] memory payloads) = abi.decode(
                payload,
                (uint128, bytes[])
            );
            if(flag & DEX_SELECTOR_FLAG != 0){
                (dexNumber, dataToSend) = abi.decode(payloads[0], (uint256, bytes));
            }
        }

        swapImplAddress = IDexRecords(swapsImpl).retrieveDexAddress(
            dexNumber
        );

        (expectedReturn, ) = ISwapsImpl(swapImplAddress).dexAmountOutFormatted(
            dataToSend,
            sourceTokenAmount
        );
    }

    function _checkSwapSize(address tokenAddress, uint256 amount)
        internal
        view
    {
        uint256 _maxSwapSize = maxSwapSize;
        if (_maxSwapSize != 0) {
            uint256 amountInEth;
            if (tokenAddress == address(wethToken)) {
                amountInEth = amount;
            } else {
                amountInEth = IPriceFeeds(priceFeeds).amountInEth(
                    tokenAddress,
                    amount
                );
            }
            require(amountInEth <= _maxSwapSize, "swap too large");
        }
    }
}
