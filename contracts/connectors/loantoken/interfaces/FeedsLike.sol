/**
 * Copyright 2017-2020, bZeroX, LLC. All Rights Reserved.
 * Licensed under the Apache License, Version 2.0.
 */

// SPDX-License-Identifier: GNU 
pragma solidity 0.6.12;


interface FeedsLike {
    function queryRate(
        address sourceTokenAddress,
        address destTokenAddress)
        external
        view
        returns (uint256 rate, uint256 precision);
}
