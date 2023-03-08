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



contract UniV2PriceFeedHelper_ETH {

    address private constant DAI = 0x6B175474E89094C44Da98b954EedeAC495271d0F;
    address private constant WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    address private constant USDC = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
    address private constant WBTC = 0x2260FAC5E5542a773Aa44fBCfeDf7C193bc2C599;
    address private constant MKR = 0x9f8F72aA9304c8B593d555F12eF6589cC3A579A2;
    address private constant LINK = 0x514910771AF9Ca656af840dff83E8264EcF986CA;
    address private constant YFI = 0x0bc529c00C6401aEF6D220BE8C6Ea1667F6Ad93e;
    address private constant USDT = 0xdAC17F958D2ee523a2206206994597C13D831ec7;
    address private constant AAVE = 0x7Fc66500c84A76Ad7e9c93437bFc5Ac33E2DDaE9;
    address private constant UNI = 0x1f9840a85d5aF5bf1D1762F925BDADdC4201F984;
    address private constant COMP = 0xc00e94Cb662C3520282E6f5717214004A7f26888;
    address private constant OOKI = 0x0De05F6447ab4D22c8827449EE4bA2D5C288379B;
    address private constant APE = 0x4d224452801ACEd8B2F0aebE155379bb5D594381;

    IPriceFeedsExt private constant DAI_PRICE_FEED = IPriceFeedsExt(0x773616E4d11A78F511299002da57A0a94577F1f4);
    IPriceFeedsExt private constant WETH_PRICE_FEED = IPriceFeedsExt(0x4B22d75DD2b8e0A2787B0bf93636990d8ba12C65);
    IPriceFeedsExt private constant USDC_PRICE_FEED = IPriceFeedsExt(0x986b5E1e1755e3C2440e960477f25201B0a8bbD4); // this is form DollarPeggedFeed
    IPriceFeedsExt private constant WBTC_PRICE_FEED = IPriceFeedsExt(0xdeb288F737066589598e9214E782fa5A8eD689e8);
    IPriceFeedsExt private constant MKR_PRICE_FEED = IPriceFeedsExt(0x24551a8Fb2A7211A25a17B1481f043A8a8adC7f2);
    IPriceFeedsExt private constant LINK_PRICE_FEED = IPriceFeedsExt(0xDC530D9457755926550b59e8ECcdaE7624181557);
    IPriceFeedsExt private constant YFI_PRICE_FEED = IPriceFeedsExt(0x7c5d4F8345e66f68099581Db340cd65B078C41f4);
    IPriceFeedsExt private constant USDT_PRICE_FEED = IPriceFeedsExt(0xEe9F2375b4bdF6387aa8265dD4FB8F16512A1d46); // this is form DollarPeggedFeed
    IPriceFeedsExt private constant AAVE_PRICE_FEED = IPriceFeedsExt(0x6Df09E975c830ECae5bd4eD9d90f3A95a4f88012);
    IPriceFeedsExt private constant UNI_PRICE_FEED = IPriceFeedsExt(0xD6aA3D25116d8dA79Ea0246c4826EB951872e02e);
    IPriceFeedsExt private constant COMP_PRICE_FEED = IPriceFeedsExt(0x1B39Ee86Ec5979ba5C322b826B3ECb8C79991699);
    IPriceFeedsExt private constant OOKI_PRICE_FEED = IPriceFeedsExt(0xd219325Cf1c4FA17E5984feA5911d0Ba0CaE60F9);
    IPriceFeedsExt private constant APE_PRICE_FEED = IPriceFeedsExt(0xc7de7f4d4C9c991fF62a07D18b3E31e349833A18);

    // event Logger(string name, uint256 value);
    function latestAnswer(address token) public view returns (uint256 answer) {
        // check token validity
        address token0 = IUniswapV2Pair(token).token0();
        address token1 = IUniswapV2Pair(token).token1();

        IPriceFeedsExt feed0 = getFeed(token0);
        IPriceFeedsExt feed1 = getFeed(token1);
        require(address(feed0) != address(0) && address(feed1) != address(0), "wrong lp");

        (uint256 reserve0, uint256 reserve1,) = IUniswapV2Pair(token).getReserves();

        uint256 reserve0_to_eth = reserve0 * uint256(feed0.latestAnswer()) / 10**(IERC20Metadata(token0).decimals());
        uint256 reserve1_to_eth = reserve1 * uint256(feed1.latestAnswer()) / 10**(IERC20Metadata(token1).decimals());

        answer = (reserve0_to_eth + reserve1_to_eth) * 1e18/ IUniswapV2Pair(token).totalSupply();

    }

    function getFeed(address token) public pure returns(IPriceFeedsExt feed) {
        
        if (token == address(DAI)) {
            feed = DAI_PRICE_FEED;
        } else if (token == address(WETH)) {
            feed = WETH_PRICE_FEED;
        } else if (token == address(USDC)) {
            feed = USDC_PRICE_FEED;
        } else if (token == address(WBTC)) {
            feed = WBTC_PRICE_FEED;
        } else if (token == address(USDT)) {
            feed = USDT_PRICE_FEED;
        } else if (token == address(MKR)) {
            feed = MKR_PRICE_FEED;
        } else if (token == address(LINK)) {
            feed = LINK_PRICE_FEED;
        } else if (token == address(YFI)) {
            feed = YFI_PRICE_FEED;
        } else if (token == address(AAVE)) {
            feed = AAVE_PRICE_FEED;
        } else if (token == address(UNI)) {
            feed = UNI_PRICE_FEED;
        } else if (token == address(COMP)) {
            feed = COMP_PRICE_FEED;
        } else if (token == address(OOKI)) {
            feed = OOKI_PRICE_FEED;
        } else if (token == address(APE)) {
            feed = APE_PRICE_FEED;
        }
    }
}
