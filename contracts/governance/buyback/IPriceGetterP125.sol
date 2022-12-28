/**
 * Copyright 2017-2023, OokiDao. All Rights Reserved.
 * Licensed under the Apache License, Version 2.0.
 */

// SPDX-License-Identifier: Apache-2.0
pragma solidity >=0.5.17 <0.9.0;
pragma experimental ABIEncoderV2;

interface IPriceGetterP125 {
  struct V3Specs {
    address token0;
    address token1;
    address pool;
    uint128 baseAmount;
    uint32 secondsAgo;
    bytes route;
  }

  function worstExecPrice(V3Specs memory specs) external view returns (uint256 quoteAmount);
}
