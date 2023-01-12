/**
 * Copyright 2017-2023, OokiDao. All Rights Reserved.
 * Licensed under the Apache License, Version 2.0.
 */

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

import "@openzeppelin-4.8.0/access/Ownable.sol";
import "@openzeppelin-4.8.0/utils/Address.sol";

contract HelperProxy is Ownable {
  address public implementation;

  constructor(address _impl) payable {
    replaceImplementation(_impl);
  }

  fallback() external payable {
    _fallback();
  }

  receive() external payable {
    _fallback();
  }

  function _fallback() internal {
    if (gasleft() <= 2300) {
      return;
    }

    address impl = implementation;

    assembly {
      calldatacopy(0, 0, calldatasize())
      let result := delegatecall(gas(), impl, 0, calldatasize(), 0, 0)

      returndatacopy(0, 0, returndatasize())

      switch result
      case 0 {
        revert(0, returndatasize())
      }
      default {
        return(0, returndatasize())
      }
    }
  }

  function replaceImplementation(address impl) public onlyOwner {
    require(Address.isContract(impl), "not a contract");
    implementation = impl;
  }
}
