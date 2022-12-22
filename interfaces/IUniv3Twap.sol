// SPDX-License-Identifier: Apache-2.0
pragma solidity >=0.6.12;
pragma experimental ABIEncoderV2;

interface IUniv3Twap {
  struct V3Specs {
    address token0;
    address token1;
    address pool;
    uint128 baseAmount;
    uint32 secondsAgo;
  }

  function twapValue(
    V3Specs memory specs
  ) external view returns (uint256 quoteAmount);
}
