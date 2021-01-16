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
            balances[i] = tokens[i].balanceOf(wallet);
        }
    }

    function totalSupply(IERC20[] calldata tokens)
        public
        returns (uint256[] memory totalSupply)
    {
        totalSupply = new uint256[](tokens.length);
        for (uint256 i = 0; i < tokens.length; i++) {
            totalSupply[i] = tokens[i].totalSupply();
        }
    }

    function allowance(
        IERC20[] calldata tokens,
        address owner,
        address spender
    ) public returns (uint256[] memory allowances) {
        allowances = new uint256[](tokens.length);
        for (uint256 i = 0; i < tokens.length; i++) {
            allowances[i] = tokens[i].allowance(owner, spender);
        }
    }

    function tokenPrice(IToken[] calldata tokens)
        public
        returns (uint256[] memory prices)
    {
        prices = new uint256[](tokens.length);
        for (uint256 i = 0; i < tokens.length; i++) {
            prices[i] = tokens[i].tokenPrice();
        }
    }

    function supplyInterestRate(IToken[] calldata tokens)
        public
        returns (uint256[] memory rates)
    {
        rates = new uint256[](tokens.length);
        for (uint256 i = 0; i < tokens.length; i++) {
            rates[i] = tokens[i].supplyInterestRate();
        }
    }

    function borrowInterestRate(IToken[] calldata tokens)
        public
        returns (uint256[] memory rates)
    {
        rates = new uint256[](tokens.length);
        for (uint256 i = 0; i < tokens.length; i++) {
            rates[i] = tokens[i].borrowInterestRate();
        }
    }

    function assetBalanceOf(IToken[] calldata tokens, address wallet)
        public
        returns (uint256[] memory balances)
    {
        balances = new uint256[](tokens.length);
        for (uint256 i = 0; i < tokens.length; i++) {
            balances[i] = tokens[i].assetBalanceOf(wallet);
        }
    }

    function profitOf(IToken[] calldata tokens, address wallet)
        public
        returns (int256[] memory profits)
    {
        profits = new int256[](tokens.length);
        for (uint256 i = 0; i < tokens.length; i++) {
            profits[i] = tokens[i].profitOf(wallet);
        }
    }

    function marketLiquidity(IToken[] calldata tokens)
        public
        returns (uint256[] memory liquidity)
    {
        liquidity = new uint256[](tokens.length);
        for (uint256 i = 0; i < tokens.length; i++) {
            liquidity[i] = tokens[i].marketLiquidity();
        }
    }
}
