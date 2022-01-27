/**
 * Copyright 2017-2022, OokiDao. All Rights Reserved.
 * Licensed under the Apache License, Version 2.0.
 */

// SPDX-License-Identifier: Apache-2.0

pragma solidity >=0.6.0 <0.8.0;

import "@openzeppelin-3.4.0/token/ERC20/IERC20.sol";

interface IERC20Mintable is IERC20 {
    function mint(address _to, uint256 _amount) external;
}
