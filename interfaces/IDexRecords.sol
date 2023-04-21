// SPDX-License-Identifier: Apache-2.0
pragma solidity >=0.5.17 <0.9.0;

interface IDexRecords {
  function retrieveDexAddress(uint256 dexNumber) external view returns (address);

  function setDexID(address dexAddress) external;

  function setDexID(uint256 dexID, address dexAddress) external;

  function dexCount() external view returns (uint256);
}
