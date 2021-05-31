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

// polygon: 
contract MintCoordinator_Polygon is Ownable {

    GovTokenLike public constant govToken = GovTokenLike(0x6044a7161C8EBb7fE610Ed579944178350426B5B);

    mapping (address => bool) public minters;

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
