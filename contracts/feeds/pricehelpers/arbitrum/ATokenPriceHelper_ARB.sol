/**
 * Copyright 2017-2023, OokiDao. All Rights Reserved.
 * Licensed under the Apache License, Version 2.0.
 */

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

import "interfaces/IPriceFeedHelper.sol";
// import "contracts/interfaces/ICToken.sol";
import "@aave-v3-core/interfaces/IAToken.sol";
import "@aave-v3-core/interfaces/IStableDebtToken.sol";
import "@aave-v3-core/interfaces/IPool.sol";

import "contracts/feeds/IPriceFeedsExt.sol";

contract ATokenPriceHelper_ARB is IPriceFeedHelper {
    IAToken private constant aArbDAI = IAToken(0x82E64f49Ed5EC1bC6e43DAD4FC8Af9bb3A2312EE);
    IAToken private constant aArbEURS = IAToken(0x6d80113e533a2C0fe82EaBD35f1875DcEA89Ea97);
    IAToken private constant aArbUSDC = IAToken(0x625E7708f30cA75bfd92586e17077590C60eb4cD);
    IAToken private constant aArbUSDT = IAToken(0x6ab707Aca953eDAeFBc4fD23bA73294241490620);
    IAToken private constant aArbAAVE = IAToken(0xf329e36C7bF6E5E86ce2150875a84Ce77f477375);
    IAToken private constant aArbLINK = IAToken(0x191c10Aa4AF7C30e871E70C95dB0E4eb77237530);
    IAToken private constant aArbWBTC = IAToken(0x078f358208685046a11C85e8ad32895DED33A249);
    IAToken private constant aArbWETH = IAToken(0xe50fA9b3c56FfB159cB0FCA61F5c9D750e8128c8);

    address private constant DAI  = 0xDA10009cBd5D07dd0CeCc66161FC93D7c9000da1;
    address private constant EURS = 0xD22a58f79e9481D1a88e00c343885A588b34b68B;
    address private constant USDC = 0xFF970A61A04b1cA14834A43f5dE4533eBDDB5CC8;
    address private constant USDT = 0xFd086bC7CD5C481DCC9C85ebE478A1C0b69FCbb9;
    address private constant AAVE = 0xba5DdD1f9d7F570dc94a51479a000E3BCE967196;
    address private constant LINK = 0xf97f4df75117a78c1A5a0DBb814Af92458539FB4;
    address private constant WBTC = 0x2f2a2543B76A4166549F7aaB2e75Bef0aefC5B0f;
    address private constant WETH = 0x82aF49447D8a07e3bd95BD0d56f35241523fBab1;

    IPriceFeedsExt private constant DAI_PRICE_FEED = IPriceFeedsExt(0xc5C8E77B397E531B8EC06BFb0048328B30E9eCfB);
    IPriceFeedsExt private constant EURS_PRICE_FEED = IPriceFeedsExt(0xA14d53bC1F1c0F31B4aA3BD109344E5009051a84); //EUR/USD
    IPriceFeedsExt private constant USDC_PRICE_FEED = IPriceFeedsExt(0x50834F3163758fcC1Df9973b6e91f0F0F0434aD3);
    IPriceFeedsExt private constant USDT_PRICE_FEED = IPriceFeedsExt(0x3f3f5dF88dC9F13eac63DF89EC16ef6e7E25DdE7);
    IPriceFeedsExt private constant AAVE_PRICE_FEED = IPriceFeedsExt(0xaD1d5344AaDE45F43E596773Bcc4c423EAbdD034);
    IPriceFeedsExt private constant LINK_PRICE_FEED = IPriceFeedsExt(0x86E53CF1B870786351Da77A57575e79CB55812CB);
    IPriceFeedsExt private constant WBTC_PRICE_FEED = IPriceFeedsExt(0xd0C7101eACbB49F3deCcCc166d238410D6D46d57); // WBTC/USD
    IPriceFeedsExt private constant WETH_PRICE_FEED = IPriceFeedsExt(0x639Fe6ab55C921f74e7fac1ee960C0B6293ba612);

    IPool private constant POOL = IPool(0x794a61358D6845594F94dc1DB02A252b5b4814aD);
    
    uint256 private constant RAYWAD = 1e27;

    function latestAnswer(address token) external view returns (uint256) {
        (IPriceFeedsExt feed, address underlying) = getFeed(token);
        return uint256(feed.latestAnswer()) * POOL.getReserveNormalizedIncome(underlying)/ RAYWAD;
    }

    function getFeed(address token) private pure returns(IPriceFeedsExt feed, address underlying) {
        if (token == address(aArbDAI)) {
            return (DAI_PRICE_FEED, DAI);
        } else if (token == address(aArbEURS)) {
            return (EURS_PRICE_FEED, EURS);
        } else if (token == address(aArbUSDC)) {
            return (USDC_PRICE_FEED, USDC);
        } else if (token == address(aArbUSDT)) {
            return (USDT_PRICE_FEED, USDT);
        } else if (token == address(aArbAAVE)) {
            return (AAVE_PRICE_FEED, AAVE);
        } else if (token == address(aArbLINK)) {
            return (LINK_PRICE_FEED, LINK);
        } else if (token == address(aArbWBTC)) {
            return (WBTC_PRICE_FEED, WBTC);
        } else if (token == address(aArbWETH)) {
            return (WETH_PRICE_FEED, WETH);
        }
    }
}
