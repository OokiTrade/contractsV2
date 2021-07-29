/**
 * Copyright 2017-2021, bZeroX, LLC. All Rights Reserved.
 * Licensed under the Apache License, Version 2.0.
 */

// SPDX-License-Identifier: APACHE 2.0

pragma solidity >=0.6.0 <0.8.0;

import "openzeppelin-3.4.0/access/Ownable.sol";
import "../IPriceFeedsExt.sol";


contract FastGasFeedMock is IPriceFeedsExt, Ownable {

    int256 public override latestAnswer = 86000000000;

    function setLatestAnswer(
        int256 newValue)
        external
        onlyOwner
    {
        latestAnswer = newValue;
    }
}
