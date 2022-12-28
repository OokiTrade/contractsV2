// SPDX-License-Identifier: Apache-2.0
pragma solidity >=0.5.17 <0.9.0;

interface IyVault {
  function pricePerShare() external view returns (uint256);
}
