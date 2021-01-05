/**
 * Copyright 2017-2021, bZeroX, LLC <https://bzx.network/>. All Rights Reserved.
 * Licensed under the Apache License, Version 2.0.
 */

pragma solidity 0.5.17;

import "../BZRXv1Converter.sol";


contract BZRXv1ConverterMock is BZRXv1Converter {

    uint256 public currentTime;

    /*constructor(
        IERC20 _BZRXv1,
        IERC20 _BZRX)
        BZRXv1Converter(_BZRXv1, _BZRX)
        public
    {}*/

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