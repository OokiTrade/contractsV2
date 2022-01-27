/**
 * Copyright 2017-2022, OokiDao. All Rights Reserved.
 * Licensed under the Apache License, Version 2.0.
 */

pragma solidity 0.5.17;

import "./IPriceFeedsExt.sol";
import "@openzeppelin-2.5.0/ownership/Ownable.sol";


// bsc: 0xfe4F0eb0A1Ad109185c9AaDE64C48ff8e928e54B
contract FixedPriceFeed is IPriceFeedsExt, Ownable {

    int256 public latestAnswer = 10000000000;

    function setLatestAnswer(
        int256 newValue)
        external
        onlyOwner
    {
        latestAnswer = newValue;
    }
}
