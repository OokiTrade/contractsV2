// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

import '../core/State.sol';

contract Receiver is State {
  constructor(IWeth wethtoken, address usdc, address bzrx, address vbzrx, address ooki) Constants(wethtoken, usdc, bzrx, vbzrx, ooki) {}

  function initialize(address target) external onlyOwner {
    _setTarget(0, target);
  }

  fallback() external payable {}
}
