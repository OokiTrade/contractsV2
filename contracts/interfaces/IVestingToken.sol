/**
 * Copyright 2017-2023, OokiDao. All Rights Reserved.
 * Licensed under the Apache License, Version 2.0.
 */

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

import '@openzeppelin-4.8.0/token/ERC20/utils/SafeERC20.sol';

interface IVestingToken is IERC20 {
  function claim() external;

  function vestedBalanceOf(address _owner) external view returns (uint256);

  function claimedBalanceOf(address _owner) external view returns (uint256);
}
