/**
 * Copyright 2017-2022, OokiDao. All Rights Reserved.
 * Licensed under the Apache License, Version 2.0.
 */

pragma solidity >=0.6.0 <0.8.0;
pragma experimental ABIEncoderV2;

/// SPDX-License-Identifier: MIT

import "@openzeppelin-3.4.0/access/Ownable.sol";
import "@openzeppelin-3.4.0/token/ERC20/IERC20.sol";

import "../../interfaces/IPriceFeeds.sol";
import "../../interfaces/IToken.sol";
import "../../interfaces/IBZx.sol";

contract HelperImpl is Ownable {

    //address public constant bZxProtocol = 0xD8Ee69652E4e4838f2531732a46d1f7F584F0b7f; // mainnet
    //address public constant bZxProtocol = 0x5cfba2639a3db0D9Cc264Aa27B2E6d134EeA486a; // kovan
    //address public constant bZxProtocol = 0xD154eE4982b83a87b0649E5a7DDA1514812aFE1f; // bsc
    //address public constant bZxProtocol = 0x059D60a9CEfBc70b9Ea9FFBb9a041581B1dFA6a8; // polygon
    //address public constant bZxProtocol = 0x37407F3178ffE07a6cF5C847F8f680FEcf319FAB; // arbitrum
    address public constant bZxProtocol = 0xAcedbFd5Bc1fb0dDC948579d4195616c05E74Fd1; // optimism


    // address public constant wethToken = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2; // mainnet
    // address public constant wethToken = 0xd0A1E359811322d97991E03f863a0C30C2cF029C; // kovan
    // address public constant wethToken = 0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c; // bsc
    // address public constant wethToken = 0x0d500B1d8E8eF31E21C99d1Db9A6444d3ADf1270; // polygon
    // address public constant wethToken = 0x82aF49447D8a07e3bd95BD0d56f35241523fBab1; // arbitrum
    address public constant wethToken = 0x4200000000000000000000000000000000000006; // optimism

    uint256 internal constant WEI_PRECISION = 10**18;
    uint256 internal constant WEI_PERCENT_PRECISION = 10**20;

    function balanceOf(IERC20[] calldata tokens, address wallet)
        public view
        returns (uint256[] memory balances)
    {
        balances = new uint256[](tokens.length);
        for (uint256 i = 0; i < tokens.length; i++) {
            balances[i] = tokens[i].balanceOf(wallet);
        }
    }

    function totalSupply(IERC20[] calldata tokens)
        public view
        returns (uint256[] memory totalSupply)
    {
        totalSupply = new uint256[](tokens.length);
        for (uint256 i = 0; i < tokens.length; i++) {
            totalSupply[i] = tokens[i].totalSupply();
        }
    }

    function allowance(
        IERC20[] calldata tokens,
        address owner,
        address spender
    ) public view returns (uint256[] memory allowances) {
        allowances = new uint256[](tokens.length);
        for (uint256 i = 0; i < tokens.length; i++) {
            allowances[i] = tokens[i].allowance(owner, spender);
        }
    }

    function tokenPrice(IToken[] calldata tokens)
        public view
        returns (uint256[] memory prices)
    {
        prices = new uint256[](tokens.length);
        for (uint256 i = 0; i < tokens.length; i++) {
            prices[i] = tokens[i].tokenPrice();
        }
    }

    function supplyInterestRate(IToken[] calldata tokens)
        public view
        returns (uint256[] memory rates)
    {
        rates = new uint256[](tokens.length);
        for (uint256 i = 0; i < tokens.length; i++) {
            rates[i] = tokens[i].supplyInterestRate();
        }
    }

    function borrowInterestRate(IToken[] calldata tokens)
        public view
        returns (uint256[] memory rates)
    {
        rates = new uint256[](tokens.length);
        for (uint256 i = 0; i < tokens.length; i++) {
            rates[i] = tokens[i].borrowInterestRate();
        }
    }

    function assetBalanceOf(IToken[] calldata tokens, address wallet)
        public view
        returns (uint256[] memory balances)
    {
        balances = new uint256[](tokens.length);
        for (uint256 i = 0; i < tokens.length; i++) {
            balances[i] = tokens[i].assetBalanceOf(wallet);
        }
    }

    function profitOf(IToken[] calldata tokens, address wallet)
        public view
        returns (int256[] memory profits)
    {
        profits = new int256[](tokens.length);
        for (uint256 i = 0; i < tokens.length; i++) {
            profits[i] = tokens[i].profitOf(wallet);
        }
    }

    function marketLiquidity(IToken[] calldata tokens)
        public view
        returns (uint256[] memory liquidity)
    {
        liquidity = new uint256[](tokens.length);
        for (uint256 i = 0; i < tokens.length; i++) {
            liquidity[i] = IERC20(tokens[i].loanTokenAddress()).balanceOf(address(tokens[i]));
        }
    }


    struct ReserveDetail{
        address iToken;
        uint256 totalAssetSupply;
        uint256 totalAssetBorrow;
        uint256 supplyInterestRate;
        uint256 borrowInterestRate;
        uint256 torqueBorrowInterestRate;
        uint256 vaultBalance;
    }

    function reserveDetails(IToken[] calldata tokens)
        public
        view
        returns (ReserveDetail[] memory reserveDetails)    
        {
        reserveDetails = new ReserveDetail[](tokens.length);

        for (uint256 i = 0; i < tokens.length; i++) {
            reserveDetails[i].iToken = address(tokens[i]);
            reserveDetails[i].totalAssetSupply = tokens[i].totalAssetSupply();
            reserveDetails[i].totalAssetBorrow = tokens[i].totalAssetBorrow();
            reserveDetails[i].supplyInterestRate = tokens[i].supplyInterestRate();
            reserveDetails[i].borrowInterestRate = tokens[i].borrowInterestRate();
            reserveDetails[i].torqueBorrowInterestRate = tokens[i].nextBorrowInterestRate(0);
            reserveDetails[i].vaultBalance = IERC20(tokens[i].loanTokenAddress()).balanceOf(bZxProtocol);
        }
    }

    struct AssetRates{
        uint256 rate;
        uint256 precision;
        uint256 destAmount;
    }

    function assetRates(
        address usdTokenAddress,
        address[] memory tokens,
        uint256[] memory sourceAmounts)
        public
        view
        returns (AssetRates[] memory assetRates)
    {
        IPriceFeeds feeds = IPriceFeeds(IBZx(bZxProtocol).priceFeeds());
        assetRates = new AssetRates[](tokens.length);
 

        for (uint256 i = 0; i < tokens.length; i++) {
            (assetRates[i].rate, assetRates[i].precision) = feeds.queryRate(
                tokens[i],
                usdTokenAddress
            );

            if (sourceAmounts[i] != 0) {
                assetRates[i].destAmount = sourceAmounts[i] * assetRates[i].rate;
                require(assetRates[i].destAmount / sourceAmounts[i] == assetRates[i].rate, "overflow");
                assetRates[i].destAmount = assetRates[i].destAmount / assetRates[i].precision;
            }
        }
    }



    function getDepositAmountForBorrow(
        uint256 borrowAmount,
        address loanTokenAddress,
        address collateralTokenAddress)     // address(0) means ETH
        external
        view
        returns (uint256) // depositAmount
    {   
        IToken iToken = IToken(IBZx(bZxProtocol).underlyingToLoanPool(loanTokenAddress));
        if (borrowAmount != 0) {
            if (borrowAmount <= IERC20(loanTokenAddress).balanceOf(address(iToken))) {
                if (collateralTokenAddress == address(0)) {
                    collateralTokenAddress = wethToken;
                }
                return getRequiredCollateralByParams(
                    iToken.loanParamsIds(uint256(keccak256(abi.encodePacked(
                        collateralTokenAddress,
                        true
                    )))),
                    borrowAmount
                ) + 10; // some dust to compensate for rounding errors
            }
        }
    }

    function getBorrowAmountForDeposit(
        uint256 depositAmount,
        address loanTokenAddress,
        address collateralTokenAddress)     // address(0) means ETH
        external
        view
        returns (uint256 borrowAmount)
    {
        IToken iToken = IToken(IBZx(bZxProtocol).underlyingToLoanPool(loanTokenAddress));
        if (depositAmount != 0) {
            if (collateralTokenAddress == address(0)) {
                collateralTokenAddress = wethToken;
            }
            borrowAmount = IBZx(bZxProtocol).getBorrowAmountByParams(
                iToken.loanParamsIds(uint256(keccak256(abi.encodePacked(
                    collateralTokenAddress,
                    true
                )))),
                depositAmount
            );

            if (borrowAmount > IERC20(loanTokenAddress).balanceOf(address(iToken))) {
                borrowAmount = 0;
            }
        }
    }

    function getRequiredCollateralByParams(
        bytes32 loanParamsId,
        uint256 newPrincipal)
        internal
        view
        returns (uint256 collateralAmountRequired)
    {
        IBZx.LoanParams memory loanParamsLocal = IBZx(bZxProtocol).loanParams(loanParamsId);
        return IBZx(bZxProtocol).getRequiredCollateral(
            loanParamsLocal.loanToken,
            loanParamsLocal.collateralToken,
            newPrincipal,
            loanParamsLocal.minInitialMargin, // marginAmount
            loanParamsLocal.maxLoanTerm == 0 ? // isTorqueLoan
                true :
                false
        );
    }

    function getBorrowAmountByParams(
        bytes32 loanParamsId,
        uint256 collateralTokenAmount)
        internal
        view
        returns (uint256 borrowAmount)
    {
        IBZx.LoanParams memory loanParamsLocal = IBZx(bZxProtocol).loanParams(loanParamsId);
        return getBorrowAmount(
            loanParamsLocal.loanToken,
            loanParamsLocal.collateralToken,
            collateralTokenAmount,
            loanParamsLocal.minInitialMargin, // marginAmount
            loanParamsLocal.maxLoanTerm == 0 ? // isTorqueLoan
                true :
                false
        );
    }



    function getBorrowAmount(
        address loanToken,
        address collateralToken,
        uint256 collateralTokenAmount,
        uint256 marginAmount,
        bool isTorqueLoan)
        internal
        view
        returns (uint256 borrowAmount)
    {
        if (marginAmount != 0) {
            if (isTorqueLoan) {
                marginAmount = marginAmount
                    + (WEI_PERCENT_PRECISION); // adjust for over-collateralized loan
            }

            if (loanToken == collateralToken) {
                borrowAmount = collateralTokenAmount
                    * (WEI_PERCENT_PRECISION)
                    / (marginAmount);
            } else {
                (uint256 sourceToDestRate, uint256 sourceToDestPrecision) = IPriceFeeds(IBZx(bZxProtocol).priceFeeds()).queryRate(
                    collateralToken,
                    loanToken
                );
                if (sourceToDestPrecision != 0) {
                    borrowAmount = collateralTokenAmount
                        * (WEI_PERCENT_PRECISION)
                        * (sourceToDestRate)
                        / (marginAmount)
                        / (sourceToDestPrecision);
                }
            }

            uint256 feePercent = isTorqueLoan ?
                IBZx(bZxProtocol).borrowingFeePercent() :
                IBZx(bZxProtocol).tradingFeePercent();
            if (borrowAmount != 0 && feePercent != 0) {
                borrowAmount = borrowAmount
                    * (
                        WEI_PERCENT_PRECISION - feePercent // never will overflow
                    )
                    / (WEI_PERCENT_PRECISION);
            }
        }
    }

}
