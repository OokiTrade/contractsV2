/**
 * Copyright 2017-2022, OokiDao. All Rights Reserved.
 * Licensed under the Apache License, Version 2.0.
 */

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

import '@openzeppelin-4.7.0/access/Ownable.sol';

contract VoteDelegationUpgradeable is Ownable {
  address public implementation;
}
