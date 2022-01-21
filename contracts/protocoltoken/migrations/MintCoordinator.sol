/**
 * Copyright 2017-2022, OokiDao. All Rights Reserved.
 * Licensed under the Apache License, Version 2.0.
 */

pragma solidity ^0.8.0;

import "@openzeppelin-4.3.2/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin-4.3.2/access/Ownable.sol";
import "../OokiToken.sol";
 
contract MintCoordinator is Ownable {

    OokiToken public constant OOKI = OokiToken(0x0De05F6447ab4D22c8827449EE4bA2D5C288379B);
    mapping (address => bool) public minters;

    function mint(address _to, uint256 _amount) public {
        require(minters[msg.sender], "unauthorized");
        OOKI.mint(_to, _amount);
    }

    function transferTokenOwnership(address newOwner) public onlyOwner {
        OOKI.transferOwnership(newOwner);
    }

    function addMinter(address addr) public onlyOwner {
        minters[addr] = true;
        emit AddMinter(addr);
    }

    function removeMinter(address addr) public onlyOwner {
        minters[addr] = false;
        emit RemoveMinter(addr);
    }

    function rescue(IERC20 _token) public onlyOwner {
        SafeERC20.safeTransfer(_token, msg.sender, _token.balanceOf(address(this)));
    }

    function rescueToken(IERC20 _token) public onlyOwner {
        OOKI.rescue(_token);
        rescue(_token);
    }

    event AddMinter(address indexed minter);
    event RemoveMinter(address indexed minter);
}
