/**
 * Copyright 2017-2021, bZeroX, LLC <https://bzx.network/>. All Rights Reserved.
 * Licensed under the Apache License, Version 2.0.
 */

pragma solidity 0.5.17;

import "../BZRXToken.sol";


contract BZRXTokenMock is BZRXToken {

    uint256 public currentBlock;

    constructor()
        BZRXToken(msg.sender)
        public
    {}

    function setBlock(
        uint256 _block)
        public
    {
        currentBlock = _block;
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
}