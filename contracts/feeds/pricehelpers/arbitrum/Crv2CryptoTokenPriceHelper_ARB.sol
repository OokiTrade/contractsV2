/**
 * Copyright 2017-2023, OokiDao. All Rights Reserved.
 * Licensed under the Apache License, Version 2.0.
 */

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

import "interfaces/IPriceFeedHelper.sol";
import "@openzeppelin-4.8.0/token/ERC20/IERC20.sol";

import "contracts/feeds/IPriceFeedsExt.sol";

contract Crv2CryptoTokenPriceHelper_ARB {
    address private constant CURVE_USDT_USDC_TOKEN = 0x7f90122BF0700F9E7e1F688fe926940E8839F353;


    IERC20 private constant USDT = IERC20(0xFd086bC7CD5C481DCC9C85ebE478A1C0b69FCbb9);
    IERC20 private constant USDC = IERC20(0xFF970A61A04b1cA14834A43f5dE4533eBDDB5CC8);

    IPriceFeedsExt private constant USDT_PRICE_FEED = IPriceFeedsExt(0x3f3f5dF88dC9F13eac63DF89EC16ef6e7E25DdE7);
    IPriceFeedsExt private constant USDC_PRICE_FEED = IPriceFeedsExt(0x50834F3163758fcC1Df9973b6e91f0F0F0434aD3);

    function latestAnswer(address token) external view returns (uint256) {
        require(token == CURVE_USDT_USDC_TOKEN, "unsupported");
        uint256 balanceUSD = USDT.balanceOf(CURVE_USDT_USDC_TOKEN) * uint256(USDT_PRICE_FEED.latestAnswer()) / 1e8;
        balanceUSD += USDC.balanceOf(CURVE_USDT_USDC_TOKEN) * uint256(USDC_PRICE_FEED.latestAnswer()) / 1e8;
        // 1e20 = 1e18 + 1e2. 1e2 is to allighn to 8 decimal chainlink like pricefeed
        return balanceUSD * 1e20 / IERC20(CURVE_USDT_USDC_TOKEN).totalSupply();
    }
}
