/**
 * Copyright 2017-2023, OokiDao. All Rights Reserved.
 * Licensed under the Apache License, Version 2.0.
 */

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

import '@openzeppelin-4.7.0/proxy/ERC1967/ERC1967Proxy.sol';
import '@openzeppelin-4.7.0/access/Ownable.sol';

contract OokiOwnableProxy is Ownable, ERC1967Proxy {
  fallback() external payable override {
    require(msg.value == 0);
    _fallback();
  }

  constructor(address _logic, bytes memory _data) payable ERC1967Proxy(_logic, _data) {}

  function upgradeTo(address newImplementation) public onlyOwner {
    _upgradeTo(newImplementation);
  }
}
