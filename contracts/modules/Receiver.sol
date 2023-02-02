/**
 * Copyright 2017-2023, OokiDao. All Rights Reserved.
 * Licensed under the Apache License, Version 2.0.
 */

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

import "contracts/core/State.sol";

contract Receiver is State {
  function initialize(address target) external onlyOwner {
    _setTarget(0, target);
  }

  fallback() external payable {}
}
