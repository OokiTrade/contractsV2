/**
 * Copyright 2017-2023, OokiDao. All Rights Reserved.
 * Licensed under the Apache License, Version 2.0.
 */

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

import "interfaces/IPriceFeedHelper.sol";
import "@openzeppelin-4.8.0/token/ERC20/IERC20.sol";

import "contracts/feeds/IPriceFeedsExt.sol";

contract CrvwstETHCRVTokenPriceHelper_ARB {
    address private constant CURVE_WSTETH_ETH_TOKEN = 0xDbcD16e622c95AcB2650b38eC799f76BFC557a0b;
    address private constant CURVE_WSTETH_ETH_POOL = 0x6eB2dc694eB516B16Dc9FBc678C60052BbdD7d80;


    IERC20 private constant WSTETH = IERC20(0x5979D7b546E38E414F7E9822514be443A4800529);

    IPriceFeedsExt private constant WSTETH_PRICE_FEED = IPriceFeedsExt(0x07C5b924399cc23c24a95c8743DE4006a32b7f2a);
    IPriceFeedsExt private constant WETH_PRICE_FEED = IPriceFeedsExt(0x639Fe6ab55C921f74e7fac1ee960C0B6293ba612);


    function latestAnswer(address token) external view returns (uint256) {
        require(token == CURVE_WSTETH_ETH_TOKEN, "unsupported");
        uint256 balanceUSDT = WSTETH.balanceOf(CURVE_WSTETH_ETH_POOL) * uint256(WSTETH_PRICE_FEED.latestAnswer()) / 1e20;
        balanceUSDT += CURVE_WSTETH_ETH_POOL.balance * uint256(WETH_PRICE_FEED.latestAnswer()) / 1e20;

        // 1e20 = 1e18 + 1e2. 1e2 is to allighn to 8 decimal chainlink like pricefeed
        return balanceUSDT * 1e20 / IERC20(CURVE_WSTETH_ETH_TOKEN).totalSupply() ;
    }
}
