/**
 * Copyright 2017-2021, bZxDao. All Rights Reserved.
 * Licensed under the Apache License, Version 2.0.
 */

pragma solidity ^0.8.0;

import "@openzeppelin-4.3.2/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin-4.3.2/access/Ownable.sol";
import "../OokiToken.sol";
 
contract MintCoordinator is Ownable {

    OokiToken public constant OOKI = OokiToken(0xC5c66f91fE2e395078E0b872232A20981bc03B15);
    mapping (address => bool) public minters;
    mapping (address => bool) public burners;
    

    constructor() public {
        // minters[TODO] = true;
    }

    function mint(address _to, uint256 _amount) public {
        require(minters[msg.sender], "unauthorized");
        OOKI.mint(_to, _amount);
    }

    function burn(uint256 _amount) public {
        require(burners[msg.sender], "unauthorized");
        OOKI.transferFrom(msg.sender, address(this), _amount);
        OOKI.burn(_amount);
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

    function addBurner(address addr) public onlyOwner {
        burners[addr] = true;
    }

    function removeBurner(address addr) public onlyOwner {
        burners[addr] = false;
    }


    function rescue(IERC20 _token) public onlyOwner {
        SafeERC20.safeTransfer(_token, msg.sender, _token.balanceOf(address(this)));
    }

    function rescueToken(IERC20 _token) public onlyOwner {
        OOKI.rescue(_token);
        rescue(_token);
    }
}
