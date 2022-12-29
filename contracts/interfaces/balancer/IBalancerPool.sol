// SPDX-License-Identifier: Apache-2.0
pragma solidity >=0.5.17 <0.9.0;

interface IBalancerPool {
  function getRate() external view returns (uint256);

  function getLatest(uint8 variable) external view returns (uint256);

  /**
   * @dev Returns the time average weighted price corresponding to each of `queries`. Prices are represented as 18
   * decimal fixed point values.
   */
  function getTimeWeightedAverage(OracleAverageQuery[] memory queries) external view returns (uint256[] memory results);

  struct OracleAverageQuery {
    uint8 variable;
    uint256 secs;
    uint256 ago;
  }
}
