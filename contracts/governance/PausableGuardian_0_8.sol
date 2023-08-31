/**
 * Copyright 2017-2023, OokiDao. All Rights Reserved.
 * Licensed under the Apache License, Version 2.0.
 */

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;
import "@openzeppelin-4.9.3/access/AccessControl.sol";

abstract contract PausableGuardian_0_8 is AccessControl {
  // keccak256("Pausable_FunctionPause")
  bytes32 internal constant Pausable_FunctionPause = 0xa7143c84d793a15503da6f19bf9119a2dac94448ca45d77c8bf08f57b2e91047;

  // keccak256("Pausable_GuardianAddress")
  // bytes32 internal constant Pausable_GuardianAddress = 0x80e6706973d0c59541550537fd6a33b971efad732635e6c3b99fb01006803cdf;

  string internal constant UNAUTHORIZED_ERROR = "unauthorized";
  string internal constant PAUSED_ERROR = "paused";

  bytes32 public constant GUARDIAN_ROLE = keccak256("GUARDIAN_ROLE");
  bytes32 public constant TIMELOCK_ROLE = keccak256("TIMELOCK_ROLE");
  bytes32 public constant FACTORY_ROLE = keccak256("FACTORY_ROLE");

  constructor() {
    _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
  }

  modifier pausable() {
    require(!_isPaused(msg.sig) || hasRole(GUARDIAN_ROLE, _msgSender()) || hasRole(TIMELOCK_ROLE, _msgSender()), PAUSED_ERROR);
    _;
  }

  modifier onlyHasRole(bytes32 _role) {
    require(
        hasRole(_role, _msgSender()) || hasRole(TIMELOCK_ROLE, _msgSender()),
        "onlyHasRole: msg.sender does not have role"
    );
    _;
  }

  modifier hasAnyRole(bytes32 _role1, bytes32 role2) {
    require(
        hasRole(_role1, _msgSender()) || hasRole(role2, _msgSender()) || hasRole(TIMELOCK_ROLE, _msgSender()),
        "onlyHasRole: msg.sender does not have role"
    );
    _;
  }

  function _isPaused(bytes4 sig) public view returns (bool isPaused) {
    bytes32 slot = keccak256(abi.encodePacked(sig, Pausable_FunctionPause));
    assembly {
      isPaused := sload(slot)
    }
  }

  function toggleFunctionPause(bytes4 sig) onlyHasRole(GUARDIAN_ROLE) public {
    bytes32 slot = keccak256(abi.encodePacked(sig, Pausable_FunctionPause));
    assembly {
      sstore(slot, 1)
    }
  }

  function toggleFunctionUnPause(bytes4 sig) onlyHasRole(GUARDIAN_ROLE) public {
    bytes32 slot = keccak256(abi.encodePacked(sig, Pausable_FunctionPause));
    assembly {
      sstore(slot, 0)
    }
  }

  // function changeGuardian(address newGuardian) public {
  //   require(msg.sender == getGuardian(), UNAUTHORIZED_ERROR);
  //   _changeGuardian(newGuardian);
  // }

  // function _changeGuardian(address newGuardian) internal {
  //   assembly {
  //     sstore(Pausable_GuardianAddress, newGuardian)
  //   }
  // }


  // function getGuardian() public view returns (address guardian) {
  //   assembly {
  //     guardian := sload(Pausable_GuardianAddress)
  //   }
  // }
}
