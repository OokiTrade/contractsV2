/**
 * Copyright 2017-2020, bZeroX, LLC. All Rights Reserved.
 * Licensed under the Apache License, Version 2.0.
 */

pragma solidity 0.5.17;
pragma experimental ABIEncoderV2;


contract DAppHelper_TokenLike {
    string public name;
    uint8 public decimals;
    string public symbol;
    function totalSupply() public view returns (uint256);
    function balanceOf(address _who) public view returns (uint256);
    function allowance(address _owner, address _spender) public view returns (uint256);
}

contract DAppHelper_iTokenLike is DAppHelper_TokenLike {
    function loanTokenAddress() public view returns (address);
    function tokenPrice() public view returns (uint256);
    function totalAssetSupplies() public view returns (uint256);
    function totalAssetBorrows() public view returns (uint256);
    function supplyInterestRate() public view returns (uint256);
    function avgBorrowInterestRate() public view returns (uint256);
    function nextBorrowInterestRateWithOption(
        uint256 borrowAmount,
        bool useFixedInterestModel)
        public
        view
        returns (uint256);
}

contract DAppHelper_Protocol {
    function priceFeeds()
        public
        view
        returns (uint256);
}

contract DAppHelper_FeedsLike {
    function queryRate(
        address sourceToken,
        address destToken)
        public
        view
        returns (uint256 rate, uint256 precision);
}

contract DAppHelper {

    //address public constant legacyVault = 0x8B3d70d628Ebd30D4A2ea82DB95bA2e906c71633; // mainnet
    //address public constant legacyVault = 0xcE069b35AE99762BEe444C81DeC1728AA99AFd4B; // kovan
    //address public constant legacyVault = 0xbAB325Bc2E78ea080F46c1A2bf9BF25F8A3c4d69; // ropsten

    address public owner;
    address public bZxProtocol;
    address public legacyVault;

    constructor(
        address _bZxProtocol,
        address _legacyVault)
        public
    {
        owner = msg.sender;
        bZxProtocol = _bZxProtocol;
        legacyVault = _legacyVault;
    }

    function setAddresses(
        address _bZxProtocol,
        address _legacyVault)
        external
    {
        require(msg.sender == owner, "unauthorized");
        bZxProtocol = _bZxProtocol;
        legacyVault = _legacyVault;
    }

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
        DAppHelper_FeedsLike feeds = DAppHelper_FeedsLike(DAppHelper_Protocol(bZxProtocol).priceFeeds());
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
            DAppHelper_iTokenLike token = DAppHelper_iTokenLike(tokenAddresses[i]);
            totalAssetSupply[i] = token.totalAssetSupplies();
            totalAssetBorrow[i] = token.totalAssetBorrows();
            supplyInterestRate[i] = token.supplyInterestRate();
            borrowInterestRate[i] = token.avgBorrowInterestRate();
            torqueBorrowInterestRate[i] = token.nextBorrowInterestRateWithOption(0,true);

            address loanToken = token.loanTokenAddress();
            vaultBalance[i] = DAppHelper_TokenLike(loanToken).balanceOf(bZxProtocol);
            if (legacyVault != address(0)) {
                vaultBalance[i] += DAppHelper_TokenLike(loanToken).balanceOf(legacyVault);
            }
        }
    }
}
