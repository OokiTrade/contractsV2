/**
 * Copyright 2017-2020, bZeroX, LLC. All Rights Reserved.
 * Licensed under the Apache License, Version 2.0.
 */

pragma solidity 0.5.17;

import "../openzeppelin/Ownable.sol";
import "../openzeppelin/SafeMath.sol";
import "../openzeppelin/SafeERC20.sol";
import "../mixins/EnumerableBytes32Set.sol";


contract StakingState is Ownable {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;
    using EnumerableBytes32Set for EnumerableBytes32Set.Bytes32Set;

    uint256 internal constant WEI_PRECISION = 10**18;
    uint256 internal constant WEI_PERCENT_PRECISION = 10**20;

    uint256 public constant initialCirculatingSupply = 1030000000e18 - 889389933e18;
    address internal constant ZERO_ADDRESS = address(0);

    address public BZRX;
    address public vBZRX;
    address public LPToken;

    address public implementation;

    bool public isPaused;

    address public fundsWallet;

    mapping(address => uint256) internal _totalSupplyPerToken;                      // token => value
    mapping(address => mapping(address => uint256)) internal _balancesPerToken;     // token => account => value
    mapping(address => mapping(address => uint256)) internal _checkpointPerToken;   // token => account => value

    mapping(address => address) public delegate;                                    // user => delegate
    mapping(address => mapping(address => uint256)) public repStakedPerToken;       // token => user => value
    mapping(address => bool) public reps;                                           // user => isActive

    uint256 public bzrxRewardSet;
    uint256 public bzrxPerTokenStored;
    mapping(address => uint256) public bzrxRewardsPerTokenPaid;                     // user => value
    mapping(address => uint256) public bzrxRewards;                                 // user => value

    uint256 public stableCoinRewardSet;
    uint256 public stableCoinPerTokenStored;
    mapping(address => uint256) public stableCoinRewardsPerTokenPaid;               // user => value
    mapping(address => uint256) public stableCoinRewards;                           // user => value

    EnumerableBytes32Set.Bytes32Set internal _repStakedSet;

    uint256 public lastUpdateTime;
    uint256 public lastRewardsUpdateTime;

    mapping(address => uint256) internal _vBZRXLastUpdate;

    mapping(address => address[]) public swapPaths;
    mapping(address => uint256) public stakingRewards;
    uint256 public rewardPercent = 50e18;
    uint256 public maxAllowedDisagreement = 3 ether;

    address[] public currentFeeTokens;
}
