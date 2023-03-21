/**
 * Copyright 2017-2023, OokiDao. All Rights Reserved.
 * Licensed under the Apache License, Version 2.0.
 */

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

import "contracts/feeds/IPriceFeedsExt.sol";
import "interfaces/IPriceFeedHelper.sol";
import "contracts/interfaces/uniswap/IUniswapV2Pair.sol";
import "@openzeppelin-4.8.0/token/ERC20/extensions/IERC20Metadata.sol";



contract SushiV2PriceFeedHelper_ETH {

    address private constant DAI  = 0xDA10009cBd5D07dd0CeCc66161FC93D7c9000da1;
    address private constant ERUS = 0xD22a58f79e9481D1a88e00c343885A588b34b68B;
    address private constant USDC = 0xFF970A61A04b1cA14834A43f5dE4533eBDDB5CC8;
    address private constant USDT = 0xFd086bC7CD5C481DCC9C85ebE478A1C0b69FCbb9;
    address private constant AAVE = 0xba5DdD1f9d7F570dc94a51479a000E3BCE967196;
    address private constant LINK = 0xf97f4df75117a78c1A5a0DBb814Af92458539FB4;
    address private constant WBTC = 0x2f2a2543B76A4166549F7aaB2e75Bef0aefC5B0f;
    address private constant WETH = 0x82aF49447D8a07e3bd95BD0d56f35241523fBab1;

    IPriceFeedsExt private constant DAI_PRICE_FEED = IPriceFeedsExt(0xc5C8E77B397E531B8EC06BFb0048328B30E9eCfB);
    IPriceFeedsExt private constant ERUS_PRICE_FEED = IPriceFeedsExt(0xA14d53bC1F1c0F31B4aA3BD109344E5009051a84); //EUR/USD
    IPriceFeedsExt private constant USDC_PRICE_FEED = IPriceFeedsExt(0x50834F3163758fcC1Df9973b6e91f0F0F0434aD3);
    IPriceFeedsExt private constant USDT_PRICE_FEED = IPriceFeedsExt(0x3f3f5dF88dC9F13eac63DF89EC16ef6e7E25DdE7);
    IPriceFeedsExt private constant AAVE_PRICE_FEED = IPriceFeedsExt(0xaD1d5344AaDE45F43E596773Bcc4c423EAbdD034);
    IPriceFeedsExt private constant LINK_PRICE_FEED = IPriceFeedsExt(0x86E53CF1B870786351Da77A57575e79CB55812CB);
    IPriceFeedsExt private constant WBTC_PRICE_FEED = IPriceFeedsExt(0xd0C7101eACbB49F3deCcCc166d238410D6D46d57); // WBTC/USD
    IPriceFeedsExt private constant WETH_PRICE_FEED = IPriceFeedsExt(0x639Fe6ab55C921f74e7fac1ee960C0B6293ba612);

    function latestAnswer(address token) public view returns (uint256 answer) {
        // TODO check token validity
        address token0 = IUniswapV2Pair(token).token0();
        address token1 = IUniswapV2Pair(token).token1();

        IPriceFeedsExt feed0 = getFeed(token0);
        IPriceFeedsExt feed1 = getFeed(token1);
        require(address(feed0) != address(0) && address(feed1) != address(0), "wrong lp");

        (uint256 reserve0, uint256 reserve1,) = IUniswapV2Pair(token).getReserves();
        

        // TODO optimize for extra call decimals
        uint256 reserve0_to_eth = reserve0 * uint256(feed0.latestAnswer()) / 10**(IERC20Metadata(token0).decimals());
        uint256 reserve1_to_eth = reserve1 * uint256(feed1.latestAnswer()) / 10**(IERC20Metadata(token1).decimals());

        answer = (reserve0_to_eth + reserve1_to_eth) * 1e18/ IUniswapV2Pair(token).totalSupply();

    }

    function getFeed(address token) public pure returns(IPriceFeedsExt feed) {
        
        if (token == address(DAI)) {
            feed = DAI_PRICE_FEED;
        } else if (token == address(ERUS)) {
            feed = ERUS_PRICE_FEED;
        } else if (token == address(USDC)) {
            feed = USDC_PRICE_FEED;
        } else if (token == address(USDT)) {
            feed = USDT_PRICE_FEED;
        } else if (token == address(AAVE)) {
            feed = AAVE_PRICE_FEED;
        } else if (token == address(LINK)) {
            feed = LINK_PRICE_FEED;
        } else if (token == address(WBTC)) {
            feed = WBTC_PRICE_FEED;
        } else if (token == address(WETH)) {
            feed = WETH_PRICE_FEED;
        }
    }
}
