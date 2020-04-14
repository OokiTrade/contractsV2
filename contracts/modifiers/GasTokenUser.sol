/**
 * Copyright 2017-2020, bZeroX, LLC. All Rights Reserved.
 * Licensed under the Apache License, Version 2.0.
 */

pragma solidity 0.5.17;

import "../openzeppelin/Ownable.sol";


contract IGastoken {
    function freeUpTo(uint256 _value) public returns (uint256 freed);
    function balanceOf(address _who) public view returns (uint256);
    function transfer(address _to, uint256 _value) public returns (bool);
}

contract GasTokenUser is Ownable {

    // All network besides Kovan
    //IGastoken public constant gasToken = IGastoken(0x0000000000b3F879cb30FE243b4Dfee438691c04);

    // Kovan only
    IGastoken public constant gasToken = IGastoken(0x0000000000170CcC93903185bE5A2094C870Df62);

    modifier usesGasToken() {
        uint256 startingGas = gasleft();

        _;

        if (startingGas > gasleft()) {
            uint256 amount = (startingGas - gasleft() + 14154) / 41130;
            gasToken.freeUpTo(amount);
        }
    }

    // withdrawGasToken()
    function withdrawGasToken()
        external
        onlyOwner
    {
        gasToken.transfer(owner(), gasToken.balanceOf(address(this)));
    }
}
