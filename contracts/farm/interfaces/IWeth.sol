/**
 * Copyright 2017-2022, OokiDao. All Rights Reserved.
 * Licensed under the Apache License, Version 2.0.
 */

pragma solidity >=0.6.0 <0.7.0;


interface IWeth {
    function deposit() external payable;
    function withdraw(uint256 wad) external;
}
