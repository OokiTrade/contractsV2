/**
 * Copyright 2017-2023, OokiDao. All Rights Reserved.
 * Licensed under the Apache License, Version 2.0.
 */

// SPDX-License-Identifier: Apache-2.0
pragma solidity >=0.5.17 <0.9.0;

//0xbFcF63294aD7105dEa65aA58F8AE5BE2D9d0952A eth mainnet
interface ICurvePoolGauge {
  function balanceOf(address _addr) external view returns (uint256);

  function working_balances(address) external view returns (uint256);

  function claimable_tokens(address) external returns (uint256);

  function deposit(uint256 _amount) external;

  function deposit(uint256 _amount, address _addr) external;

  function withdraw(uint256 _amount) external;

  function set_approve_deposit(address _addr, bool can_deposit) external;
}