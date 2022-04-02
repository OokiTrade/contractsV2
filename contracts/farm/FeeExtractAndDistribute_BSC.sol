/**
 * Copyright 2017-2022, OokiDao. All Rights Reserved.
 * Licensed under the Apache License, Version 2.0.
 */

pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;

import "@openzeppelin-4.3.2/token/ERC20/IERC20.sol";
import "./interfaces/IUniswapV2Router.sol";
import "../../interfaces/IBZx.sol";
import "@celer/contracts/interfaces/IBridge.sol";
import "../../interfaces/IPriceFeeds.sol";
import "../governance/PausableGuardian_0_8.sol";

contract FeeExtractAndDistribute_BSC is PausableGuardian_0_8 {
    address public implementation;
    IBZx public constant BZX = IBZx(0xD154eE4982b83a87b0649E5a7DDA1514812aFE1f);

    address public constant BNB = 0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c;
    address public constant USDC = 0x8AC76a51cc950d9822D68b83fE1Ad97B32Cd580d;
    uint256 public constant MIN_USDC_AMOUNT = 1e18; //1 USDC minimum bridge amount
    uint64 public constant DEST_CHAINID = 137; //send to polygon

    IUniswapV2Router public constant SWAPS_ROUTER_V2 =
        IUniswapV2Router(0x10ED43C718714eb63d5aA57B78B54704E256024E);

    address internal constant ZERO_ADDRESS = address(0);

    uint256 public constant MAX_DISAGREEMENT = 5e18;

    mapping(address => uint256) public exportedFees;

    address[] public currentFeeTokens;

    address payable public treasuryWallet;

    address public bridge; //bridging contract

    event ExtractAndDistribute(uint256 amountTreasury, uint256 amountStakers);

    event AssetSwap(
        address indexed sender,
        address indexed srcAsset,
        address indexed dstAsset,
        uint256 srcAmount,
        uint256 dstAmount
    );

    function sweepFees() public pausable {
        _extractAndDistribute(currentFeeTokens);
    }

    function sweepFees(address[] memory assets) public pausable {
        _extractAndDistribute(assets);
    }

    function _extractAndDistribute(address[] memory assets) internal {
        uint256[] memory amounts = BZX.withdrawFees(
            assets,
            address(this),
            IBZx.FeeClaimType.All
        );

        for (uint256 i = 0; i < assets.length; i++) {
            exportedFees[assets[i]] += amounts[i];
        }

        uint256 usdcOutput = exportedFees[USDC];
        exportedFees[USDC] = 0;

        address asset;
        uint256 amount;
        for (uint256 i = 0; i < assets.length; i++) {
            asset = assets[i];
            if (asset == USDC) continue; //USDC already accounted for
            amount = exportedFees[asset];
            exportedFees[asset] = 0;

            if (amount != 0) {
                usdcOutput += asset == BNB
                    ? _swapWithPair([asset, USDC], amount)
                    : _swapWithPair([asset, BNB, USDC], amount); //builds route for all tokens to route through ETH
            }
        }

        if (usdcOutput != 0) {
            _bridgeFeesAndDistribute(); //bridges fees to Ethereum to be distributed to stakers
            emit ExtractAndDistribute(usdcOutput, 0); //for tracking distribution amounts
        }
    }

    function _swapWithPair(address[2] memory route, uint256 inAmount)
        internal
        returns (uint256 returnAmount)
    {
        address[] memory path = new address[](2);
        path[0] = route[0];
        path[1] = route[1];
        uint256[] memory amounts = SWAPS_ROUTER_V2.swapExactTokensForTokens(
            inAmount,
            1, // amountOutMin
            path,
            address(this),
            block.timestamp
        );

        returnAmount = amounts[1];
        _checkUniDisagreement(
            path[0],
            inAmount,
            returnAmount,
            MAX_DISAGREEMENT
        );
    }

    function _swapWithPair(address[3] memory route, uint256 inAmount)
        internal
        returns (uint256 returnAmount)
    {
        address[] memory path = new address[](3);
        path[0] = route[0];
        path[1] = route[1];
        path[2] = route[2];
        uint256[] memory amounts = SWAPS_ROUTER_V2.swapExactTokensForTokens(
            inAmount,
            1, // amountOutMin
            path,
            address(this),
            block.timestamp
        );

        returnAmount = amounts[2];
        _checkUniDisagreement(
            path[0],
            inAmount,
            returnAmount,
            MAX_DISAGREEMENT
        );
    }

    function _checkUniDisagreement(
        address asset,
        uint256 assetAmount,
        uint256 recvAmount,
        uint256 maxDisagreement
    ) internal view {
        uint256 estAmountOut = IPriceFeeds(BZX.priceFeeds()).queryReturn(
            asset,
            USDC,
            assetAmount
        );

        uint256 spreadValue = estAmountOut > recvAmount
            ? estAmountOut - recvAmount
            : recvAmount - estAmountOut;
        if (spreadValue != 0) {
            spreadValue = (spreadValue * 1e20) / estAmountOut;

            require(
                spreadValue <= maxDisagreement,
                "uniswap price disagreement"
            );
        }
    }

    function _bridgeFeesAndDistribute() internal {
        require(
            IERC20(USDC).balanceOf(address(this)) >= MIN_USDC_AMOUNT,
            "FeeExtractAndDistribute: bridge amount too low"
        );
        IBridge(bridge).send(
            treasuryWallet,
            USDC,
            IERC20(USDC).balanceOf(address(this)),
            DEST_CHAINID,
            uint64(block.timestamp),
            10000
        );
    }

    // OnlyOwner functions

    function setTreasuryWallet(address payable _wallet) public onlyOwner {
        treasuryWallet = _wallet;
    }

    function setFeeTokens(address[] calldata tokens) public onlyOwner {
        currentFeeTokens = tokens;
        for (uint256 i = 0; i < tokens.length; i++) {
            IERC20(tokens[i]).approve(
                address(SWAPS_ROUTER_V2),
                type(uint256).max
            );
        }
    }

    function setBridgeApproval(address token) public onlyOwner {
        IERC20(token).approve(bridge, 0);
        IERC20(token).approve(bridge, type(uint256).max);
    }

    function setBridge(address _wallet) public onlyOwner {
        bridge = _wallet;
    }
}
