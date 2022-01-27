/**
 * Copyright 2017-2022, OokiDao. All Rights Reserved.
 * Licensed under the Apache License, Version 2.0.
 */

pragma solidity 0.5.17;

import "@openzeppelin-2.5.0/token/ERC20/SafeERC20.sol";
import "../interfaces/IUniswapV2Router.sol";
import "../interfaces/curve/ICurve3Pool.sol";
import "../interfaces/curve/ICurveMinter.sol";
import "../interfaces/curve/ICurve3PoolGauge.sol";
import "../../interfaces/IBZx.sol";
import "../../interfaces/IBZRXv2Converter.sol";

contract StakingConstantsV2 {
    address internal constant ZERO_ADDRESS = address(0);

    address public constant BZRX = 0x56d811088235F11C8920698a204A5010a788f4b3;
    address public constant OOKI = 0x0De05F6447ab4D22c8827449EE4bA2D5C288379B;
    address public constant vBZRX = 0xB72B31907C1C95F3650b64b2469e08EdACeE5e8F;
    address public constant iOOKI = 0x05d5160cbc6714533ef44CEd6dd32112d56Ad7da;
    address public constant OOKI_ETH_LP = 0xEaaddE1E14C587a7Fb4Ba78eA78109BB32975f1e; // sushiswap

    uint256 internal constant cliffDuration = 15768000; // 86400 * 365 * 0.5
    uint256 internal constant vestingDuration = 126144000; // 86400 * 365 * 4
    uint256 internal constant vestingDurationAfterCliff = 110376000; // 86400 * 365 * 3.5
    uint256 internal constant vestingStartTimestamp = 1594648800; // start_time
    uint256 internal constant vestingCliffTimestamp = vestingStartTimestamp + cliffDuration;
    uint256 internal constant vestingEndTimestamp = vestingStartTimestamp + vestingDuration;

    // these are 10x original balances for BZRX because of OOKI split
    uint256 internal constant _startingVBZRXBalance = 8893899330e18;
    // uint256 public constant initialCirculatingSupply = 10300000000e18 - _startingVBZRXBalance;

    address internal constant SUSHI_MASTERCHEF = 0xc2EdaD668740f1aA35E4D8f227fB8E17dcA888Cd;
    uint256 internal constant OOKI_ETH_SUSHI_MASTERCHEF_PID = 335;
    address public constant SUSHI = 0x6B3595068778DD592e39A122f4f5a5cF09C90fE2;

    ICurve3Pool public constant curve3pool = ICurve3Pool(0xbEbc44782C7dB0a1A60Cb6fe97d0b483032FF1C7);
    IERC20 public constant curve3Crv = IERC20(0x6c3F90f043a72FA612cbac8115EE7e52BDe6E490);

    ICurveMinter public constant curveMinter = ICurveMinter(0xd061D61a4d941c39E5453435B6345Dc261C2fcE0);

    IBZRXv2Converter public constant CONVERTER = IBZRXv2Converter(0x6BE9B7406260B6B6db79a1D4997e7f8f5c9D7400);

    event Stake(address indexed user, address indexed token, address indexed delegate, uint256 amount);

    event Unstake(address indexed user, address indexed token, address indexed delegate, uint256 amount);

    event Claim(address indexed user, uint256 ookiAmount, uint256 stableCoinAmount);

    event AddAltRewards(address indexed sender, address indexed token, uint256 amount);

    event ClaimAltRewards(address indexed user, address indexed token, uint256 amount);

    event AddRewards(address indexed sender, uint256 ookiAmount, uint256 stableCoinAmount);
}
