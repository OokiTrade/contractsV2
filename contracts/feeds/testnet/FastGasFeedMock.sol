/**
 * Copyright 2017-2021, bZeroX, LLC. All Rights Reserved.
 * Licensed under the Apache License, Version 2.0.
 */

pragma solidity 0.5.17;

import "../../openzeppelin/Ownable.sol";
import "../IPriceFeedsExt.sol";


contract FastGasFeedMock is IPriceFeedsExt, Ownable {

    uint256 public latestAnswer = 86000000000;

    function setLatestAnswer(
        uint256 newValue)
        external
        onlyOwner
    {
        latestAnswer = newValue;
    }
}
