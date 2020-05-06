/**
 * Copyright 2017-2020, bZeroX, LLC. All Rights Reserved.
 * Licensed under the Apache License, Version 2.0.
 */

pragma solidity 0.5.17;

import "../../interfaces/IWethERC20.sol";


contract Constants {
    // mainnet constants
    //IWethERC20 public constant wethToken = IWethERC20(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);

    // kovan constants
    //IWethERC20 public constant wethToken = IWethERC20(0xd0A1E359811322d97991E03f863a0C30C2cF029C);

    // ropsten constants
    //IWethERC20 public constant wethToken = IWethERC20(0xc778417E063141139Fce010982780140Aa0cD5Ab);

    // local testnet only
    IWethERC20 public constant wethToken = IWethERC20(0x3194cBDC3dbcd3E11a07892e7bA5c3394048Cc87);
}
