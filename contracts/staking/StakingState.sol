/**
 * Copyright 2017-2021, bZeroX, LLC. All Rights Reserved.
 * Licensed under the Apache License, Version 2.0.
 */

pragma solidity 0.5.17;

import "./StakingUpgradeable.sol";
import "../openzeppelin/SafeMath.sol";
import "../openzeppelin/SafeERC20.sol";
import "../mixins/EnumerableBytes32Set.sol";


contract StakingState is StakingUpgradeable {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;
    using EnumerableBytes32Set for EnumerableBytes32Set.Bytes32Set;

    uint256 public constant initialCirculatingSupply = 1030000000e18 - 889389933e18;
    address internal constant ZERO_ADDRESS = address(0);

    bool public isPaused;

    address public fundsWallet;

    mapping(address => uint256) internal _totalSupplyPerToken;                      // token => value
    mapping(address => mapping(address => uint256)) internal _balancesPerToken;     // token => account => value

    mapping(address => address) public delegate;                                    // user => delegate
    mapping(address => mapping(address => uint256)) public delegatedPerToken;       // token => user => value

    uint256 public bzrxPerTokenStored;
    mapping(address => uint256) public bzrxRewardsPerTokenPaid;                     // user => value
    mapping(address => uint256) public bzrxRewards;                                 // user => value
    mapping(address => uint256) public bzrxVesting;                                 // user => value

    uint256 public stableCoinPerTokenStored;
    mapping(address => uint256) public stableCoinRewardsPerTokenPaid;               // user => value
    mapping(address => uint256) public stableCoinRewards;                           // user => value
    mapping(address => uint256) public stableCoinVesting;                           // user => value

    uint256 public vBZRXWeightStored;
    uint256 public iBZRXWeightStored;
    uint256 public LPTokenWeightStored;

    EnumerableBytes32Set.Bytes32Set internal _delegatedSet;

    uint256 public lastRewardsAddTime;

    mapping(address => uint256) public vestingLastSync;

    mapping(address => address[]) public swapPaths;
    mapping(address => uint256) public stakingRewards;
    uint256 public rewardPercent = 50e18;
    uint256 public maxUniswapDisagreement = 3e18;
    uint256 public maxCurveDisagreement = 3e18;
    uint256 public callerRewardDivisor = 100;

    address[] public currentFeeTokens;
}
