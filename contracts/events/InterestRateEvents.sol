/**
 * Copyright 2017-2022, OokiDao. All Rights Reserved.
 * Licensed under the Apache License, Version 2.0.
 */

pragma solidity 0.5.17;


contract InterestRateEvents {

    event InterestRateVals(
        address indexed pool,
        uint256[7] interestRate
    );
}