/**
 * Copyright 2017-2021, bZeroX, LLC <https://bzx.network/>. All Rights Reserved.
 * Licensed under the Apache License, Version 2.0.
 */

// SPDX-License-Identifier: APACHE 2.0

pragma solidity >=0.6.0 <0.8.0;

import "./CheckpointingToken.sol";


contract BZRXToken is CheckpointingToken {
    using Checkpointing for Checkpointing.History;
    
    string public constant name = "bZx Protocol Token";
    string public constant symbol = "BZRX";
    uint8 public constant decimals = 18;

    uint256 internal constant totalSupply_ = 1030000000e18; // 1,030,000,000 BZRX

    constructor(
        address _to)
    {
        balancesHistory_[_to].addCheckpoint(_getBlockNumber(), totalSupply_);
        emit Transfer(address(0), _to, totalSupply_);
    }

    function totalSupply()
        public
        override
        view
        returns (uint256)
    {
        return totalSupply_;
    }
}