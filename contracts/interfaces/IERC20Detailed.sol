/**
 * Copyright 2017-2022, OokiDao. All Rights Reserved.
 * Licensed under the Apache License, Version 2.0.
 */

// SPDX-License-Identifier: Apache-2.0

pragma solidity >=0.5.0 <0.8.0;


// optional functions from IERC20 not inheriting since old solidity version
interface IERC20Detailed {
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
}
