/**
 * Copyright 2017-2021, bZeroX, LLC <https://bzx.network/>. All Rights Reserved.
 * Licensed under the Apache License, Version 2.0.
 */

pragma solidity 0.5.17;
pragma experimental ABIEncoderV2;

import "../interim/StakingInterim.sol";


contract StakingInterimMock is StakingInterim {

    uint256 public currentTime;

    function setTime(
        uint256 _time)
        public
    {
        currentTime = _time;
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