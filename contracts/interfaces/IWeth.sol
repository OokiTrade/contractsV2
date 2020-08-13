/**
 * Copyright 2017-2020, bZeroX, LLC. All Rights Reserved.
 * Licensed under the Apache License, Version 2.0.
 */

// SPDX-License-Identifier: GNU 
pragma solidity ^0.6.2;


interface IWeth {
    function deposit() external payable;
    function withdraw(uint256 wad) external;
}
