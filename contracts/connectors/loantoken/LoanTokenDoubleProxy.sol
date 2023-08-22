/**
 * Copyright 2017-2023, OokiDao. All Rights Reserved.
 * Licensed under the Apache License, Version 2.0.
 */

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

import "@openzeppelin-4.9.3/proxy/transparent/TransparentUpgradeableProxy.sol";
import "contracts/governance/PausableGuardian_0_8.sol";

contract LoanTokenDoubleProxy is TransparentUpgradeableProxy, PausableGuardian_0_8 {
  constructor(address _logic, address _admin, bytes memory _data) TransparentUpgradeableProxy(_logic, _admin, _data) {}

  function _beforeFallback() internal virtual override pausable {
    super._beforeFallback();
  }
}
