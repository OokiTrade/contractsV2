/**
 * Copyright 2017-2021, OokiDao. All Rights Reserved.
 * Licensed under the Apache License, Version 2.0.
 */
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
import "@openzeppelin-4.3.2/access/Ownable.sol";

contract AdminLock is Ownable {
 
    function rescue(IERC20 _token) public onlyOwner {
        _token.safeTransfer(msg.sender, _token.balanceOf(address(this)));
    }
}
