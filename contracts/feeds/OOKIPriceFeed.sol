/**
 * Copyright 2017-2023, OokiDao. All Rights Reserved.
 * Licensed under the Apache License, Version 2.0.
 */

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

import "contracts/feeds/IPriceFeedsExt.sol";
import "contracts/governance/PausableGuardian_0_8.sol";

contract OOKIPriceFeed is PausableGuardian_0_8, IPriceFeedsExt {
  int256 public storedPrice = 2e6; // $0.02

  function updateStoredPrice(int256 price) external onlyHasRole(GUARDIAN_ROLE) {
    storedPrice = price;
  }

  function latestAnswer() external view returns (int256) {
    return storedPrice;
  }
}
