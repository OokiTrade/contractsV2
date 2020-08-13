/**
 * Copyright 2017-2020, bZeroX, LLC. All Rights Reserved.
 * Licensed under the Apache License, Version 2.0.
 */

// SPDX-License-Identifier: GNU 
pragma solidity ^0.6.2;

import "./IERC20.sol";


interface IPot {
    function dsr()
        external
        view
        returns (uint256);

    function chi()
        external
        view
        returns (uint256);

    function rho()
        external
        view
        returns (uint256);
}

contract IChai is IERC20 {
    function move(
        address src,
        address dst,
        uint256 wad)
        external
        returns (bool);

    function join(
        address dst,
        uint256 wad)
        external;

    function draw(
        address src,
        uint256 wad)
        external;

    function exit(
        address src,
        uint wad)
        external;
}
