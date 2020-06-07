/**
 * Copyright 2017-2020, bZeroX, LLC. All Rights Reserved.
 * Licensed under the Apache License, Version 2.0.
 */

pragma solidity 0.5.17;

import "../core/State.sol";
import "../openzeppelin/SafeERC20.sol";


contract FeesHelper is State {
    using SafeERC20 for IERC20;

    /*event AffiliateFeePaid(
        address indexed receiver,
        uint256 affiliateFee,
        uint256 totalFee
    );*/

    function _getTradingFee(
        uint256 feeTokenAmount)
        internal
        view
        returns (uint256)
    {
        return feeTokenAmount
            .mul(tradingFeePercent)
            .div(10**20);
    }

    function _getBorrowingFee(
        uint256 feeTokenAmount)
        internal
        view
        returns (uint256)
    {
        return feeTokenAmount
            .mul(borrowingFeePercent)
            .div(10**20);
    }

    function _payTradingFee(
        IERC20 feeToken,
        uint256 tradingFee)
        internal
    {
        /*uint256 retainedFee = _payFee(
            feeToken,
            tradingFee
        );*/
        if (tradingFee != 0) {
            tradingFeeTokens[address(feeToken)] = tradingFeeTokens[address(feeToken)]
                .add(tradingFee);
        }
    }

    function _payBorrowingFee(
        IERC20 feeToken,
        uint256 borrowingFee)
        internal
    {
        /*uint256 retainedFee = _payFee(
            feeToken,
            borrowingFee
        );*/
        if (borrowingFee != 0) {
            borrowingFeeTokens[address(feeToken)] = borrowingFeeTokens[address(feeToken)]
                .add(borrowingFee);
        }
    }

    /*function _payFee(
        IERC20 feeToken,
        uint256 paidFee,
        address affiliateWallet)
        internal
        returns (uint256 retainedFee)
    {
        if (paidFee != 0) {
            retainedFee = paidFee;
            if (affiliateWallet != address(0)) {
                uint256 _affiliateFeePercent = affiliateFeePercent;
                if (_affiliateFeePercent != 0 && _checkWhitelist(affiliateWallet)) {
                    uint256 affiliateFee = retainedFee
                        .mul(_affiliateFeePercent)
                        .div(10**20);

                    if (affiliateFee != 0) {
                        emit AffiliateFeePaid(
                            affiliateWallet,
                            affiliateFee,
                            paidFee
                        );

                        retainedFee = retainedFee
                            .sub(affiliateFee);

                        feeToken.safeTransfer(
                            affiliateWallet,
                            affiliateFee
                        );
                    }
                }
            }
        }
    }

    function _checkWhitelist(
        address affiliateWallet)
        internal
        view
        returns (bool isWhitelisted)
    {
        // keccak256("AffiliateWhitelist")
        bytes32 slot = keccak256(abi.encodePacked(affiliateWallet, uint256(0xcda2fc7eaefa672733be021532baa62a86147ef9434c91b60aa179578a939d72)));
        assembly {
            isWhitelisted := sload(slot)
        }
    }

    function affiliateWhitelist(
        address affiliateWallet,
        bool enabled)
        public
        onlyOwner
    {
        // keccak256("AffiliateWhitelist")
        bytes32 slot = keccak256(abi.encodePacked(affiliateWallet, uint256(0xcda2fc7eaefa672733be021532baa62a86147ef9434c91b60aa179578a939d72)));
        assembly {
            sstore(slot, enabled)
        }
    }*/
}