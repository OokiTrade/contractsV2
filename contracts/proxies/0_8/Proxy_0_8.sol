/**
 * Copyright 2017-2022, OokiDao. All Rights Reserved.
 * Licensed under the Apache License, Version 2.0.
 */

pragma solidity ^0.8.0;

import "./Upgradeable_0_8.sol";
import "@openzeppelin-4.3.2/utils/Address.sol";

contract Proxy_0_8 is Upgradeable_0_8 {
    constructor(address _impl) payable {
        replaceImplementation(_impl);
    }

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
            case 0 { revert(ptr, size) }
            default { return(ptr, size) }
        }
    }

    function replaceImplementation(address impl) public onlyOwner {
        require(Address.isContract(impl), "not a contract");
        implementation = impl;
    }
}
