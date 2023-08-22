/**
 * Copyright 2017-2023, OokiDao. All Rights Reserved.
 * Licensed under the Apache License, Version 2.0.
 */

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

import "@openzeppelin-4.9.3/access/Ownable.sol";
import "interfaces/IDexRecords.sol";

contract DexRecords is Ownable, IDexRecords {
  mapping(uint256 => address) public dexes;
  uint256 public dexCount = 0;

  function retrieveDexAddress(uint256 number) public view returns (address) {
    require(dexes[number] != address(0), "DexRecords: No implementation set");
    return dexes[number];
  }

  function setDexID(address dex) public onlyOwner {
    dexes[++dexCount] = dex;
  }

  function setDexID(uint256 ID, address dex) public onlyOwner {
    dexes[ID] = dex;
  }
}
