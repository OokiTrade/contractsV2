/**
 * Copyright 2017-2023, OokiDao. All Rights Reserved.
 * Licensed under the Apache License, Version 2.0.
 */

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

import "interfaces/IPriceFeedHelper.sol";
import "@openzeppelin-4.8.0/token/ERC20/IERC20.sol";

import "contracts/feeds/IPriceFeedsExt.sol";

contract Crv3CryptoTokenPriceHelper_ARB {
    address private constant CURVE_USD_BTC_ETH_TOKEN = 0x8e0B8c8BB9db49a46697F3a5Bb8A308e744821D2;
    address private constant CURVE_USD_BTC_ETH_POOL = 0x960ea3e3C7FB317332d990873d354E18d7645590;


    IERC20 private constant USDT = IERC20(0xFd086bC7CD5C481DCC9C85ebE478A1C0b69FCbb9);
    IERC20 private constant WBTC = IERC20(0x2f2a2543B76A4166549F7aaB2e75Bef0aefC5B0f);
    IERC20 private constant WETH = IERC20(0x82aF49447D8a07e3bd95BD0d56f35241523fBab1);

    IPriceFeedsExt private constant USDT_PRICE_FEED = IPriceFeedsExt(0x3f3f5dF88dC9F13eac63DF89EC16ef6e7E25DdE7);
    IPriceFeedsExt private constant WETH_PRICE_FEED = IPriceFeedsExt(0x639Fe6ab55C921f74e7fac1ee960C0B6293ba612);
    IPriceFeedsExt private constant WBTC_PRICE_FEED = IPriceFeedsExt(0x6ce185860a4963106506C203335A2910413708e9);


    function latestAnswer(address token) external view returns (uint256) {
        require(token == CURVE_USD_BTC_ETH_TOKEN, "unsupported");
        uint256 balanceUSDT = USDT.balanceOf(CURVE_USD_BTC_ETH_POOL) * uint256(USDT_PRICE_FEED.latestAnswer()) / 1e8;
        balanceUSDT += WBTC.balanceOf(CURVE_USD_BTC_ETH_POOL) * uint256(WBTC_PRICE_FEED.latestAnswer()) / 1e10;
        balanceUSDT += WETH.balanceOf(CURVE_USD_BTC_ETH_POOL) * uint256(WETH_PRICE_FEED.latestAnswer()) / 1e20;
        return balanceUSDT * 1e18 / IERC20(CURVE_USD_BTC_ETH_TOKEN).totalSupply() ;
    }
}
