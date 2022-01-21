/**
 * Copyright 2017-2022, OokiDao. All Rights Reserved.
 * Licensed under the Apache License, Version 2.0.
 */

pragma solidity 0.5.17;

import "../BZRXVestingToken.sol";


contract BZRXVestingTokenMock is BZRXVestingToken {

    uint256 public currentBlock;
    uint256 public currentTime;

    /*constructor(
        IERC20 _BZRX)
        BZRXVestingToken(_BZRX)
        public
    {}*/

    function withdrawAll()
        public
    {
        BZRX.transfer(
            msg.sender,
            BZRX.balanceOf(address(this))
        );
    }

    function setBlock(
        uint256 _block)
        public
    {
        currentBlock = _block;
    }

    function setTime(
        uint256 _time)
        public
    {
        currentTime = _time;
    }

    function _getBlockNumber()
        internal
        view
        returns (uint256)
    {
        if (currentBlock != 0) {
            return currentBlock;
        } else {
            return block.number;
        }
    }

    function _getTimestamp()
        internal
        view
        returns (uint256)
    {
        if (currentTime != 0) {
            return currentTime;
        } else {
            return block.timestamp;
        }
    }
}