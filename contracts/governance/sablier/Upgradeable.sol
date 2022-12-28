/**
 * Copyright 2017-2023, OokiDao. All Rights Reserved.
 * Licensed under the Apache License, Version 2.0.
 */

// SPDX-License-Identifier: Apache-2.0
pragma solidity >=0.6.0 <0.7.0;

import '@openzeppelin-3.4.0/access/Ownable.sol';

contract Upgradeable is Ownable {
  address public implementation;
}
