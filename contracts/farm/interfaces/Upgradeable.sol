/**
 * Copyright 2017-2021, bZeroX, LLC. All Rights Reserved.
 * Licensed under the Apache License, Version 2.0.
 */

// SPDX-License-Identifier: APACHE 2.0

pragma solidity >=0.6.0 <0.8.0;

import "openzeppelin-3.4.0/access/Ownable.sol";


contract Upgradeable is Ownable {
    address public implementation;
}
