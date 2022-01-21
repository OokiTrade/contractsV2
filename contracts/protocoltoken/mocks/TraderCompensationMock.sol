/**
 * Copyright 2017-2022, OokiDao. All Rights Reserved.
 * Licensed under the Apache License, Version 2.0.
 */

pragma solidity 0.5.17;

import "../TraderCompensation.sol";


contract TraderCompensationMock is TraderCompensation {

    uint256 public currentTime;

    constructor(
        uint256 _optinDuration,
        uint256 _claimDuration)
        TraderCompensation(_optinDuration, _claimDuration)
        public
    {}

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