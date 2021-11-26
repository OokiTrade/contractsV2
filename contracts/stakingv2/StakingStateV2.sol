/**
 * Copyright 2017-2021, bZxDao. All Rights Reserved.
 * Licensed under the Apache License, Version 2.0.
 */

pragma solidity 0.5.17;

import "@openzeppelin-2.5.0/math/SafeMath.sol";
import "@openzeppelin-2.5.0/token/ERC20/SafeERC20.sol";
import "../mixins/EnumerableBytes32Set.sol";
import "../../interfaces/IStaking.sol";
import "@openzeppelin-2.5.0/ownership/Ownable.sol";
import "./StakingConstantsV2.sol";

contract StakingStateV2 is StakingConstantsV2, Ownable {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;
    using EnumerableBytes32Set for EnumerableBytes32Set.Bytes32Set;

    mapping(bytes4 => address) public logicTargets;
    EnumerableBytes32Set.Bytes32Set internal logicTargetsSet;

    mapping(address => uint256) internal _totalSupplyPerToken; // token => value
    mapping(address => mapping(address => uint256)) internal _balancesPerToken; // token => account => value

    uint256 public bzrxPerTokenStored;
    mapping(address => uint256) public bzrxRewardsPerTokenPaid; // user => value
    mapping(address => uint256) public bzrxRewards; // user => value
    mapping(address => uint256) public bzrxVesting; // user => value

    uint256 public stableCoinPerTokenStored;
    mapping(address => uint256) public stableCoinRewardsPerTokenPaid; // user => value
    mapping(address => uint256) public stableCoinRewards; // user => value
    mapping(address => uint256) public stableCoinVesting; // user => value

    uint256 public vBZRXWeightStored;
    uint256 public iBZRXWeightStored;
    uint256 public LPTokenWeightStored;

    mapping(address => uint256) public vestingLastSync;

    struct ProposalState {
        uint256 proposalTime;
        uint256 iBZRXWeight;
        uint256 lpBZRXBalance;
        uint256 lpTotalSupply;
    }
    address public governor;
    mapping(uint256 => ProposalState) internal _proposalState;

    mapping(address => uint256[]) public altRewardsRounds; // depreciated
    mapping(address => uint256) public altRewardsPerShare; // token => value

    // Token => (User => Info)
    mapping(address => mapping(address => IStaking.AltRewardsUserInfo)) public userAltRewardsPerShare;


    function _setTarget(bytes4 sig, address target) internal {
        logicTargets[sig] = target;

        if (target != address(0)) {
            logicTargetsSet.addBytes32(bytes32(sig));
        } else {
            logicTargetsSet.removeBytes32(bytes32(sig));
        }
    }
}
