/**
 * Copyright 2017-2023, OokiDao. All Rights Reserved.
 * Licensed under the Apache License, Version 2.0.
 */

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

import '../../interfaces/ICurvedInterestRate.sol';

contract StorageExtension {
  address internal target_;
  uint256 public flashBorrowFeePercent; // set to 0.03%
  ICurvedInterestRate rateHelper;
}
