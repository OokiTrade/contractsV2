/**
 * Copyright 2017-2020, bZeroX, LLC. All Rights Reserved.
 * Licensed under the Apache License, Version 2.0.
 */

pragma solidity 0.5.17;

import "@openzeppelin-2.5.0/token/ERC20/SafeERC20.sol";
import "../interfaces/IUniswapV2Router.sol";
import "./interfaces/ICurve3Pool.sol";
import "./interfaces/ICurveMinter.sol";
import "./interfaces/ICurve3PoolGauge.sol";
import "../../interfaces/IBZx.sol";


contract StakingConstants {

    address internal constant OOKI = 0x0De05F6447ab4D22c8827449EE4bA2D5C288379B;
    address internal constant BZRX = 0x56d811088235F11C8920698a204A5010a788f4b3;
    address internal constant vBZRX = 0xB72B31907C1C95F3650b64b2469e08EdACeE5e8F;
    address internal constant iBZRX = 0x18240BD9C07fA6156Ce3F3f61921cC82b2619157;
    address internal constant iOOKI = 0x05d5160cbc6714533ef44CEd6dd32112d56Ad7da;
    address internal constant LPToken = 0xEaaddE1E14C587a7Fb4Ba78eA78109BB32975f1e; // ooki sushiswap calculated upfront
    address internal constant LPToken_SUSHI_BZRX_ETH = 0xa30911e072A0C88D55B5D0A0984B66b0D04569d0; // sushiswap
    address internal constant LPTokenOld = 0xe26A220a341EAca116bDa64cF9D5638A935ae629; // balancer
    IERC20 public constant curve3Crv = IERC20(0x6c3F90f043a72FA612cbac8115EE7e52BDe6E490);

    address public constant WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    address public constant DAI = 0x6B175474E89094C44Da98b954EedeAC495271d0F;
    address public constant USDC = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
    address public constant USDT = 0xdAC17F958D2ee523a2206206994597C13D831ec7;
    address public constant SUSHI = 0x6B3595068778DD592e39A122f4f5a5cF09C90fE2;

    IUniswapV2Router public constant uniswapRouter = IUniswapV2Router(0xd9e1cE17f2641f24aE83637ab66a2cca9C378B9F); // sushiswap
    ICurve3Pool public constant curve3pool = ICurve3Pool(0xbEbc44782C7dB0a1A60Cb6fe97d0b483032FF1C7);
    IBZx public constant bZx = IBZx(0xD8Ee69652E4e4838f2531732a46d1f7F584F0b7f);

    uint256 internal constant cliffDuration =                15768000; // 86400 * 365 * 0.5
    uint256 internal constant vestingDuration =              126144000; // 86400 * 365 * 4
    uint256 internal constant vestingDurationAfterCliff =  110376000; // 86400 * 365 * 3.5
    uint256 internal constant vestingStartTimestamp =      1594648800; // start_time
    uint256 internal constant vestingCliffTimestamp =      vestingStartTimestamp + cliffDuration;
    uint256 internal constant vestingEndTimestamp =        vestingStartTimestamp + vestingDuration;
    uint256 internal constant _startingVBZRXBalance =       8893899330e18; // 8,893,899,330 OOKI

    address internal constant SUSHI_MASTERCHEF = 0xc2EdaD668740f1aA35E4D8f227fB8E17dcA888Cd;
    address internal constant SUSHI_ROUTER = 0xd9e1cE17f2641f24aE83637ab66a2cca9C378B9F;
    uint256 internal constant BZRX_ETH_SUSHI_MASTERCHEF_PID =  188; // we still need this to exit pool
    uint256 internal constant OOKI_ETH_SUSHI_MASTERCHEF_PID =  327; // TODO this is estimated on a fork

    uint256 public constant BZRXWeightStored = 1e18;

    ICurveMinter public constant curveMinter = ICurveMinter(0xd061D61a4d941c39E5453435B6345Dc261C2fcE0);
    ICurve3PoolGauge public constant curve3PoolGauge = ICurve3PoolGauge(0xbFcF63294aD7105dEa65aA58F8AE5BE2D9d0952A);
    address public constant CRV = 0xD533a949740bb3306d119CC777fa900bA034cd52;

    uint256 internal constant initialCirculatingSupply = 10300000000e18 - _startingVBZRXBalance;
    address internal constant ZERO_ADDRESS = address(0);

    struct DelegatedTokens {
        address user;
        uint256 BZRX;
        uint256 vBZRX;
        uint256 iBZRX;
        uint256 LPToken;
        uint256 totalVotes;
    }

    event Stake(
        address indexed user,
        address indexed token,
        address indexed delegate,
        uint256 amount
    );

    event Unstake(
        address indexed user,
        address indexed token,
        address indexed delegate,
        uint256 amount
    );

    event AddRewards(
        address indexed sender,
        uint256 bzrxAmount,
        uint256 stableCoinAmount
    );

    event Claim(
        address indexed user,
        uint256 bzrxAmount,
        uint256 stableCoinAmount
    );

    event ChangeDelegate(
        address indexed user,
        address indexed oldDelegate,
        address indexed newDelegate
    );

    event WithdrawFees(
        address indexed sender
    );

    event ConvertFees(
        address indexed sender,
        uint256 bzrxOutput,
        uint256 stableCoinOutput
    );

    event DistributeFees(
        address indexed sender,
        uint256 bzrxRewards,
        uint256 stableCoinRewards
    );

    event AddAltRewards(
        address indexed sender,
        address indexed token,
        uint256 amount
    );

    event ClaimAltRewards(
        address indexed user,
        address indexed token,
        uint256 amount
    );
}
