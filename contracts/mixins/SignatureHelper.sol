// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

contract SignatureHelper {
  function getSig(bytes calldata data) external pure returns (bytes4) {
    return bytes4(data[0:4]);
  }
}
