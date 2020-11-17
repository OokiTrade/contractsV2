/**
 * Copyright 2017-2020, bZeroX, LLC. All Rights Reserved.
 * Licensed under the Apache License, Version 2.0.
 */

pragma solidity 0.5.17;

import "../../openzeppelin/Ownable.sol";
import "../../openzeppelin/SafeMath.sol";
import "../../openzeppelin/SafeERC20.sol";
import "../../mixins/EnumerableBytes32Set.sol";


contract StakingInterimState is Ownable {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;
    using EnumerableBytes32Set for EnumerableBytes32Set.Bytes32Set;

    uint256 public constant initialCirculatingSupply = 1030000000e18 - 889389933e18;
    address internal constant ZERO_ADDRESS = address(0);

    address public BZRX;
    address public vBZRX;
    address public LPToken;

    address public implementation;

    bool public isInit;
    bool public isActive;

    mapping(address => uint256) internal _totalSupplyPerToken;                      // token => value
    mapping(address => mapping(address => uint256)) internal _balancesPerToken;     // token => account => value
    mapping(address => mapping(address => uint256)) internal _checkpointPerToken;   // token => account => value

    mapping(address => address) public delegate;                                    // user => delegate
    mapping(address => mapping(address => uint256)) public repStakedPerToken;       // token => user => value
    mapping(address => bool) public reps;                                           // user => isActive

    uint256 public rewardPerTokenStored;
    mapping(address => uint256) public userRewardPerTokenPaid;                      // user => value
    mapping(address => uint256) public rewards;                                     // user => value

    EnumerableBytes32Set.Bytes32Set internal repStakedSet;

    uint256 public lastUpdateTime;
    uint256 public periodFinish;
    uint256 public rewardRate;
}
