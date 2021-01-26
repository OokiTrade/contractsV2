/**
 * Copyright 2017-2021, bZeroX, LLC. All Rights Reserved.
 * Licensed under the Apache License, Version 2.0.
 */

pragma solidity 0.5.17;

import "./StakingUpgradeable.sol";
import "../openzeppelin/Address.sol";


contract StakingProxy is StakingUpgradeable {

    constructor(
        address _impl)
        public
    {
        replaceImplementation(_impl);
    }

    function()
        external
        payable
    {
        if (gasleft() <= 2300) {
            return;
        }

        address impl = implementation;

        bytes memory data = msg.data;
        assembly {
            let result := delegatecall(gas, impl, add(data, 0x20), mload(data), 0, 0)
            let size := returndatasize
            let ptr := mload(0x40)
            returndatacopy(ptr, 0, size)
            switch result
            case 0 { revert(ptr, size) }
            default { return(ptr, size) }
        }
    }

    function replaceImplementation(
        address impl)
        public
        onlyOwner
    {
        require(Address.isContract(impl), "not a contract");
        implementation = impl;
    }
}
