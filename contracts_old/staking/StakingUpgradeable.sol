/**
 * Copyright 2017-2023, OokiDao. All Rights Reserved.
 * Licensed under the Apache License, Version 2.0.
 */

// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.5.17;

import '@openzeppelin-2.5.0/ownership/Ownable.sol';

contract StakingUpgradeable is Ownable {
  address public implementation;
}