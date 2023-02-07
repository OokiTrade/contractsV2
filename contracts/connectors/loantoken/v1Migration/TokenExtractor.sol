/**
 * Copyright 2017-2023, OokiDao. All Rights Reserved.
 * Licensed under the Apache License, Version 2.0.
 */
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
import "@openzeppelin-4.7.0/token/ERC20/IERC20.sol";
import "@openzeppelin-4.7.0/token/ERC20/utils/SafeERC20.sol";

contract TokenExtractor {
    using SafeERC20 for IERC20;
    function withdraw(address _token, address _to, uint256 _amount) public {
            IERC20(_token).safeTransfer(_to,_amount);
    }
}