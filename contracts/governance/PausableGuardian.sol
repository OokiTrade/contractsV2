/**
 * Copyright 2017-2021, bZeroX, LLC. All Rights Reserved.
 * Licensed under the Apache License, Version 2.0.
 */

pragma solidity 0.5.17;

import "@openzeppelin-2.5.0/ownership/Ownable.sol";

contract PausableGuardian is Ownable {
    // keccak256("Pausable_FunctionPause")
    bytes32 internal constant Pausable_FunctionPause = 0xa7143c84d793a15503da6f19bf9119a2dac94448ca45d77c8bf08f57b2e91047;
    // keccak256("Pausable_GuardianAddress")
    bytes32 internal constant Pausable_GuardianAddress = 0x80e6706973d0c59541550537fd6a33b971efad732635e6c3b99fb01006803cdf;

    modifier pausable(bytes4 sig) {
        require(!_isPaused(sig), "paused");
        _;
    }

    function _isPaused(bytes4 sig) public view returns (bool isPaused) {
        bytes32 slot = keccak256(abi.encodePacked(sig, Pausable_FunctionPause));
        assembly {
            isPaused := sload(slot)
        }
    }

    function toggleFunctionPause(bytes4 sig) public {
        require(msg.sender == getGuardian() || msg.sender == owner(), "unauthorized");
        bytes32 slot = keccak256(abi.encodePacked(sig, Pausable_FunctionPause));
        bool isPaused = true;
        assembly {
            sstore(slot, isPaused)
        }
    }

    function toggleFunctionUnPause(bytes4 sig) public {
        // only DAO can unpause
        require(msg.sender == owner(), "unauthorized");
        bytes32 slot = keccak256(abi.encodePacked(sig, Pausable_FunctionPause));
        bool isPaused = false;
        assembly {
            sstore(slot, isPaused)
        }
    }

    function changeGuardian(address newGuardian) public {
        require(msg.sender == getGuardian() || msg.sender == owner(), "unauthorized");
        bytes32 slot = keccak256(abi.encodePacked(Pausable_GuardianAddress));
        assembly {
            sstore(slot, newGuardian)
        }
    }

    function getGuardian() public view returns (address guardian) {
        bytes32 slot = keccak256(abi.encodePacked(Pausable_GuardianAddress));
        assembly {
            guardian := sload(slot)
        }
    }
}
