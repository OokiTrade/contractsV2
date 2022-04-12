/**
 * Copyright 2017-2022, OokiDao. All Rights Reserved.
 * Licensed under the Apache License, Version 2.0.
 */

pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;

import "@openzeppelin-4.3.2/token/ERC20/extensions/IERC20Metadata.sol";
import "../proxies/0_8/Upgradeable_0_8.sol";
import "../interfaces/IUniswapV3SwapRouter.sol";
import "@uniswap/v3-periphery/contracts/interfaces/IQuoter.sol";
import "./interfaces/IPriceGetterP125.sol";

contract BuyBackAndBurn is Upgradeable_0_8 {
    IPriceGetterP125.V3Specs public specsForTWAP;
    uint256 public maxPriceDisagreement; //set value as 100+x% on WEI_PRECISION_PERCENT
    bool public isPaused;
    address public treasuryWallet;
    IPriceGetterP125 public priceGetter;

    address public constant USDC = 0x2791Bca1f2de4661ED88A30C99A7a9449Aa84174;
    address public constant P125 = 0x83000597e8420aD7e9EDD410b2883Df1b83823cF;
    IUniswapV3SwapRouter public constant SWAP_ROUTER =
        IUniswapV3SwapRouter(0xE592427A0AEce92De3Edee1F18E0157C05861564); //uni v3
    IQuoter public constant QUOTER =
        IQuoter(0xb27308f9F90D607463bb33eA1BeBb41C27CE5AB6); //uni v3 quote v2
    uint256 public constant WEI_PRECISION_PERCENT = 10**20; //1e18 precision on percentages

    event BuyBack(
        uint256 indexed price,
        uint256 amountIn,
        uint256 amountBought
    );

    modifier onlyEOA() {
        require(msg.sender == tx.origin, "unauthorized");
        _;
    }

    modifier checkPause() {
        require(!isPaused || msg.sender == owner(), "paused");
        _;
    }

    function getDebtTokenAmountOut(uint256 amountIn) public returns (uint256) {
        return QUOTER.quoteExactInput(specsForTWAP.route, amountIn);
    }

    function worstExecPrice() public view returns (uint256) {
        uint256 quoteAmount = priceGetter.worstExecPrice(specsForTWAP);
        return (quoteAmount * maxPriceDisagreement) / WEI_PRECISION_PERCENT;
    }

    function buyBack(uint256 percentage) public checkPause onlyEOA {
        uint256 buyAmount;
        uint256 fullBalance = IERC20Metadata(USDC).balanceOf(address(this));
        uint256 minAmountOut = (worstExecPrice() * fullBalance) / 10**6;
        uint256 balanceUsed;
        uint256 execPrice;
        if (getDebtTokenAmountOut(fullBalance) >= minAmountOut) {
            (execPrice, balanceUsed, buyAmount) = _buyDebtToken(
                WEI_PRECISION_PERCENT
            ); //uses full amount
        } else {
            (execPrice, balanceUsed, buyAmount) = _buyDebtToken(percentage); //uses partial
        }
        emit BuyBack(execPrice, balanceUsed, buyAmount);
    }

    function _buyDebtToken(uint256 percentage)
        internal
        returns (
            uint256 price,
            uint256 amountIn,
            uint256 amountOut
        )
    {
        uint256 bought;
        uint256 balanceUsed = (IERC20Metadata(USDC).balanceOf(address(this)) *
            percentage) / WEI_PRECISION_PERCENT;
        uint256 minAmountOut = (worstExecPrice() * balanceUsed) / 10**6;
        uint256 execPrice = getDebtTokenAmountOut(balanceUsed);
        require(
            minAmountOut / 10**12 >= balanceUsed,
            "worst absolue price is 1:1"
        ); //caps buyback price to $1
        IUniswapV3SwapRouter.ExactInputParams
            memory params = IUniswapV3SwapRouter.ExactInputParams({
                path: specsForTWAP.route,
                recipient: address(this),
                deadline: block.timestamp,
                amountIn: balanceUsed,
                amountOutMinimum: minAmountOut
            });
        return (execPrice, balanceUsed, SWAP_ROUTER.exactInput(params));
    }

    // OnlyOwner functions

    function togglePause(bool _isPaused) public onlyOwner {
        isPaused = _isPaused;
    }

    function sendToTreasury() public onlyOwner {
        IERC20Metadata(P125).transfer(
            treasuryWallet,
            IERC20Metadata(P125).balanceOf(address(this))
        ); //transfers full balance to multisig to be sent to Ethereum and burnt
    }

    function setApproval() public onlyOwner {
        IERC20Metadata(USDC).approve(address(SWAP_ROUTER), 0);
        IERC20Metadata(USDC).approve(address(SWAP_ROUTER), type(uint256).max);
    }

    function setPriceGetter(IPriceGetterP125 _wallet) public onlyOwner {
        priceGetter = _wallet;
    }

    function setTreasuryWallet(address _wallet) public onlyOwner {
        treasuryWallet = _wallet;
    }

    function setMaxPriceDisagreement(uint256 value) public onlyOwner {
        maxPriceDisagreement = value;
    }

    function setTWAPSpecs(IPriceGetterP125.V3Specs memory specs)
        public
        onlyOwner
    {
        specsForTWAP = specs;
    }

    function rescue(IERC20 _token) public onlyOwner {
        _token.transfer(
            msg.sender,
            _token.balanceOf(address(this))
        );
    }
}
