/**
 * Copyright 2017-2021, bZeroX, LLC <https://bzx.network/>. All Rights Reserved.
 * Licensed under the Apache License, Version 2.0.
 */

// SPDX-License-Identifier: APACHE 2.0

pragma solidity >=0.6.0 <0.8.0;

import "../TraderCompensation.sol";


contract TraderCompensationMock is TraderCompensation {

    uint256 public currentTime;

    constructor(
        uint256 _optinDuration,
        uint256 _claimDuration)
        TraderCompensation(_optinDuration, _claimDuration)
    {}

    function setTime(
        uint256 _time)
        public
    {
        currentTime = _time;
    }

    function _getTimestamp()
        internal
        override
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