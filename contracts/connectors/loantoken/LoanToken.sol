/**
 * Copyright 2017-2022, OokiDao. All Rights Reserved.
 * Licensed under the Apache License, Version 2.0.
 */

pragma solidity 0.5.17;

import "./AdvancedTokenStorage.sol";


contract LoanToken is AdvancedTokenStorage {

    address internal target_;

    constructor(
        address _newOwner,
        address _newTarget)
        public
    {
        transferOwnership(_newOwner);
        _setTarget(_newTarget);
    }

    function()
        external
        payable
    {
        if (gasleft() <= 2300) {
            return;
        }

        address target = target_;
        bytes memory data = msg.data;
        assembly {
            let result := delegatecall(gas, target, add(data, 0x20), mload(data), 0, 0)
            let size := returndatasize
            let ptr := mload(0x40)
            returndatacopy(ptr, 0, size)
            switch result
            case 0 { revert(ptr, size) }
            default { return(ptr, size) }
        }
    }

    function setTarget(
        address _newTarget)
        public
        onlyOwner
    {
        _setTarget(_newTarget);
    }

    function _setTarget(
        address _newTarget)
        internal
    {
        require(Address.isContract(_newTarget), "target not a contract");
        target_ = _newTarget;
    }
}
