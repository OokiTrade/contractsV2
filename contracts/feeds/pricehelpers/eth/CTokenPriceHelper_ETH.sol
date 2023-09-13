/**
 * Copyright 2017-2023, OokiDao. All Rights Reserved.
 * Licensed under the Apache License, Version 2.0.
 */

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

import "interfaces/IPriceFeedHelper.sol";
import "contracts/interfaces/ICToken.sol";
import "contracts/feeds/IPriceFeedsExt.sol";

contract CTokenPriceHelper_ETH is IPriceFeedHelper {
    ICToken private constant cUSDC = ICToken(0x39AA39c021dfbaE8faC545936693aC917d5E7563);
    ICToken private constant cDAI = ICToken(0x5d3a536E4D6DbD6114cc1Ead35777bAB948E3643);
    ICToken private constant cUNI = ICToken(0x35A18000230DA775CAc24873d00Ff85BccdeD550);
    ICToken private constant cETH = ICToken(0x4Ddc2D193948926D02f9B1fE9e1daa0718270ED5);
    ICToken private constant cWBTC = ICToken(0xC11b1268C1A384e55C48c2391d8d480264A3A7F4);
    ICToken private constant cUSDT = ICToken(0xf650C3d88D12dB855b8bf7D11Be6C55A4e07dCC9);
    ICToken private constant cCOMP = ICToken(0x70e36f6BF80a52b3B46b3aF8e106CC0ed743E8e4);


    IPriceFeedsExt private constant USDC_PRICE_FEED = IPriceFeedsExt(0xA2F78ab2355fe2f984D808B5CeE7FD0A93D5270E);
    IPriceFeedsExt private constant DAI_PRICE_FEED = IPriceFeedsExt(0x773616E4d11A78F511299002da57A0a94577F1f4);
    IPriceFeedsExt private constant UNI_PRICE_FEED = IPriceFeedsExt(0xD6aA3D25116d8dA79Ea0246c4826EB951872e02e);
    IPriceFeedsExt private constant ETH_PRICE_FEED = IPriceFeedsExt(0x4B22d75DD2b8e0A2787B0bf93636990d8ba12C65);
    IPriceFeedsExt private constant WBTC_PRICE_FEED = IPriceFeedsExt(0xdeb288F737066589598e9214E782fa5A8eD689e8);
    IPriceFeedsExt private constant USDT_PRICE_FEED = IPriceFeedsExt(0xEe9F2375b4bdF6387aa8265dD4FB8F16512A1d46);
    IPriceFeedsExt private constant COMP_PRICE_FEED = IPriceFeedsExt(0x1B39Ee86Ec5979ba5C322b826B3ECb8C79991699);

    function latestAnswer(address token) external view returns (uint256) {
        if (token == address(cUSDC)) {
            return calculate(cUSDC, 10**(18-6), USDC_PRICE_FEED);
        } else if (token == address(cUSDT)) {
            return calculate(cUSDT, 10**(18-6), USDT_PRICE_FEED);
        } else if (token == address(cWBTC)) {
            return calculate(cWBTC, 10**(18-8), WBTC_PRICE_FEED);
        } else if (token == address(cDAI)) {
            return calculate(cDAI, 1, DAI_PRICE_FEED);
        } else if (token == address(cUNI)) {
            return calculate(cUNI, 1, UNI_PRICE_FEED);
        } else if (token == address(cCOMP)) {
            return calculate(cUNI, 1, COMP_PRICE_FEED);
        } else if (token == address(cETH)) {
            return calculate(cETH, 1, ETH_PRICE_FEED);
        }
        require(false, "unsupported");
    }

    function calculate(ICToken ctoken, uint256 decimals, IPriceFeedsExt priceFeedExt) internal view returns(uint256){
        return ctoken.exchangeRateStored() / decimals * uint256(priceFeedExt.latestAnswer());
    }
}
