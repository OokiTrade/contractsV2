/**
 * Copyright 2017-2020, bZeroX, LLC. All Rights Reserved.
 * Licensed under the Apache License, Version 2.0.
 */

pragma solidity 0.5.17;

import "../interfaces/IWethERC20.sol";


contract Constants {
    //IWethERC20 public constant wethToken = IWethERC20(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2); // mainnet
    //address internal constant protocolTokenAddress = 0x1c74cFF0376FB4031Cd7492cD6dB2D66c3f2c6B9; // mainnet

    //IWethERC20 public constant wethToken = IWethERC20(0xd0A1E359811322d97991E03f863a0C30C2cF029C); // kovan
    //address internal constant protocolTokenAddress = 0xe3e682A8Fc7EFec410E4099cc09EfCC0743C634a; // kovan

    IWethERC20 public constant wethToken = IWethERC20(0x602C71e4DAC47a042Ee7f46E0aee17F94A3bA0B6); // local testnet only
    address public constant protocolTokenAddress = 0x3194cBDC3dbcd3E11a07892e7bA5c3394048Cc87; // local testnet only
}
