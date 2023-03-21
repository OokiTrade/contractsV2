/**
 * Copyright 2017-2023, OokiDao. All Rights Reserved.
 * Licensed under the Apache License, Version 2.0.
 */

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

interface ICToken {
    function exchangeRateCurrent() external returns (uint256);

    function exchangeRateStored() external view returns (uint256);
}