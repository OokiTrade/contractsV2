// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

import '@openzeppelin-4.7.0/access/Ownable.sol';

contract DexRecords is Ownable {
  mapping(uint256 => address) public dexes;
  uint256 public dexCount = 0;

  function retrieveDexAddress(uint256 number) public view returns (address) {
    require(dexes[number] != address(0), 'DexRecords: No implementation set');
    return dexes[number];
  }

  function setDexID(address dex) public onlyOwner {
    dexes[++dexCount] = dex;
  }

  function setDexID(uint256 ID, address dex) public onlyOwner {
    dexes[ID] = dex;
  }

  function getDexCount() external view returns (uint256) {
    return dexCount;
  }
}
