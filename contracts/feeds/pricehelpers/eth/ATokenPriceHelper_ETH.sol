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

contract ATokenPriceHelper_ETH is IPriceFeedHelper {
    IAToken private constant aWETH = IAToken(0x4d5F47FA6A74757f35C14fD3a6Ef8E3C9BC514E8);
    IAToken private constant awstETH = IAToken(0x0B925eD163218f6662a35e0f0371Ac234f9E9371);
    IAToken private constant aWBTC = IAToken(0x5Ee5bf7ae06D1Be5997A1A72006FE6C607eC6DE8);
    IAToken private constant aUSDC = IAToken(0x98C23E9d8f34FEFb1B7BD6a91B7FF122F4e16F5c);
    IAToken private constant aDAI = IAToken(0x018008bfb33d285247A21d44E50697654f754e63);
    IAToken private constant aLINK = IAToken(0x5E8C8A7243651DB1384C0dDfDbE39761E8e7E51a);
    IAToken private constant aAAVE = IAToken(0xA700b4eB416Be35b2911fd5Dee80678ff64fF6C9);

    address private constant WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    address private constant wstETH = 0x7f39C581F595B53c5cb19bD0b3f8dA6c935E2Ca0;
    address private constant WBTC = 0x2260FAC5E5542a773Aa44fBCfeDf7C193bc2C599;
    address private constant USDC = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
    address private constant DAI = 0x6B175474E89094C44Da98b954EedeAC495271d0F;
    address private constant LINK = 0x514910771AF9Ca656af840dff83E8264EcF986CA;
    address private constant AAVE = 0x7Fc66500c84A76Ad7e9c93437bFc5Ac33E2DDaE9;


    IPriceFeedsExt private constant WETH_PRICE_FEED = IPriceFeedsExt(0x4B22d75DD2b8e0A2787B0bf93636990d8ba12C65);
    IPriceFeedsExt private constant wstETH_PRICE_FEED = IPriceFeedsExt(0x64b068a655985B3AF49814fBe65A3b293B3b811C);
    IPriceFeedsExt private constant WBTC_PRICE_FEED = IPriceFeedsExt(0xdeb288F737066589598e9214E782fa5A8eD689e8);
    IPriceFeedsExt private constant USDC_PRICE_FEED = IPriceFeedsExt(0x986b5E1e1755e3C2440e960477f25201B0a8bbD4);
    IPriceFeedsExt private constant DAI_PRICE_FEED = IPriceFeedsExt(0x773616E4d11A78F511299002da57A0a94577F1f4);
    IPriceFeedsExt private constant LINK_PRICE_FEED = IPriceFeedsExt(0xDC530D9457755926550b59e8ECcdaE7624181557);
    IPriceFeedsExt private constant AAVE_PRICE_FEED = IPriceFeedsExt(0x6Df09E975c830ECae5bd4eD9d90f3A95a4f88012);

    IPool private constant POOL = IPool(0x87870Bca3F3fD6335C3F4ce8392D69350B4fA4E2);
    
    uint256 private constant RAYWAD = 1e27;

    function latestAnswer(address token) external view returns (uint256) {
        (IPriceFeedsExt feed, address underlying) = getFeed(token);
        return uint256(feed.latestAnswer()) * POOL.getReserveNormalizedIncome(underlying)/ RAYWAD;
    }

    function getFeed(address token) private pure returns(IPriceFeedsExt feed, address underlying) {
        if (token == address(aWETH)) {
            return (WETH_PRICE_FEED, WETH);
        } else if (token == address(awstETH)) {
            return (wstETH_PRICE_FEED, wstETH);
        } else if (token == address(aWBTC)) {
            return (WBTC_PRICE_FEED, WBTC);
        } else if (token == address(aUSDC)) {
            return (USDC_PRICE_FEED, USDC);
        } else if (token == address(aDAI)) {
            return (DAI_PRICE_FEED, DAI);
        } else if (token == address(aLINK)) {
            return (LINK_PRICE_FEED, LINK);
        } else if (token == address(aAAVE)) {
            return (AAVE_PRICE_FEED, AAVE);
        }
    }
}
