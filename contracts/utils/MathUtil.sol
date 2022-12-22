/**
 * Copyright 2017-2022, OokiDao. All Rights Reserved.
 * Licensed under the Apache License, Version 2.0.
 */

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

library MathUtil {
  /**
   * @dev Integer division of two numbers, rounding up and truncating the quotient
   */
  function divCeil(uint256 a, uint256 b) internal pure returns (uint256) {
    return divCeil(a, b, 'SafeMath: division by zero');
  }

  /**
   * @dev Integer division of two numbers, rounding up and truncating the quotient
   */
  function divCeil(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
    if (a == 0) {
      return 0;
    }
    uint256 c = ((a - 1) / b) + 1;

    return c;
  }

  function min256(uint256 _a, uint256 _b) internal pure returns (uint256) {
    return _a < _b ? _a : _b;
  }
}
