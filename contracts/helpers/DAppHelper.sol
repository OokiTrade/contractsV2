/**
 * Copyright 2017-2022, OokiDao. All Rights Reserved.
 * Licensed under the Apache License, Version 2.0.
 */

pragma solidity >=0.6.0 <0.8.4;
pragma experimental ABIEncoderV2;
import "../../interfaces/IBZx.sol";
import "../../interfaces/IPriceFeeds.sol";
import "../../interfaces/IToken.sol";

// this contract is deprecated use HelperImpl
contract DAppHelper {

    //address public constant bZxProtocol = 0xD8Ee69652E4e4838f2531732a46d1f7F584F0b7f; // mainnet
    //address public constant bZxProtocol = 0x5cfba2639a3db0D9Cc264Aa27B2E6d134EeA486a; // kovan
    //address public constant bZxProtocol = 0xD154eE4982b83a87b0649E5a7DDA1514812aFE1f; // bsc
    //address public constant bZxProtocol = 0x059D60a9CEfBc70b9Ea9FFBb9a041581B1dFA6a8; // polygon
    address public constant bZxProtocol = 0x37407F3178ffE07a6cF5C847F8f680FEcf319FAB; // arbitrum

    function assetRates(
        address usdTokenAddress,
        address[] memory tokens,
        uint256[] memory sourceAmounts)
        public
        view
        returns (
            uint256[] memory rates,
            uint256[] memory precisions,
            uint256[] memory destAmounts
        )
    {
        IPriceFeeds feeds = IPriceFeeds(IBZx(bZxProtocol).priceFeeds());
        rates = new uint256[](tokens.length);
        precisions = new uint256[](tokens.length);
        destAmounts = new uint256[](tokens.length);

        for (uint256 i=0; i < tokens.length; i++) {
            (rates[i], precisions[i]) = feeds.queryRate(
                tokens[i],
                usdTokenAddress
            );

            if (sourceAmounts[i] != 0) {
                destAmounts[i] = sourceAmounts[i] * rates[i];
                require(destAmounts[i] / sourceAmounts[i] == rates[i], "overflow");
                destAmounts[i] = destAmounts[i] / precisions[i];
            }
        }
    }

    function reserveDetails(
        address[] memory tokenAddresses)
        public
        view
        returns (
            uint256[] memory totalAssetSupply,
            uint256[] memory totalAssetBorrow,
            uint256[] memory supplyInterestRate,
            uint256[] memory borrowInterestRate,
            uint256[] memory torqueBorrowInterestRate,
            uint256[] memory vaultBalance
        )
    {
        totalAssetSupply = new uint256[](tokenAddresses.length);
        totalAssetBorrow = new uint256[](tokenAddresses.length);
        supplyInterestRate = new uint256[](tokenAddresses.length);
        borrowInterestRate = new uint256[](tokenAddresses.length);
        torqueBorrowInterestRate = new uint256[](tokenAddresses.length);
        vaultBalance = new uint256[](tokenAddresses.length);

        for (uint256 i=0; i < tokenAddresses.length; i++) {
            IToken token = IToken(tokenAddresses[i]);
            totalAssetSupply[i] = token.totalAssetSupply();
            totalAssetBorrow[i] = token.totalAssetBorrow();
            supplyInterestRate[i] = token.supplyInterestRate();
            borrowInterestRate[i] = token.avgBorrowInterestRate();
            torqueBorrowInterestRate[i] = token.nextBorrowInterestRate(0);

            address loanToken = token.loanTokenAddress();
            vaultBalance[i] = IToken(loanToken).balanceOf(bZxProtocol);
        }
    }
}
