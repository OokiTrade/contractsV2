/**
 * Copyright 2017-2023, OokiDao. All Rights Reserved.
 * Licensed under the Apache License, Version 2.0.
 */

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

import "@openzeppelin-4.8.3/token/ERC20/IERC20.sol";
import "contracts/interfaces/uniswap/IUniswapV3SwapRouter.sol";
import "interfaces/IBZx.sol";
import "@celer/contracts/interfaces/IBridge.sol";
import "interfaces/IPriceFeeds.sol";
import "contracts/governance/PausableGuardian_0_8.sol";

contract FeeExtractAndDistribute_Optimism is PausableGuardian_0_8 {
  address public implementation;
  IBZx public constant BZX = IBZx(0xAcedbFd5Bc1fb0dDC948579d4195616c05E74Fd1);

  address public constant ETH = 0x4200000000000000000000000000000000000006;
  address public constant USDC = 0x7F5c764cBc14f9669B88837ca1490cCa17c31607;
  uint64 public constant DEST_CHAINID = 137; //send to polygon
  uint256 public constant MIN_USDC_AMOUNT = 30e6; //$30 min bridge amount
  IUniswapV3SwapRouter public constant SWAPS_ROUTER_V3 = IUniswapV3SwapRouter(0xE592427A0AEce92De3Edee1F18E0157C05861564);

  address internal constant ZERO_ADDRESS = address(0);

  uint256 public constant MAX_DISAGREEMENT = 5e18;

  mapping(address => uint256) public exportedFees;

  address[] public currentFeeTokens;

  mapping(address => bytes) public swapPaths;

  address payable public treasuryWallet;

  address public bridge; //bridging contract

  uint32 public slippage = 10000; //1%

  event ExtractAndDistribute(uint256 amountTreasury, uint256 amountStakers);

  event AssetSwap(address indexed sender, address indexed srcAsset, address indexed dstAsset, uint256 srcAmount, uint256 dstAmount);

  function sweepFees() public pausable {
    _extractAndDistribute(currentFeeTokens);
  }

  function sweepFees(address[] memory assets) public pausable {
    _extractAndDistribute(assets);
  }

  function _extractAndDistribute(address[] memory assets) internal {
    uint256[] memory amounts = BZX.withdrawFees(assets, address(this), IBZx.FeeClaimType.All);

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
        usdcOutput += _swap(asset, amount);
      }
    }

    if (usdcOutput != 0) {
      _bridgeFeesAndDistribute(); //bridges fees to Ethereum to be distributed to stakers
      emit ExtractAndDistribute(usdcOutput, 0); //for tracking distribution amounts
    }
  }

  function _swap(address inToken, uint256 amountIn) internal returns (uint256 returnAmount) {
    IUniswapV3SwapRouter.ExactInputParams memory params = IUniswapV3SwapRouter.ExactInputParams({
      path: swapPaths[inToken],
      recipient: address(this),
      deadline: block.timestamp,
      amountIn: amountIn,
      amountOutMinimum: 1
    });
    returnAmount = SWAPS_ROUTER_V3.exactInput(params);
    _checkUniDisagreement(inToken, amountIn, returnAmount, MAX_DISAGREEMENT);
  }

  function _bridgeFeesAndDistribute() internal {
    require(IERC20(USDC).balanceOf(address(this)) >= MIN_USDC_AMOUNT, "FeeExtractAndDistribute_Optimism: Fees Bridged Too Little");
    IBridge(bridge).send(treasuryWallet, USDC, IERC20(USDC).balanceOf(address(this)), DEST_CHAINID, uint64(block.timestamp), slippage);
  }

  // OnlyOwner functions

  function setTreasuryWallet(address payable _wallet) public onlyOwner {
    treasuryWallet = _wallet;
  }

  function setFeeTokens(address[] calldata tokens, bytes[] calldata swapPath) public onlyOwner {
    currentFeeTokens = tokens;
    for (uint256 i = 0; i < tokens.length; i++) {
      swapPaths[tokens[i]] = swapPath[i];
      IERC20(tokens[i]).approve(address(SWAPS_ROUTER_V3), 0);
      IERC20(tokens[i]).approve(address(SWAPS_ROUTER_V3), type(uint256).max);
    }
  }

  function setBridgeApproval(address token) public onlyOwner {
    IERC20(token).approve(bridge, 0);
    IERC20(token).approve(bridge, type(uint256).max);
  }

  function setBridge(address _wallet) public onlyOwner {
    bridge = _wallet;
  }

  function _checkUniDisagreement(address asset, uint256 assetAmount, uint256 recvAmount, uint256 maxDisagreement) internal view {
    uint256 estAmountOut = IPriceFeeds(BZX.priceFeeds()).queryReturn(asset, USDC, assetAmount);

    uint256 spreadValue = estAmountOut > recvAmount ? estAmountOut - recvAmount : recvAmount - estAmountOut;
    if (spreadValue != 0) {
      spreadValue = (spreadValue * 1e20) / estAmountOut;

      require(spreadValue <= maxDisagreement, "uniswap price disagreement");
    }
  }

  function setSlippage(uint32 newSlippage) external onlyGuardian {
    slippage = newSlippage;
  }

  function requestRefund(bytes calldata wdmsg, bytes[] calldata sigs, address[] calldata signers, uint256[] calldata powers) external onlyGuardian {
    IBridge(bridge).withdraw(wdmsg, sigs, signers, powers);
  }

  function guardianBridge() external onlyGuardian {
    _bridgeFeesAndDistribute();
  }
}
