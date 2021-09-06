/**
 * Copyright 2017-2021, bZxDao. All Rights Reserved.
 * Licensed under the Apache License, Version 2.0.
 */

pragma solidity 0.6.12;

import "@openzeppelin-3.4.0/token/ERC20/SafeERC20.sol";
import "@openzeppelin-3.4.0/access/Ownable.sol";
import "../OokiToken.sol";
 
contract MintCoordinator is Ownable {

    OokiToken public constant OOKI = OokiToken(0xC5c66f91fE2e395078E0b872232A20981bc03B15);
    mapping (address => bool) public minters;
    

    constructor() public {
        // minters[TODO] = true;
    }

    function mint(address _to, uint256 _amount) public {
        require(minters[msg.sender], "unauthorized");
        OOKI.mint(_to, _amount);
    }

    function transferTokenOwnership(address newOwner) public onlyOwner {
        OOKI.transferOwnership(newOwner);
    }

    function addMinter(address addr) public onlyOwner {
        minters[addr] = true;
    }

    function removeMinter(address addr) public onlyOwner {
        minters[addr] = false;
    }

    function rescue(IERC20 _token) public onlyOwner {
        SafeERC20.safeTransfer(_token, msg.sender, _token.balanceOf(address(this)));
    }

    function rescueToken(IERC20 _token) public onlyOwner {
        OOKI.rescue(_token);
        rescue(_token);
    }
}
