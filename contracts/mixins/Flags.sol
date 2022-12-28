/**
 * Copyright 2017-2023, OokiDao. All Rights Reserved.
 * Licensed under the Apache License, Version 2.0.
 */

// SPDX-License-Identifier: Apache-2.0
pragma solidity >=0.5.17 <0.9.0;

contract Flags {
  uint128 public constant HOLD_OOKI_FLAG = 1; // base-2: 1
  uint128 public constant DEX_SELECTOR_FLAG = 2; // base-2: 10
  uint128 public constant DELEGATE_FLAG = 4; // base-2: 100
  uint128 public constant PAY_WITH_OOKI_FLAG = 8; // base-2: 1000
  uint128 public constant WITH_PERMIT = 16; // base-2: 10000
  uint128 public constant TRACK_VOLUME_FLAG = 32; // base-2: 100000
}
