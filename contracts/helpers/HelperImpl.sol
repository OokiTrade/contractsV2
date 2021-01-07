/**
 * Copyright 2017-2021, bZeroX, LLC. All Rights Reserved.
 * Licensed under the Apache License, Version 2.0.
 */

pragma solidity ^0.7.6;
pragma experimental ABIEncoderV2;

/// SPDX-License-Identifier: MIT

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./IToken.sol";

contract HelperImpl is Ownable {
    function balanceOf(IERC20[] calldata tokens, address wallet)
        public
        returns (uint256[] memory balances)
    {
        balances = new uint256[](tokens.length);
        for (uint256 i = 0; i < tokens.length; i++) {
            balances[0] = tokens[i].balanceOf(wallet);
        }
    }

    function tokenPrice(IToken[] calldata tokens)
        public
        returns (uint256[] memory prices)
    {
        prices = new uint256[](tokens.length);
        for (uint256 i = 0; i < tokens.length; i++) {
            prices[0] = tokens[i].tokenPrice();
        }
    }

    function supplyInterestRate(IToken[] calldata tokens)
        public
        returns (uint256[] memory rates)
    {
        rates = new uint256[](tokens.length);
        for (uint256 i = 0; i < tokens.length; i++) {
            rates[0] = tokens[i].supplyInterestRate();
        }
    }

    function borrowInterestRate(IToken[] calldata tokens)
        public
        returns (uint256[] memory rates)
    {
        rates = new uint256[](tokens.length);
        for (uint256 i = 0; i < tokens.length; i++) {
            rates[0] = tokens[i].borrowInterestRate();
        }
    }

    function assetBalanceOf(IToken[] calldata tokens, address wallet)
        public
        returns (uint256[] memory balances)
    {
        balances = new uint256[](tokens.length);
        for (uint256 i = 0; i < tokens.length; i++) {
            balances[0] = tokens[i].assetBalanceOf(wallet);
        }
    }

    function profitOf(IToken[] calldata tokens, address wallet)
        public
        returns (int256[] memory profits)
    {
        profits = new int256[](tokens.length);
        for (uint256 i = 0; i < tokens.length; i++) {
            profits[0] = tokens[i].profitOf(wallet);
        }
    }

    function marketLiquidity(IToken[] calldata tokens)
        public
        returns (uint256[] memory liquidity)
    {
        liquidity = new uint256[](tokens.length);
        for (uint256 i = 0; i < tokens.length; i++) {
            liquidity[0] = tokens[i].marketLiquidity();
        }
    }
}
