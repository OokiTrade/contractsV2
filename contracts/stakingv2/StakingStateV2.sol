/**
 * Copyright 2017-2023, OokiDao. All Rights Reserved.
 * Licensed under the Apache License, Version 2.0.
 */

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

import "@openzeppelin-4.8.3/token/ERC20/utils/SafeERC20.sol";
import "../mixins/EnumerableBytes32Set.sol";
import "../../interfaces/IStakingV2.sol";
import "@openzeppelin-4.8.3/access/Ownable.sol";
import "./StakingConstantsV2.sol";

contract StakingStateV2 is StakingConstantsV2, Ownable {
  using SafeERC20 for IERC20;
  using EnumerableBytes32Set for EnumerableBytes32Set.Bytes32Set;

  mapping(bytes4 => address) public logicTargets;
  EnumerableBytes32Set.Bytes32Set internal logicTargetsSet;

  mapping(address => uint256) public _totalSupplyPerToken; // token => value
  mapping(address => mapping(address => uint256)) internal _balancesPerToken; // token => account => value

  uint256 public ookiPerTokenStored;
  mapping(address => uint256) public ookiRewardsPerTokenPaid; // user => value
  mapping(address => uint256) public ookiRewards; // user => value
  mapping(address => uint256) public bzrxVesting; // user => value

  uint256 public stableCoinPerTokenStored;
  mapping(address => uint256) public stableCoinRewardsPerTokenPaid; // user => value
  mapping(address => uint256) public stableCoinRewards; // user => value
  mapping(address => uint256) public stableCoinVesting; // user => value

  uint256 public vBZRXWeightStored;
  uint256 public iOOKIWeightStored;
  uint256 public LPTokenWeightStored;

  uint256 public lastRewardsAddTime;
  mapping(address => uint256) public vestingLastSync;

  struct ProposalState {
    uint256 proposalTime;
    uint256 iOOKIWeight;
    uint256 lpOOKIBalance;
    uint256 lpTotalSupply;
  }
  address public governor;
  mapping(uint256 => ProposalState) internal _proposalState;

  mapping(address => uint256[]) public altRewardsRounds; // depreciated
  mapping(address => uint256) public altRewardsPerShare; // token => value

  // Token => (User => Info)
  mapping(address => mapping(address => IStakingV2.AltRewardsUserInfo)) public userAltRewardsInfo;

  address public voteDelegator;

  mapping(address => uint256) public altRewardsPerSharePerBlock; // token => value
  mapping(address => uint256) public altRewardsBlock; // token => value (last block when addAltRewards was triggered)
  mapping(address => uint256) public altRewardsStartBlock;

  function _setTarget(bytes4 sig, address target) internal {
    logicTargets[sig] = target;

    if (target != address(0)) {
      logicTargetsSet.addBytes32(bytes32(sig));
    } else {
      logicTargetsSet.removeBytes32(bytes32(sig));
    }
  }
}
