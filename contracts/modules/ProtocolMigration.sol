/**
 * Copyright 2017-2020, bZeroX, LLC. All Rights Reserved.
 * Licensed under the Apache License, Version 2.0.
 */

pragma solidity 0.5.17;
pragma experimental ABIEncoderV2;

import "../core/State.sol";


contract ProtocolMigration is State {

    constructor() public {}

    function()
        external
    {
        revert("fallback not allowed");
    }

    function initialize(
        address target)
        external
        onlyOwner
    {
        logicTargets[this.setLegacyOracles.selector] = target;
        logicTargets[this.getLegacyOracle.selector] = target;
    }

    function setLegacyOracles(
        address[] calldata refs,
        address[] calldata oracles)
        external
        onlyOwner
    {
        require(refs.length == oracles.length, "count mismatch");

        for (uint256 i = 0; i < refs.length; i++) {
            // keccak256("ProtocolMigration_LegacyOracle")
            bytes32 slot = keccak256(abi.encodePacked(refs[i], uint256(0x321954720f5981c32956ae92f635353a60cc1706b85a3871684a484badf16114)));
            address oracle = oracles[i];
            assembly {
                sstore(slot, oracle)
            }
        }
    }

    function getLegacyOracle(
        address ref)
        external
        view
        returns (address)
    {
        //keccak256("ProtocolMigration_LegacyOracle")
        bytes32 slot = keccak256(abi.encodePacked(ref, uint256(0x321954720f5981c32956ae92f635353a60cc1706b85a3871684a484badf16114)));
        address oracle;
        assembly {
            oracle := sload(slot)
        }
        return oracle;
    }
}