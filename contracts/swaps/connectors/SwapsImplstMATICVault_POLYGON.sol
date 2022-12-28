/**
 * Copyright 2017-2023, OokiDao. All Rights Reserved.
 * Licensed under the Apache License, Version 2.0.
 */

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

import "contracts/core/State.sol";
import "contracts/swaps/ISwapsImpl.sol";
import "@openzeppelin-4.8.0/token/ERC20/utils/SafeERC20.sol";
import "contracts/interfaces/IBalancerVault.sol";
import "contracts/interfaces/IBalancerHelpers.sol";

//Added because of version issues.. TODO
interface IVault {
  function deposit(uint256 assets, address receiver) external returns (uint256 shares);

  function redeem(
    uint256 shares,
    address receiver,
    address owner
  ) external returns (uint256 assets);

  function convertAssetsToShares(uint256 assets, address receiver) external view returns (uint256 shares);

  function convertSharesToAssets(uint256 shares, address receiver) external view returns (uint256 assets);
}

contract SwapsImplstMATICVault_POLYGON is State, ISwapsImpl {
  using SafeERC20 for IERC20;

  address public constant WMATIC = 0x0d500B1d8E8eF31E21C99d1Db9A6444d3ADf1270;
  address public constant STMATIC = 0x3A58a54C066FdC0f2D55FC9C89F0415C92eBf3C4;

  address internal constant _vault = 0xBA12222222228d8Ba445958a75a0704d566BF2C8;

  bytes32 public constant POOLID = 0xaf5e0b5425de1f5a630a8cb5aa9d97b8141c908d000200000000000000000366;

  IBalancerHelpers public constant HELPER = IBalancerHelpers(0x239e55F427D44C3cc793f49bFB507ebe76638a2b);

  IVault public constant VAULT = IVault(0x976f31D12df9272f10c2f20BE2887824Cc3d974c);
  address public constant ASSET = 0xaF5E0B5425dE1F5a630A8cB5AA9D97B8141C908D;

  constructor(
    IWeth wethtoken,
    address usdc,
    address bzrx,
    address vbzrx,
    address ooki
  ) Constants(wethtoken, usdc, bzrx, vbzrx, ooki) {}

  function dexSwap(
    address sourceTokenAddress,
    address destTokenAddress,
    address receiverAddress,
    address returnToSenderAddress,
    uint256 minSourceTokenAmount,
    uint256 maxSourceTokenAmount,
    uint256 requiredDestTokenAmount,
    bytes memory payload
  ) public returns (uint256 destTokenAmountReceived, uint256 sourceTokenAmountUsed) {
    require(sourceTokenAddress != destTokenAddress, "source == dest");
    require((sourceTokenAddress == WMATIC || sourceTokenAddress == address(VAULT)) && (destTokenAddress == WMATIC || destTokenAddress == address(VAULT)), "unsupported tokens");

    IERC20 sourceToken = IERC20(sourceTokenAddress);
    address _thisAddress = address(this);
    (sourceTokenAmountUsed, destTokenAmountReceived) = _swap(
      sourceTokenAddress,
      destTokenAddress,
      receiverAddress,
      minSourceTokenAmount,
      maxSourceTokenAmount,
      requiredDestTokenAmount,
      payload
    );

    if (returnToSenderAddress != _thisAddress && sourceTokenAmountUsed < maxSourceTokenAmount) {
      // send unused source token back
      sourceToken.safeTransfer(returnToSenderAddress, maxSourceTokenAmount - sourceTokenAmountUsed);
    }
  }

  function dexExpectedRate(
    address sourceTokenAddress,
    address destTokenAddress,
    uint256 sourceTokenAmount
  ) public view returns (uint256 expectedRate) {
    revert("unsupported");
  }

  function dexAmountOut(bytes memory payload, uint256 amountIn) public returns (uint256 amountOut, address midToken) {
    if (amountIn != 0) {
      (uint256 limiter, address sourceToken) = abi.decode(payload, (uint256, address));
      if (sourceToken == WMATIC) {
        uint256 joinKind = 1;
        uint256[] memory values = new uint256[](2);
        values[0] = amountIn;
        values[1] = 0;
        address[] memory addrs = new address[](2);
        addrs[0] = WMATIC;
        addrs[1] = STMATIC;
        IBalancerHelpers.JoinPoolRequest memory req = IBalancerHelpers.JoinPoolRequest({
          assets: addrs,
          maxAmountsIn: values,
          userData: abi.encode(joinKind, values, limiter),
          fromInternalBalance: false
        });
        (amountOut, ) = HELPER.queryJoin(POOLID, address(this), address(this), req);
        amountOut = VAULT.convertAssetsToShares(amountOut, address(this));
      } else {
        amountIn = VAULT.convertSharesToAssets(amountIn, address(this));
        uint256 exitKind = 0;
        uint256[] memory values = new uint256[](2);
        values[0] = limiter;
        values[1] = 0;
        address[] memory addrs = new address[](2);
        addrs[0] = WMATIC;
        addrs[1] = STMATIC;
        IBalancerHelpers.ExitPoolRequest memory req = IBalancerHelpers.ExitPoolRequest({
          assets: addrs,
          minAmountsOut: values,
          userData: abi.encode(exitKind, amountIn, 0),
          toInternalBalance: false
        });
        (, uint256[] memory amountsOut) = HELPER.queryExit(POOLID, address(this), address(this), req);
        amountOut = amountsOut[0];
      }
    }
  }

  function dexAmountOutFormatted(bytes memory payload, uint256 amountIn) public returns (uint256 amountOut, address midToken) {
    return dexAmountOut(payload, amountIn);
  }

  function dexAmountIn(bytes memory route, uint256 amountOut) public returns (uint256 amountIn, address midToken) {
    revert("unsupported");
  }

  function dexAmountInFormatted(bytes memory payload, uint256 amountOut) public returns (uint256 amountIn, address midToken) {
    revert("unsupported");
  }

  function setSwapApprovals(
    address[] memory /*tokens*/
  ) public {
    IERC20(WMATIC).safeApprove(_vault, 0);
    IERC20(WMATIC).safeApprove(_vault, type(uint256).max);

    IERC20(ASSET).safeApprove(address(VAULT), 0);
    IERC20(ASSET).safeApprove(address(VAULT), type(uint256).max);

    IERC20(ASSET).safeApprove(_vault, 0);
    IERC20(ASSET).safeApprove(_vault, type(uint256).max);
  }

  function revokeApprovals(
    address[] memory /*tokens*/
  ) public {
    IERC20(WMATIC).safeApprove(_vault, 0);
    IERC20(ASSET).safeApprove(_vault, 0);
    IERC20(ASSET).safeApprove(address(VAULT), 0);
  }

  function _swap(
    address sourceTokenAddress,
    address destTokenAddress,
    address receiverAddress,
    uint256 minSourceTokenAmount,
    uint256, /*maxSourceTokenAmount*/
    uint256 requiredDestTokenAmount,
    bytes memory payload
  ) internal returns (uint256 sourceTokenAmountUsed, uint256 destTokenAmountReceived) {
    require(requiredDestTokenAmount == 0, "required dest token amount unsupported");
    sourceTokenAmountUsed = minSourceTokenAmount;
    address _thisAddress = address(this);
    if (sourceTokenAddress == WMATIC) {
      uint256 minAmountOut = abi.decode(payload, (uint256));
      uint256[] memory values = new uint256[](2);
      values[0] = minSourceTokenAmount;
      values[1] = 0;
      address[] memory addrs = new address[](2);
      addrs[0] = WMATIC;
      addrs[1] = STMATIC;
      IBalancerVault.JoinPoolRequest memory req = IBalancerVault.JoinPoolRequest({
        assets: addrs,
        maxAmountsIn: values,
        userData: abi.encode(1, values, minAmountOut),
        fromInternalBalance: false
      });
      destTokenAmountReceived = IERC20(ASSET).balanceOf(_thisAddress);
      IBalancerVault(_vault).joinPool(POOLID, _thisAddress, _thisAddress, req);
      destTokenAmountReceived = VAULT.deposit(IERC20(ASSET).balanceOf(_thisAddress) - destTokenAmountReceived, receiverAddress);
    } else {
      minSourceTokenAmount = VAULT.redeem(minSourceTokenAmount, _thisAddress, _thisAddress);
      uint256 minAmountOut = abi.decode(payload, (uint256));
      uint256[] memory values = new uint256[](2);
      values[0] = minAmountOut;
      values[1] = 0;
      address[] memory addrs = new address[](2);
      addrs[0] = WMATIC;
      addrs[1] = STMATIC;
      IBalancerVault.ExitPoolRequest memory req = IBalancerVault.ExitPoolRequest({
        assets: addrs,
        minAmountsOut: values,
        userData: abi.encode(0, minSourceTokenAmount, 0),
        toInternalBalance: false
      });
      destTokenAmountReceived = IERC20(WMATIC).balanceOf(receiverAddress);
      IBalancerVault(_vault).exitPool(POOLID, _thisAddress, payable(receiverAddress), req);
      destTokenAmountReceived = IERC20(WMATIC).balanceOf(receiverAddress) - destTokenAmountReceived;
    }
  }
}
