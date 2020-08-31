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


    uint256 constant public initialCirculatingSupply = 1030000000e18 - 889389933e18;
    uint256 constant public normalizedRewardRate = 1e6;
    address internal constant ZERO_ADDRESS = address(0);

    bool public isInit = false;
    address public implementation;

    mapping(address => uint256) internal _totalSupplyPerToken;                      // token => value
    mapping(address => mapping(address => uint256)) internal _balancesPerToken;     // token => account => value
    mapping(address => mapping(address => uint256)) internal _checkpointPerToken;   // token => account => value

    mapping(address => address) public repDelegate;                                 // user => delegate
    mapping(address => mapping(address => uint256)) public repStakedPerToken;       // token => wallet => value
    mapping(address => bool) public reps;                                           // wallet => isActive

    mapping(address => uint256) public rewardsPerTokenStored;
    mapping(address => mapping(address => uint256)) public userRewardPerTokenPaid;
    mapping(address => uint256) public rewards;

    EnumerableBytes32Set.Bytes32Set internal repStakedSet;

    address public BZRX;
    address public vBZRX;
    address public LPToken;

    uint256 public lastUpdateTime;

    bool public isActive;

}
