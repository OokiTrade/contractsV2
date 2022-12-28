/**
 * Copyright 2017-2023, OokiDao. All Rights Reserved.
 * Licensed under the Apache License, Version 2.0.
 */

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

import '../StakingStateV2.sol';
import '../../governance/PausableGuardian_0_8.sol';

contract StakingPausableGuardian is StakingStateV2, PausableGuardian_0_8 {
  function initialize(address target) external onlyOwner {
    _setTarget(this._isPaused.selector, target);
    _setTarget(this.toggleFunctionPause.selector, target);
    _setTarget(this.toggleFunctionUnPause.selector, target);
    _setTarget(this.changeGuardian.selector, target);
    _setTarget(this.getGuardian.selector, target);
  }
}
