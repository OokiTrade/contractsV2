/**
 * Copyright 2017-2021, bZeroX, LLC. All Rights Reserved.
 * Licensed under the Apache License, Version 2.0.
 */

// SPDX-License-Identifier: APACHE 2.0


pragma solidity >=0.6.0 <0.8.0;

import "openzeppelin-3.4.0/access/Ownable.sol";



contract HelperProxy is Ownable {

    address public implementation;

    constructor(address _impl) payable {
        replaceImplementation(_impl);
    }

    fallback() external payable {
        _fallback();
    }
    receive() external payable {
        _fallback();
    }
    function _fallback() internal {
        if (gasleft() <= 2300) {
            return;
        }

        address impl = implementation;

        assembly {
            calldatacopy(0, 0, calldatasize())
            let result := delegatecall(gas(), impl, 0, calldatasize(), 0, 0)

            returndatacopy(0, 0, returndatasize())

            switch result
            case 0 { revert(0, returndatasize()) }
            default { return(0, returndatasize()) }
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
