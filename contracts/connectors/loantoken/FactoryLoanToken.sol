// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

import './LoanToken.sol';
import '../../../interfaces/ILoanTokenFactory.sol';

contract FactoryLoanToken is LoanToken {
  address factory;

  constructor() LoanToken(msg.sender, msg.sender) {
    factory = msg.sender;
  }

  fallback() external payable override {
    if (gasleft() <= 2300) {
      return;
    }

    address target = _getTarget();
    bytes memory data = msg.data;
    require(!ILoanTokenFactory(factory).isPaused(msg.data), 'paused');
    assembly {
      let result := delegatecall(gas(), target, add(data, 0x20), mload(data), 0, 0)
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

  function _getTarget() internal override returns (address) {
    if (factory != address(0)) {
      return ILoanTokenFactory(factory).getTarget();
    } else {
      return super._getTarget();
    }
  }

  function setFactory(address newFactory) external {
    require(msg.sender == factory, 'unauthorized');
    factory = newFactory;
  }
}
