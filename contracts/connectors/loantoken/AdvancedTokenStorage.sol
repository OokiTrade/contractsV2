/**
 * Copyright 2017-2022, OokiDao. All Rights Reserved.
 * Licensed under the Apache License, Version 2.0.
 */

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

import './LoanTokenBase.sol';

abstract contract AdvancedTokenStorage is LoanTokenBase {
  event Transfer(address indexed from, address indexed to, uint256 value);

  event Approval(address indexed owner, address indexed spender, uint256 value);

  event Mint(
    address indexed minter,
    uint256 tokenAmount,
    uint256 assetAmount,
    uint256 price
  );

  event Burn(
    address indexed burner,
    uint256 tokenAmount,
    uint256 assetAmount,
    uint256 price
  );

  event Deposit(
    address indexed caller,
    address indexed owner,
    uint256 assets,
    uint256 shares
  );

  event Withdraw(
    address indexed caller,
    address indexed receiver,
    address indexed owner,
    uint256 assets,
    uint256 shares
  );

  event FlashBorrow(
    address borrower,
    address target,
    address loanToken,
    uint256 loanAmount
  );

  mapping(address => uint256) internal _balances;
  mapping(address => mapping(address => uint256)) internal _allowances;
  uint256 internal _totalSupply;
}
