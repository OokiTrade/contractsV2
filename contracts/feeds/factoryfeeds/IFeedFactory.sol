/**
 * Copyright 2017-2023, OokiDao. All Rights Reserved.
 * Licensed under the Apache License, Version 2.0.
 */

// SPDX-License-Identifier: Apache-2.0
pragma solidity >=0.5.17 <0.9.0;

import "interfaces/IUniv3Twap.sol";

interface IFeedFactory is IUniv3Twap {
  function specs() external view returns (V3Specs memory);
}
