pragma solidity ^0.8.0;

import "../../../interfaces/IBZx.sol";


contract OrderBookConstants {
    address public constant WRAPPED_TOKEN =
        0x0d500B1d8E8eF31E21C99d1Db9A6444d3ADf1270;
    address public constant USDC = 0x2791Bca1f2de4661ED88A30C99A7a9449Aa84174;
    address public constant VAULT = 0xFA6485ec4Aa9AF504adb4ed47b567E1875E21e85;
    IBZx public constant PROTOCOL =
        IBZx(0x059D60a9CEfBc70b9Ea9FFBb9a041581B1dFA6a8);
}