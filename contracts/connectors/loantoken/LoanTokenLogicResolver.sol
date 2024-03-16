/**
 * Copyright 2017-2023, OokiDao. All Rights Reserved.
 * Licensed under the Apache License, Version 2.0.
 */

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

import "contracts/governance/PausableGuardian_0_8.sol";

contract LoanTokenLogicResolver is PausableGuardian_0_8 {
  address public implementation;

  fallback() external payable {
    if (gasleft() <= 2300) {
      return;
    }

    address impl = implementation;

    bytes memory data = msg.data;
    assembly {
      let result := delegatecall(gas(), impl, add(data, 0x20), mload(data), 0, 0)
      let size := returndatasize()
      let ptr := mload(0x40)
      returndatacopy(ptr, 0, size)
      switch result
      case 0 {
        revert(ptr, size)
      }
      default {
        return(ptr, size)
      }
    }
  }

  function setImplementation(address newImplementation) external onlyOwner {
    implementation = newImplementation;
  }
}
