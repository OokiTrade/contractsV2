// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

interface IstMATICRateProvider {
  function getRate() external view returns (uint256);
}
