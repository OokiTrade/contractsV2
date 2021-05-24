/**
 * Copyright 2017-2021, bZeroX, LLC. All Rights Reserved.
 * Licensed under the Apache License, Version 2.0.
 */

pragma solidity 0.6.12;

import "@openzeppelin/contracts/access/Ownable.sol";


interface GovTokenLike {
    function mint(address to, uint256 amount) external;
    function transferOwnership(address newOwner) external;
}

// bsc: 0x68d57B33Fe3B691Ef96dFAf19EC8FA794899f2ac
contract MintCoordinator is Ownable {

    GovTokenLike public constant govToken = GovTokenLike(0xf8E026dC4C0860771f691EcFFBbdfe2fa51c77CF);

    mapping (address => bool) public minters;

    constructor() public {
        // adding MasterChef
        minters[0x1FDCA2422668B961E162A8849dc0C2feaDb58915] = true;
    }

    function mint(address _to, uint256 _amount) public {
        require(minters[msg.sender], "unauthorized");
        govToken.mint(_to, _amount);
    }

    function transferTokenOwnership(address newOwner) public onlyOwner {
        govToken.transferOwnership(newOwner);
    }

    function addMinter(address addr) public onlyOwner {
        minters[addr] = true;
    }

    function removeMinter(address addr) public onlyOwner {
        minters[addr] = false;
    }
}
