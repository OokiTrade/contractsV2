/**
 * Copyright 2017-2023, OokiDao. All Rights Reserved.
 * Licensed under the Apache License, Version 2.0.
 */

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

import "contracts/feeds/IPriceFeedsExt.sol";
import "interfaces/IPriceFeedHelper.sol";
import "interfaces/IToken.sol";

contract ITokenPriceFeedHelperV2_ARB is IPriceFeedHelper {

    IToken private constant IFRAX = IToken(0xC3f6816C860e7d7893508C8F8568d5AF190f6d7d);
    IToken private constant IUSDC = IToken(0xEDa7f294844808B7C93EE524F990cA7792AC2aBd);
    IToken private constant IUSDT = IToken(0xd103a2D544fC02481795b0B33eb21DE430f3eD23);
    IToken private constant ILINK = IToken(0x76F3Fca193Aa9aD86347F70D82F013c19060D22C);
    IToken private constant IWETH = IToken(0xE602d108BCFbB7f8281Fd0835c3CF96e5c9B5486);
    IToken private constant IWBTC = IToken(0x4eBD7e71aFA27506EfA4a4783DFbFb0aD091701e);
     
    IPriceFeedsExt private constant FRAX_PRICE_FEED = IPriceFeedsExt(0x0809E3d38d1B4214958faf06D8b1B1a2b73f2ab8);
    IPriceFeedsExt private constant USDC_PRICE_FEED = IPriceFeedsExt(0x50834F3163758fcC1Df9973b6e91f0F0F0434aD3);
    IPriceFeedsExt private constant USDT_PRICE_FEED = IPriceFeedsExt(0x3f3f5dF88dC9F13eac63DF89EC16ef6e7E25DdE7);
    IPriceFeedsExt private constant LINK_PRICE_FEED = IPriceFeedsExt(0x86E53CF1B870786351Da77A57575e79CB55812CB);
    IPriceFeedsExt private constant WETH_PRICE_FEED = IPriceFeedsExt(0x639Fe6ab55C921f74e7fac1ee960C0B6293ba612);
    IPriceFeedsExt private constant WBTC_PRICE_FEED = IPriceFeedsExt(0x6ce185860a4963106506C203335A2910413708e9);
    
    function latestAnswer(address token) public view returns (uint256) {
        return (uint256(getFeed(token).latestAnswer()) * IToken(token).tokenPrice()) / 1e18;
    }

    function getFeed(address token) private pure returns(IPriceFeedsExt feed) {
        if (token == address(IFRAX)) {
            feed = FRAX_PRICE_FEED;
        } else if (token == address(IUSDC)) {
            feed = USDC_PRICE_FEED;
        } else if (token == address(IUSDT)) {
            feed = USDT_PRICE_FEED;
        } else if (token == address(ILINK)) {
            feed = LINK_PRICE_FEED;
        } else if (token == address(IWETH)) {
            feed = WETH_PRICE_FEED;
        } else if (token == address(IWBTC)) {
            feed = WBTC_PRICE_FEED;
        }
    }
}
