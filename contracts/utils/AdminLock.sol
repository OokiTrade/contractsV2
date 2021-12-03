/**
 * Copyright 2017-2021, OokiDao. All Rights Reserved.
 * Licensed under the Apache License, Version 2.0.
 */
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
import "@openzeppelin-4.3.2/access/Ownable.sol";
import "@openzeppelin-4.3.2/token/ERC20/utils/SafeERC20.sol";

contract AdminLock is Ownable {
    using SafeERC20 for IERC20;
    IERC20 public LOCKED_TOKEN;

    constructor(IERC20 _lokedToken) {
        LOCKED_TOKEN = IERC20(_lokedToken);
    }

    function deposit() public {
        uint256 amount = LOCKED_TOKEN.balanceOf(msg.sender);
        LOCKED_TOKEN.safeTransferFrom(msg.sender, address(this), amount);
        emit Deposited(msg.sender, amount);
    }

    function rescue(IERC20 _token) public onlyOwner {
        _token.safeTransfer(msg.sender, _token.balanceOf(address(this)));
    }

    event Deposited(address owner, uint256 amount);
}
