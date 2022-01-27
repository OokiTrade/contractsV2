/**
 * Copyright 2017-2022, OokiDao. All Rights Reserved.
 * Licensed under the Apache License, Version 2.0.
 */

pragma solidity 0.5.17;

import "@openzeppelin-2.5.0/math/SafeMath.sol";
import "@openzeppelin-2.5.0/token/ERC20/SafeERC20.sol";
import "./VoteDelegationUpgradeable.sol";
import "../../mixins/EnumerableBytes32Set.sol";
import "../../../interfaces/IStakingV2.sol";


contract VoteDelegatorState is VoteDelegationUpgradeable {

    // A record of each accounts delegate
    // delegator => delegatee
    mapping (address => address) internal _delegates;

    /// @notice A checkpoint for marking number of votes from a given block
    struct Checkpoint {
        uint32 fromBlock;
        uint256 votes;
    }

    /// @notice A record of votes checkpoints for each account, by index
    mapping (address => mapping (uint32 => Checkpoint)) public checkpoints;

    /// @notice The number of checkpoints for each account
    mapping (address => uint32) public numCheckpoints;

    /// @notice The EIP-712 typehash for the contract's domain
    bytes32 public constant DOMAIN_TYPEHASH = keccak256("EIP712Domain(string name,uint256 chainId,address verifyingContract)");

    /// @notice The EIP-712 typehash for the delegation struct used by the contract
    bytes32 public constant DELEGATION_TYPEHASH = keccak256("Delegation(address delegatee,uint256 nonce,uint256 expiry)");

    /// @notice A record of states for signing / validating signatures
    mapping (address => uint) public nonces;

    mapping (address => uint256) public totalDelegators;

    IStakingV2 staking;
}
