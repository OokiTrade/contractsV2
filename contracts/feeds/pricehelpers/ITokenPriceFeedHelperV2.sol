/**
 * Copyright 2017-2023, OokiDao. All Rights Reserved.
 * Licensed under the Apache License, Version 2.0.
 */

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

import "contracts/feeds/IPriceFeedsExt.sol";
import "interfaces/IPriceFeedHelper.sol";
import "interfaces/IToken.sol";

// iDAI 0x6b093998D36f2C7F0cc359441FBB24CC629D5FF0 0x773616E4d11A78F511299002da57A0a94577F1f4
// iETH 0xB983E01458529665007fF7E0CDdeCDB74B967Eb6 0x4B22d75DD2b8e0A2787B0bf93636990d8ba12C65
// iUSDC 0x32E4c68B3A4a813b710595AebA7f6B7604Ab9c15 0xA9F9F897dD367C416e350c33a92fC12e53e1Cee5
// iWBTC 0x2ffa85f655752fB2aCB210287c60b9ef335f5b6E 0xdeb288F737066589598e9214E782fa5A8eD689e8
// iLRC 0x3dA0e01472Dee3746b4D324a65D7EdFaECa9Aa4f 0x160AC928A16C93eD4895C2De6f81ECcE9a7eB7b4
// iKNC 0x687642347a9282Be8FD809d8309910A3f984Ac5a 0x656c0544eF4C98A6a98491833A89204Abb045d6b
// iMKR 0x9189c499727f88F8eCC7dC4EEA22c828E6AaC015 0x24551a8Fb2A7211A25a17B1481f043A8a8adC7f2
// iBZRX 0x18240BD9C07fA6156Ce3F3f61921cC82b2619157 0x8f7C7181Ed1a2BA41cfC3f5d064eF91b67daef66
// iLINK 0x463538705E7d22aA7f03Ebf8ab09B067e1001B54 0xDC530D9457755926550b59e8ECcdaE7624181557
// iYFI 0x7F3Fe9D492A9a60aEBb06d82cBa23c6F32CAd10b 0x7c5d4F8345e66f68099581Db340cd65B078C41f4
// iUSDT 0x7e9997a38A439b2be7ed9c9C4628391d3e055D48 0xA9F9F897dD367C416e350c33a92fC12e53e1Cee5
// iAAVE 0x0cae8d91E0b1b7Bd00D906E990C3625b2c220db1 0x6Df09E975c830ECae5bd4eD9d90f3A95a4f88012
// iUNI 0x0a625FceC657053Fe2D9FFFdeb1DBb4e412Cf8A8 0xD6aA3D25116d8dA79Ea0246c4826EB951872e02e
// iCOMP 0x6d29903BC2c4318b59B35d97Ab98ab9eC08Ed70D 0x1B39Ee86Ec5979ba5C322b826B3ECb8C79991699
// iOOKI 0x05d5160cbc6714533ef44CEd6dd32112d56Ad7da 0xd219325Cf1c4FA17E5984feA5911d0Ba0CaE60F9
// iAPE 0x5c5d12feD25160942623132325A839eDE3F4f4D9 0xc7de7f4d4C9c991fF62a07D18b3E31e349833A18

contract ITokenPriceFeedHelperV2 is IPriceFeedHelper {

    IToken private constant IDAI = IToken(0x6b093998D36f2C7F0cc359441FBB24CC629D5FF0);
    IToken private constant IETH = IToken(0xB983E01458529665007fF7E0CDdeCDB74B967Eb6);
    IToken private constant IUSDC = IToken(0x32E4c68B3A4a813b710595AebA7f6B7604Ab9c15);
    IToken private constant IWBTC = IToken(0x2ffa85f655752fB2aCB210287c60b9ef335f5b6E);
    IToken private constant IMKR = IToken(0x9189c499727f88F8eCC7dC4EEA22c828E6AaC015);
    IToken private constant ILINK = IToken(0x463538705E7d22aA7f03Ebf8ab09B067e1001B54);
    IToken private constant IYFI = IToken(0x7F3Fe9D492A9a60aEBb06d82cBa23c6F32CAd10b);
    IToken private constant IUSDT = IToken(0x7e9997a38A439b2be7ed9c9C4628391d3e055D48);
    IToken private constant IAAVE = IToken(0x0cae8d91E0b1b7Bd00D906E990C3625b2c220db1);
    IToken private constant IUNI = IToken(0x0a625FceC657053Fe2D9FFFdeb1DBb4e412Cf8A8);
    IToken private constant ICOMP = IToken(0x6d29903BC2c4318b59B35d97Ab98ab9eC08Ed70D);
    IToken private constant IOOKI = IToken(0x05d5160cbc6714533ef44CEd6dd32112d56Ad7da);
    IToken private constant IAPE = IToken(0x5c5d12feD25160942623132325A839eDE3F4f4D9);
 
    IPriceFeedsExt private constant DAI_PRICE_FEED = IPriceFeedsExt(0x773616E4d11A78F511299002da57A0a94577F1f4);
    IPriceFeedsExt private constant ETH_PRICE_FEED = IPriceFeedsExt(0x4B22d75DD2b8e0A2787B0bf93636990d8ba12C65);
    IPriceFeedsExt private constant USDC_PRICE_FEED = IPriceFeedsExt(0xA2F78ab2355fe2f984D808B5CeE7FD0A93D5270E); // this is form DollarPeggedFeed
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

    function latestAnswer(address token) public view returns (uint256) {
        if (token == address(DAI_PRICE_FEED)) {
            return (uint256(DAI_PRICE_FEED.latestAnswer()) * IToken(token).tokenPrice()) / 1e18;
        }
        return (uint256(getFeed(token).latestAnswer()) * IToken(token).tokenPrice()) / 1e18;
    }

    function getFeed(address token) private pure returns(IPriceFeedsExt feed) {
        if (token == address(IDAI)) {
            feed = DAI_PRICE_FEED;
        } else if (token == address(IETH)) {
            feed = ETH_PRICE_FEED;
        } else if (token == address(IUSDC)) {
            feed = USDC_PRICE_FEED;
        } else if (token == address(IWBTC)) {
            feed = WBTC_PRICE_FEED;
        } else if (token == address(IUSDT)) {
            feed = USDT_PRICE_FEED;
        } else if (token == address(IMKR)) {
            feed = MKR_PRICE_FEED;
        } else if (token == address(ILINK)) {
            feed = LINK_PRICE_FEED;
        } else if (token == address(IYFI)) {
            feed = YFI_PRICE_FEED;
        } else if (token == address(IAAVE)) {
            feed = AAVE_PRICE_FEED;
        } else if (token == address(IUNI)) {
            feed = UNI_PRICE_FEED;
        } else if (token == address(ICOMP)) {
            feed = COMP_PRICE_FEED;
        } else if (token == address(IOOKI)) {
            feed = OOKI_PRICE_FEED;
        } else if (token == address(IAPE)) {
            feed = APE_PRICE_FEED;
        }
    }
}
