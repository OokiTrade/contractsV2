/**
 * Copyright 2017-2021, bZeroX, LLC. All Rights Reserved.
 * Licensed under the Apache License, Version 2.0.
 */

// SPDX-License-Identifier: APACHE 2.0

pragma solidity >=0.6.0 <0.8.0;



import "./Upgradeable_0_5.sol";


contract Proxy_0_5 is Upgradeable_0_5 {

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
        require(isContract(impl), "not a contract");
        implementation = impl;
    }

    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
        return size > 0;
    }

}
