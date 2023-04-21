/**
 * Copyright 2017-2023, OokiDao. All Rights Reserved.
 * Licensed under the Apache License, Version 2.0.
 */

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

import "contracts/interfaces/IVault.sol";
import "@openzeppelin-4.8.3/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin-4.8.3/token/ERC20/ERC20.sol";
import "contracts/interfaces/balancer/IBalancerGauge.sol";
import "contracts/interfaces/balancer/IBalancerVault.sol";
import "contracts/interfaces/balancer/IBalancerPool.sol";
import "interfaces/IPriceFeeds.sol";

contract bStablestMATICVault is ERC20, IVault {
  using SafeERC20 for IERC20;

  uint256 public override totalAssets;
  address public constant override asset = 0xaF5E0B5425dE1F5a630A8cB5AA9D97B8141C908D;

  uint256 internal _sharePrice = 1e18;

  address internal constant _BSTABLEGAUGE = 0x9928340f9E1aaAd7dF1D95E27bd9A5c715202a56;
  address internal constant _VAULT = 0xBA12222222228d8Ba445958a75a0704d566BF2C8;

  address public constant BAL = 0x9a71012B13CA4d3D0Cdc72A177DF3ef03b0E76A3;

  bytes32 public constant POOLID = 0xaf5e0b5425de1f5a630a8cb5aa9d97b8141c908d000200000000000000000366;
  address public constant WMATIC = 0x0d500B1d8E8eF31E21C99d1Db9A6444d3ADf1270;
  address public constant STMATIC = 0x3A58a54C066FdC0f2D55FC9C89F0415C92eBf3C4;
  address public constant USDC = 0x2791Bca1f2de4661ED88A30C99A7a9449Aa84174;

  bytes32 public constant POOLIDSWAP = 0x0297e37f1873d2dab4487aa67cd56b58e2f27875000100000000000000000002;

  address public constant PRICEFEED = 0x600F8E7B10CF6DA18871Ff79e4A61B13caCEd9BC;

  IBalancerVault.FundManagement internal _funds =
    IBalancerVault.FundManagement({sender: address(this), fromInternalBalance: false, recipient: payable(address(uint160(address(this)))), toInternalBalance: false});

  IBalancerVault.FundManagement internal _feeFunds =
    IBalancerVault.FundManagement({
      sender: address(this),
      fromInternalBalance: false,
      recipient: payable(0x8c02eDeE0c759df83e31861d11E6918Dd93427d2), //fee distributor
      toInternalBalance: false
    });

  constructor() ERC20("bStable-stMATIC/MATIC-Vault", "OVault") {}

  function convertToShares(uint256 assets) public view override returns (uint256 shares) {
    return (assets * 1e18) / _sharePrice;
  }

  function convertToAssets(uint256 shares) public view override returns (uint256 assets) {
    return (shares * _sharePrice) / 1e18;
  }

  function maxDeposit(address receiver) external view override returns (uint256) {
    return type(uint256).max;
  }

  //Note: Due to how compounding works with Balancer, the share amount will likely be overstated; however, there is no loss of funds as the share price will increase with it
  function previewDeposit(uint256 assets) public view override returns (uint256) {
    return convertToShares(assets);
  }

  function deposit(uint256 assets, address receiver) external override returns (uint256 shares) {
    compound();
    IERC20(asset).safeTransferFrom(msg.sender, address(this), assets);
    shares = convertToShares(assets);
    IBalancerGauge(_BSTABLEGAUGE).deposit(assets);
    _mint(receiver, shares);
    emit Deposit(msg.sender, receiver, assets, shares);
  }

  function maxMint(address receiver) external view override returns (uint256) {
    return type(uint256).max;
  }

  //Note: Due to how compounding works with Balancer, the asset amount will likely be understated; however, there is no loss of funds as the share price will increase with it
  function previewMint(uint256 shares) external view override returns (uint256 assets) {
    return convertToAssets(shares);
  }

  function mint(uint256 shares, address receiver) external override returns (uint256 assets) {
    compound();
    assets = convertToAssets(shares);
    IERC20(asset).safeTransferFrom(msg.sender, address(this), assets);
    IBalancerGauge(_BSTABLEGAUGE).deposit(assets);
    _mint(receiver, shares);
    emit Deposit(msg.sender, receiver, assets, shares);
  }

  function maxWithdraw(address owner) external view override returns (uint256) {
    return convertToAssets(balanceOf(owner));
  }

  function previewWithdraw(uint256 assets) external view override returns (uint256) {
    return convertToShares(assets);
  }

  function withdraw(
    uint256 assets,
    address receiver,
    address owner
  ) external override returns (uint256 shares) {
    require(msg.sender == owner, "unauthorized");
    compound();
    shares = convertToShares(assets);
    _burn(owner, shares);
    IBalancerGauge(_BSTABLEGAUGE).withdraw(assets);
    IERC20(asset).transfer(receiver, assets);

    emit Withdraw(msg.sender, receiver, owner, assets, shares);
  }

  function maxRedeem(address owner) external view override returns (uint256) {
    return balanceOf(owner);
  }

  function previewRedeem(uint256 shares) external view override returns (uint256) {
    return convertToAssets(shares);
  }

  function redeem(
    uint256 shares,
    address receiver,
    address owner
  ) external override returns (uint256 assets) {
    require(msg.sender == owner, "unauthorized");
    compound();
    assets = convertToAssets(shares);
    _burn(owner, shares);
    IBalancerGauge(_BSTABLEGAUGE).withdraw(assets);
    IERC20(asset).transfer(receiver, assets);

    emit Withdraw(msg.sender, receiver, owner, assets, shares);
  }

  function setApprovals() public {
    IERC20(BAL).safeApprove(_VAULT, 0);
    IERC20(BAL).safeApprove(_VAULT, type(uint256).max);

    IERC20(WMATIC).safeApprove(_VAULT, 0);
    IERC20(WMATIC).safeApprove(_VAULT, type(uint256).max);

    IERC20(asset).safeApprove(_BSTABLEGAUGE, 0);
    IERC20(asset).safeApprove(_BSTABLEGAUGE, type(uint256).max);
  }

  function compound() public override {
    uint256 rateForConversion = IBalancerPool(asset).getLatest(0);
    if (rateForConversion > 102e16 || rateForConversion < 98e16) return; //silently return if rate from reference rate is > 2% difference. Acts as manipulation protection
    uint256 tokensClaimed = IBalancerGauge(_BSTABLEGAUGE).claimable_reward_write(address(this), BAL);
    IBalancerGauge(_BSTABLEGAUGE).claim_rewards();
    if (tokensClaimed == 0) return;
    bytes memory blank;
    uint256 feeAmount = tokensClaimed / 10;
    tokensClaimed -= feeAmount;
    IBalancerVault.SingleSwap memory swapParams = IBalancerVault.SingleSwap({
      poolId: POOLIDSWAP,
      kind: IBalancerVault.SwapKind.GIVEN_IN,
      assetIn: BAL,
      assetOut: WMATIC,
      amount: tokensClaimed,
      userData: blank
    });

    uint256 minAmountOut = (IPriceFeeds(PRICEFEED).queryReturn(BAL, WMATIC, tokensClaimed) * 985) / 1000;
    uint256 swapReceived = IBalancerVault(_VAULT).swap(swapParams, _funds, minAmountOut, block.timestamp);
    swapParams = IBalancerVault.SingleSwap({poolId: POOLIDSWAP, kind: IBalancerVault.SwapKind.GIVEN_IN, assetIn: BAL, assetOut: USDC, amount: feeAmount, userData: blank});
    minAmountOut = (IPriceFeeds(PRICEFEED).queryReturn(BAL, USDC, feeAmount) * 985) / 1000;
    IBalancerVault(_VAULT).swap(swapParams, _feeFunds, minAmountOut, block.timestamp);
    uint256 joinKind = 1;
    uint256[] memory values = new uint256[](2);
    values[0] = swapReceived;
    values[1] = 0;
    address[] memory addrs = new address[](2);
    addrs[0] = WMATIC;
    addrs[1] = STMATIC;
    minAmountOut = (IPriceFeeds(PRICEFEED).queryReturn(WMATIC, asset, swapReceived) * 985) / 1000;
    IBalancerVault.JoinPoolRequest memory req = IBalancerVault.JoinPoolRequest({
      assets: addrs,
      maxAmountsIn: values,
      userData: abi.encode(joinKind, values, minAmountOut),
      fromInternalBalance: false
    });
    IBalancerVault(_VAULT).joinPool(POOLID, address(this), address(this), req);
    IBalancerGauge(_BSTABLEGAUGE).deposit(IERC20(asset).balanceOf(address(this)));
    _sharePrice = (IERC20(_BSTABLEGAUGE).balanceOf(address(this)) * 1e18) / totalSupply();
  }
}
