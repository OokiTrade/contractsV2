/**
 * Copyright 2017-2023, OokiDao. All Rights Reserved.
 * Licensed under the Apache License, Version 2.0.
 */

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

contract SignatureHelper {
  function getSig(bytes calldata data) external pure returns (bytes4) {
    return bytes4(data[0:4]);
  }
}
