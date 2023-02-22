/**
 * Copyright 2017-2023, OokiDao. All Rights Reserved.
 * Licensed under the Apache License, Version 2.0.
 */
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
import "@openzeppelin-4.8.0/token/ERC20/IERC20.sol";
import "@openzeppelin-4.8.0/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin-4.8.0/access/Ownable.sol";


contract ITokenV1Migrator is Ownable {
    using SafeERC20 for IERC20;
    address constant DEAD = 0x000000000000000000000000000000000000dEaD;

    //v1 address => tokenPrice
    mapping(address => uint256) public iTokenPrices;

    //v1 address => v2 address
    mapping(address => address) public iTokens;

    function setTokenPrice(address _v1itokenAddress, uint256 _v1itokenPrice, address _v2itokenAddress,  uint256 _v2itokenPrice) public onlyOwner {
        require(
            _v1itokenAddress != _v2itokenAddress
            && _v1itokenAddress != address(0) && _v2itokenAddress != address(0)
            && _v1itokenAddress != address(this) && _v2itokenAddress != address(this),
            "Invalid itoken address"
        );
        require(_v1itokenPrice > 1e18, "_v1itokenPrice should be > 1e18");
        require(_v2itokenPrice > 1e18, "_v2itokenPrice should be > 1e18");
        iTokenPrices[_v1itokenAddress] = 1e18 * _v1itokenPrice / _v2itokenPrice;
        iTokens[_v1itokenAddress] = _v2itokenAddress;

    }

    function migrate(address _v1itokenAddress) public {
        require(_v1itokenAddress != address(0));
        address _v2itokenAddress = iTokens[_v1itokenAddress];
        uint256 iTokenPrice = iTokenPrices[_v1itokenAddress];
        require(iTokenPrice > 0, "itoken is not configured");
        uint256 inAmount = IERC20(_v1itokenAddress).balanceOf(msg.sender);
        require(inAmount > 0, "Nothing to migrate");

        require(IERC20(_v1itokenAddress).allowance(msg.sender, address(this)) >= inAmount, "Please approve");
        uint256 outAmount = inAmount * iTokenPrice / 1e18;
        IERC20(_v1itokenAddress).transferFrom(msg.sender, DEAD, inAmount);
        IERC20(_v2itokenAddress).transfer(msg.sender, outAmount);
    }
}