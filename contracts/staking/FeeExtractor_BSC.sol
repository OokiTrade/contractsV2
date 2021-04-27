/**
 * Copyright 2017-2021, bZeroX, LLC <https://bzx.network/>. All Rights Reserved.
 * Licensed under the Apache License, Version 2.0.
 */

pragma solidity 0.5.17;
pragma experimental ABIEncoderV2;

import "../proxies/0_5/Upgradeable_0_5.sol";
import "../openzeppelin/SafeMath.sol";
import "../openzeppelin/SafeERC20.sol";
import "../interfaces/IWethERC20.sol";
import "../interfaces/IUniswapV2Router.sol";
import "./interfaces/IBZxPartial.sol";


contract FeeExtractor_BSC is Upgradeable_0_5 {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    IBZxPartial public constant bZx = IBZxPartial(0xC47812857A74425e2039b57891a3DFcF51602d5d);

    address public constant BGOV = 0xf8E026dC4C0860771f691EcFFBbdfe2fa51c77CF;
    address public constant BNB = 0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c;

    IUniswapV2Router public constant pancakeRouterV1 = IUniswapV2Router(0x05fF2B0DB69458A0750badebc4f9e13aDd608C7F);
    IUniswapV2Router public constant pancakeRouterV2 = IUniswapV2Router(0x10ED43C718714eb63d5aA57B78B54704E256024E);

    address internal constant ZERO_ADDRESS = address(0);

    bool public isPaused;

    address public fundsWallet;

    mapping(address => uint256) public exportedFees;

    uint256 public burnPercent;

    address[] public currentFeeTokens;


    event BuyAndBurn(
        address indexed sender,
        address indexed asset,
        uint256 burnAmount
    );

    modifier onlyEOA() {
        require(msg.sender == tx.origin, "unauthorized");
        _;
    }

    modifier checkPause() {
        require(!isPaused || isOwner(), "paused");
        _;
    }


    function sweepFees(
        uint256 fraction) // 0 or 1e20 == 100%
        public
        // sweepFeesByAsset() does checkPause
        returns (uint256 burnAmount)
    {
        return sweepFeesByAsset(currentFeeTokens, fraction);
    }

    function sweepFeesByAsset(
        address[] memory assets,
        uint256 fraction) // 0 or 1e20 == 100%
        public
        checkPause
        onlyEOA
        returns (uint256 burnAmount)
    {
        require(fraction == 0 || fraction <= 1e20, "invalid fraction");
        if (fraction == 0) {
            fraction = 1e20;
        }

        burnAmount = _buyAndBurn(assets, fraction);
    }

    function _buyAndBurn(
        address[] memory assets,
        uint256 fraction)
        internal
        returns (uint256 burnAmount)
    {
        uint256[] memory amounts = bZx.withdrawFees(assets, address(this), IBZxPartial.FeeClaimType.All);

        for (uint256 i = 0; i < assets.length; i++) {
            require(assets[i] != BGOV, "BGOV not supported");
            exportedFees[assets[i]] = exportedFees[assets[i]]
                .add(amounts[i]);
        }
 
        uint256 bnbOutput = exportedFees[BNB]
            .mul(fraction)
            .div(1e20);
        exportedFees[BNB] -= bnbOutput;

        address asset;
        uint256 amount;
        for (uint256 i = 0; i < assets.length; i++) {
            asset = assets[i];
            if (asset == BGOV || asset == BNB) {
                continue;
            }
            amount = exportedFees[asset]
                .mul(fraction)
                .div(1e20);
            exportedFees[asset] -= amount;

            if (amount != 0) {
                bnbOutput += _swapWithPair(asset, BNB, amount, false);
            }
        }
        if (bnbOutput != 0) {
            burnAmount = bnbOutput
                .mul(burnPercent)
                .div(1e20);

            IWethERC20(BNB).withdraw(bnbOutput - burnAmount);
            Address.sendValue(fundsWallet, bnbOutput - burnAmount);

            // burnAmount gets reflected in BGOV here
            burnAmount = _swapWithPair(BNB, BGOV, burnAmount, true);

            // burn baby burn
            IERC20(BGOV).transfer(
                0x000000000000000000000000000000000000dEaD,
                burnAmount
            );

            emit BuyAndBurn(
                msg.sender,
                BGOV,
                burnAmount
            );
        }
    }

    function _swapWithPair(
        address inAsset,
        address outAsset,
        uint256 inAmount,
        bool usesV1)
        internal
        returns (uint256 returnAmount)
    {
        address[] memory path = new address[](2);
        path[0] = inAsset;
        path[1] = outAsset;

        IUniswapV2Router router;
        if (usesV1) {
            router = pancakeRouterV1;
        } else {
            router = pancakeRouterV2;
        }

        uint256[] memory amounts = router.swapExactTokensForTokens(
            inAmount,
            1, // amountOutMin
            path,
            address(this),
            block.timestamp
        );

        returnAmount = amounts[1];
    }

    // OnlyOwner functions

    function togglePause(
        bool _isPaused)
        external
        onlyOwner
    {
        isPaused = _isPaused;
    }

    function setFundsWallet(
        address _fundsWallet)
        external
        onlyOwner
    {
        fundsWallet = _fundsWallet;
    }

    function setBurnPercent(
        uint256 _burnPercent)
        external
        onlyOwner
    {
        require(_burnPercent <= 1e20, "value too high");
        burnPercent = _burnPercent;
    }

    function setFeeTokens(
        address[] calldata tokens)
        external
        onlyOwner
    {
        currentFeeTokens = tokens;
        
        IERC20(BNB).safeApprove(address(pancakeRouterV1), 0);
        IERC20(BNB).safeApprove(address(pancakeRouterV1), uint256(-1));
        for (uint256 i = 0; i < tokens.length; i++) {
            IERC20(tokens[i]).safeApprove(address(pancakeRouterV2), 0);
            IERC20(tokens[i]).safeApprove(address(pancakeRouterV2), uint256(-1));
        }
    }
}
