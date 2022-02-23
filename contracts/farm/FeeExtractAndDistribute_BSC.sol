/**
 * Copyright 2017-2022, OokiDao. All Rights Reserved.
 * Licensed under the Apache License, Version 2.0.
 */

pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

import "@openzeppelin-3.4.0/token/ERC20/SafeERC20.sol";
import "./interfaces/Upgradeable.sol";
import "./interfaces/IWethERC20.sol";
import "./interfaces/IUniswapV2Router.sol";
import "../../interfaces/IBZx.sol";
import "./interfaces/IMasterChefPartial.sol";
import "./interfaces/IPriceFeeds.sol";

contract FeeExtractAndDistribute_BSC is Upgradeable {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    IBZx public constant bZx = IBZx(0xC47812857A74425e2039b57891a3DFcF51602d5d);
    IMasterChefPartial public constant chef =
        IMasterChefPartial(0x1FDCA2422668B961E162A8849dc0C2feaDb58915);

    address public constant BGOV = 0xf8E026dC4C0860771f691EcFFBbdfe2fa51c77CF;
    address public constant BNB = 0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c;
    address public constant BZRX = 0x4b87642AEDF10b642BE4663Db842Ecc5A88bf5ba;
    address public constant iBZRX = 0xA726F2a7B200b03beB41d1713e6158e0bdA8731F;

    IUniswapV2Router public constant pancakeRouterV2 =
        IUniswapV2Router(0x10ED43C718714eb63d5aA57B78B54704E256024E);

    address internal constant ZERO_ADDRESS = address(0);

    //below is unused
    bool public isPaused; 

    address payable public fundsWallet;

    mapping(address => uint256) public exportedFees;

    address[] public currentFeeTokens;

    mapping(IERC20 => uint256) public tokenHeld;

    address payable public treasuryWallet;

    event ExtractAndDistribute(uint256 amountTreasury, uint256 amountStakers);

    event AssetSwap(
        address indexed sender,
        address indexed srcAsset,
        address indexed dstAsset,
        uint256 srcAmount,
        uint256 dstAmount
    );

    event AssetBurn(
        address indexed sender,
        address indexed asset,
        uint256 amount
    );

    modifier onlyEOA() {
        require(msg.sender == tx.origin, "unauthorized");
        _;
    }

    modifier checkPause() {
        require(!isPaused || msg.sender == owner(), "paused");
        _;
    }

    function sweepFees() public // sweepFeesByAsset() does checkPause
    {
        sweepFeesByAsset(currentFeeTokens);
    }

    function sweepFeesByAsset(address[] memory assets)
        public
        checkPause
        onlyEOA
    {
        _extractAndDistribute(assets);
    }

    function _extractAndDistribute(address[] memory assets) internal {
        uint256[] memory amounts = bZx.withdrawFees(
            assets,
            address(this),
            IBZx.FeeClaimType.All
        );

        for (uint256 i = 0; i < assets.length; i++) {
            require(assets[i] != BGOV, "asset not supported");
            exportedFees[assets[i]] = exportedFees[assets[i]].add(amounts[i]);
        }

        uint256 bnbOutput = exportedFees[BNB];
        exportedFees[BNB] = 0;

        address asset;
        uint256 amount;
        for (uint256 i = 0; i < assets.length; i++) {
            asset = assets[i];
            if (asset == BGOV || asset == BZRX || asset == BNB) {
                continue;
            }
            amount = exportedFees[asset];
            exportedFees[asset] = 0;

            if (amount != 0) {
                bnbOutput += _swapWithPair(asset, BNB, amount);
            }
        }

        if (bnbOutput != 0) {
            // add any BZRX extracted from fees
            uint256 bzrxAmount = exportedFees[BZRX];
            exportedFees[BZRX] = 0;

            if (bzrxAmount != 0) {
                IERC20(BZRX).safeTransfer(iBZRX, bzrxAmount);
                emit AssetSwap(msg.sender, address(0), BZRX, 0, bzrxAmount);
            }

            IWethERC20(BNB).withdraw(bnbOutput);
            bnbOutput = bnbOutput / 2;
            chef.addAltReward.value(bnbOutput)();

            Address.sendValue(treasuryWallet, bnbOutput);

            emit ExtractAndDistribute(bnbOutput, bnbOutput);
        }
    }

    function _swapWithPair(
        address inAsset,
        address outAsset,
        uint256 inAmount
    ) internal returns (uint256 returnAmount) {
        address[] memory path = new address[](2);
        path[0] = inAsset;
        path[1] = outAsset;

        uint256[] memory amounts = pancakeRouterV2.swapExactTokensForTokens(
            inAmount,
            1, // amountOutMin
            path,
            address(this),
            block.timestamp
        );

        returnAmount = amounts[1];
    }

    // OnlyOwner functions

    function togglePause(bool _isPaused) external onlyOwner {
        isPaused = _isPaused;
    }

    function setFundsWallet(address payable _wallet) external onlyOwner {
        fundsWallet = _wallet;
    }

    function setTreasuryWallet(address payable _wallet) external onlyOwner {
        treasuryWallet = _wallet;
    }

    function setFeeTokens(address[] calldata tokens) external onlyOwner {
        currentFeeTokens = tokens;
        for (uint256 i = 0; i < tokens.length; i++) {
            IERC20(tokens[i]).safeApprove(address(pancakeRouterV2), 0);
            IERC20(tokens[i]).safeApprove(
                address(pancakeRouterV2),
                uint256(-1)
            );
        }
        //IERC20(BGOV).safeApprove(address(chef), 0);
        //IERC20(BGOV).safeApprove(address(chef), uint256(-1));
    }

    function depositToken(IERC20 token, uint256 amount) external onlyOwner {
        token.safeTransferFrom(msg.sender, address(this), amount);

        tokenHeld[token] = tokenHeld[token].add(amount);
    }

    function withdrawToken(IERC20 token, uint256 amount) external onlyOwner {
        uint256 balance = tokenHeld[token];
        if (amount > balance) {
            amount = balance;
        }

        tokenHeld[token] = tokenHeld[token].sub(amount);

        token.safeTransfer(msg.sender, amount);
    }
}
