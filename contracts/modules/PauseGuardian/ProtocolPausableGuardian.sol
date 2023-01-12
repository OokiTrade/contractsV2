/**
 * Copyright 2017-2023, OokiDao. All Rights Reserved.
 * Licensed under the Apache License, Version 2.0.
 */

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

import "contracts/core/State.sol";
import "contracts/governance/PausableGuardian_0_8.sol";

contract ProtocolPausableGuardian is State, PausableGuardian_0_8 {
  constructor(
    IWeth wethtoken,
    address usdc,
    address bzrx,
    address vbzrx,
    address ooki
  ) Constants(wethtoken, usdc, bzrx, vbzrx, ooki) {}

  function initialize(address target) external onlyOwner {
    _setTarget(this._isPaused.selector, target);
    _setTarget(this.toggleFunctionPause.selector, target);
    _setTarget(this.toggleFunctionUnPause.selector, target);
    _setTarget(this.pause.selector, target);
    _setTarget(this.unpause.selector, target);
    _setTarget(this.changeGuardian.selector, target);
    _setTarget(this.getGuardian.selector, target);
  }
}
