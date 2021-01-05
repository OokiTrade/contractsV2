/**
 * Copyright 2017-2021, bZeroX, LLC <https://bzx.network/>. All Rights Reserved.
 * Licensed under the Apache License, Version 2.0.
 */

pragma solidity 0.5.17;

import "./CheckpointingToken.sol";


contract BZRXToken is CheckpointingToken {

    string public constant name = "bZx Protocol Token";
    string public constant symbol = "BZRX";
    uint8 public constant decimals = 18;

    uint256 internal constant totalSupply_ = 1030000000e18; // 1,030,000,000 BZRX

    constructor(
        address _to)
        public
    {
        balancesHistory_[_to].addCheckpoint(_getBlockNumber(), totalSupply_);
        emit Transfer(address(0), _to, totalSupply_);
    }

    function totalSupply()
        public
        view
        returns (uint256)
    {
        return totalSupply_;
    }
}