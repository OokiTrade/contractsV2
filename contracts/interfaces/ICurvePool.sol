// SPDX-License-Identifier: Apache-2.0
pragma solidity >=0.5.17 <0.9.0;

interface ICurvePool {
  function get_virtual_price() external view returns (uint256);
}
