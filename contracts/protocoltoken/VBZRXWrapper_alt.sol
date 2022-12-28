/**
 * Copyright 2017-2023, OokiDao. All Rights Reserved.
 * Licensed under the Apache License, Version 2.0.
 */

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

import '../interfaces/IVestingToken.sol';
import '../proxies/0_8/Upgradeable_0_8.sol';

contract VBZRXWrapper_alt is Upgradeable_0_8 {
  // --- ERC20 Data ---
  string public constant name = 'Wrapped vBZRX';
  string public constant symbol = 'wvBZRX';
  uint8 public constant decimals = 18;
  uint256 public totalSupply;

  IERC20 public constant BZRX = IERC20(0x56d811088235F11C8920698a204A5010a788f4b3);
  IVestingToken public constant vBZRX = IVestingToken(0xB72B31907C1C95F3650b64b2469e08EdACeE5e8F);

  mapping(address => uint256) public balanceOf;
  mapping(address => mapping(address => uint256)) public allowance;

  uint256 public bzrxVestiesPerTokenStored;
  mapping(address => uint256) public bzrxVestiesPerTokenPaid;
  mapping(address => uint256) public bzrxVesties;

  event Approval(address indexed owner, address indexed spender, uint256 value);
  event Transfer(address indexed src, address indexed dst, uint256 value);
  event Deposit(address indexed dst, uint256 value);
  event Withdraw(address indexed src, uint256 value);
  event Claim(address indexed owner, uint256 value);

  event TransferDepositBalance(address indexed src, address indexed dst, uint256 value);
  mapping(address => uint256) public depositBalanceOf;
  mapping(address => bool) public bridge;

  // --- Token ---
  function transfer(address dst, uint256 value) external returns (bool) {
    return transferFrom(msg.sender, dst, value);
  }

  function transferFrom(address src, address dst, uint256 value) public returns (bool) {
    settleVesting(src);
    settleVesting(dst);

    uint256 srcBalance = balanceOf[src];
    require(srcBalance >= value, 'vBZRXWrapper/insufficient-balance');
    if (src != msg.sender && allowance[src][msg.sender] != type(uint256).max) {
      require(allowance[src][msg.sender] >= value, 'vBZRXWrapper/insufficient-allowance');
      allowance[src][msg.sender] -= value;
    }

    if (!bridge[src] && !bridge[dst]) {
      // move proportional vesties to dst
      uint256 moveAmount = (bzrxVesties[src] * (value)) / (srcBalance);
      bzrxVesties[src] -= moveAmount;
      bzrxVesties[dst] += moveAmount;

      uint256 depositBalance = depositBalanceOf[src];
      require(value <= depositBalance, 'vBZRXWrapper/insufficient-deposit-balance');
      depositBalanceOf[src] = depositBalance - value;
      depositBalanceOf[dst] += value;
    }

    balanceOf[src] = srcBalance - value;
    balanceOf[dst] += value;
    emit Transfer(src, dst, value);
    return true;
  }

  function approve(address spender, uint256 value) external returns (bool) {
    allowance[msg.sender][spender] = value;
    emit Approval(msg.sender, spender, value);
    return true;
  }

  // --- Custom Logic ---

  function settleVesting(address account) internal {
    uint256 _bzrxVestiesPerTokenStored = bzrxVestiesPerTokenStored;
    uint256 _totalSupply = totalSupply;
    if (_totalSupply != 0) {
      uint256 balanceBefore = BZRX.balanceOf(address(this));

      vBZRX.claim();

      _bzrxVestiesPerTokenStored = ((BZRX.balanceOf(address(this)) - balanceBefore) * (1e36)) / (_totalSupply) + (_bzrxVestiesPerTokenStored);
    }

    bzrxVesties[account] = _claimable(account, _bzrxVestiesPerTokenStored);
    bzrxVestiesPerTokenStored = _bzrxVestiesPerTokenStored;
    bzrxVestiesPerTokenPaid[account] = _bzrxVestiesPerTokenStored;
  }

  function _claimable(address account, uint256 _bzrxPerToken) internal view returns (uint256 bzrxVestiesClaimable) {
    uint256 bzrxPerTokenUnpaid = _bzrxPerToken - (bzrxVestiesPerTokenPaid[account]);
    bzrxVestiesClaimable = bzrxVesties[account];
    if (bzrxPerTokenUnpaid != 0) {
      bzrxVestiesClaimable = (depositBalanceOf[account] * (bzrxPerTokenUnpaid)) / (1e36) + (bzrxVestiesClaimable);
    }
  }

  function _claim() internal returns (uint256 claimed) {
    claimed = bzrxVesties[msg.sender];
    if (claimed != 0) {
      bzrxVesties[msg.sender] = 0;
      BZRX.transfer(msg.sender, claimed);
    }
    emit Claim(msg.sender, claimed);
  }

  function claimable(address account) external view returns (uint256) {
    uint256 _totalSupply = totalSupply;
    if (_totalSupply == 0) {
      return bzrxVesties[account];
    }
    return _claimable(account, (vBZRX.vestedBalanceOf(address(this)) * (1e36)) / (_totalSupply) + (bzrxVestiesPerTokenStored));
  }

  function claim() external returns (uint256) {
    settleVesting(msg.sender);
    return _claim();
  }

  function exit() external {
    withdraw(type(uint256).max);
    _claim();
  }

  function deposit(uint256 value) external {
    require(!bridge[msg.sender], 'unauthorized');

    settleVesting(msg.sender);
    vBZRX.transferFrom(msg.sender, address(this), value);
    balanceOf[msg.sender] += value;
    totalSupply += value;

    depositBalanceOf[msg.sender] += value;

    emit Transfer(address(0), msg.sender, value);
    emit Deposit(msg.sender, value);
  }

  function withdraw(uint256 value) public {
    require(!bridge[msg.sender], 'unauthorized');

    settleVesting(msg.sender);
    uint256 balance = balanceOf[msg.sender];
    if (value > balance) {
      value = balance;
    }
    balanceOf[msg.sender] = balance - value;
    totalSupply -= value;

    uint256 depositBalance = depositBalanceOf[msg.sender];
    require(value <= depositBalance, 'vBZRXWrapper/insufficient-deposit-balance');
    depositBalanceOf[msg.sender] = depositBalance - value;

    vBZRX.transfer(msg.sender, value);
    emit Transfer(msg.sender, address(0), value);
    emit Withdraw(msg.sender, value);
  }

  function setBridge(address addr, bool toggle) external onlyOwner {
    bridge[addr] = toggle;
  }
}
