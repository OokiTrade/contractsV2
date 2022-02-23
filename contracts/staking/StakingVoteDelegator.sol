/**
 * Copyright 2017-2022, OokiDao. All Rights Reserved.
 * Licensed under the Apache License, Version 2.0.
 */

pragma solidity 0.5.17;
pragma experimental ABIEncoderV2;

import "@openzeppelin-2.5.0/math/SafeMath.sol";
import "../governance/GovernorBravoDelegate.sol";
import "../../interfaces/IStaking.sol";
import "./StakingVoteDelegatorState.sol";
import "./StakingVoteDelegatorConstants.sol";
import "@openzeppelin-2.5.0/token/ERC20/SafeERC20.sol";
import "../governance/PausableGuardian.sol";


contract StakingVoteDelegator is StakingVoteDelegatorState, StakingVoteDelegatorConstants, PausableGuardian {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    /**
     * @notice Getter
     * @param delegator The address to get delegatee for
     */
    function delegates(address delegator) external view returns (address) {
        return _delegates[delegator];
    }

    /**
     * @notice Delegate votes from `msg.sender` to `delegatee`
     * @param delegatee The address to delegate votes to
     */
    function delegate(address delegatee) pausable external {
        if(delegatee == msg.sender){
            delegatee = ZERO_ADDRESS;
        }
        return _delegate(msg.sender, delegatee);
    }

    /**
     * @notice Delegates votes from signatory to `delegatee`
     * @param delegatee The address to delegate votes to
     * @param nonce The contract state required to match the signature
     * @param expiry The time at which to expire the signature
     * @param v The recovery byte of the signature
     * @param r Half of the ECDSA signature pair
     * @param s Half of the ECDSA signature pair
     */
    function delegateBySig(address delegatee, uint nonce, uint expiry, uint8 v, bytes32 r, bytes32 s) pausable external {
        if(delegatee == msg.sender){
            delegatee = ZERO_ADDRESS;
        }

        bytes32 domainSeparator = keccak256(
            abi.encode(
                DOMAIN_TYPEHASH,
                keccak256(bytes("STAKING")),
                getChainId(),
                address(this)
            )
        );

        bytes32 structHash = keccak256(
            abi.encode(
                DELEGATION_TYPEHASH,
                delegatee,
                nonce,
                expiry
            )
        );

        bytes32 digest = keccak256(
            abi.encodePacked(
                "\x19\x01",
                domainSeparator,
                structHash
            )
        );

        address signatory = ecrecover(digest, v, r, s);
        require(signatory != ZERO_ADDRESS, "Staking::delegateBySig: invalid signature");
        require(nonce == nonces[signatory]++, "Staking::delegateBySig: invalid nonce");
        require(now <= expiry, "Staking::delegateBySig: signature expired");
        return _delegate(signatory, delegatee);
    }

    /**
     * @notice Gets the current votes balance for `account`
     * @param account The address to get votes balance
     * @return The number of current votes for `account`
     */
    function getCurrentVotes(address account) external view returns (uint256) {
        uint32 nCheckpoints = numCheckpoints[account];
        return nCheckpoints > 0 ? checkpoints[account][nCheckpoints - 1].votes : 0;
    }


    /**
     * @notice Determine the prior number of votes for an account as of a block number
     * @dev Block number must be a finalized block or else this function will revert to prevent misinformation.
     * @param account The address of the account to check
     * @param blockNumber The block number to get the vote balance at
     * @return The number of votes the account had as of the given block
     */
    function getPriorVotes(address account, uint blockNumber) public view returns (uint256) {
        require(blockNumber < block.number, "Staking::getPriorVotes: not yet determined");

        uint32 nCheckpoints = numCheckpoints[account];
        if (nCheckpoints == 0) {
            return 0;
        }

        // First check most recent balance
        if (checkpoints[account][nCheckpoints - 1].fromBlock <= blockNumber) {
            return checkpoints[account][nCheckpoints - 1].votes;
        }

        // Next check implicit zero balance
        if (checkpoints[account][0].fromBlock > blockNumber) {
            return 0;
        }

        uint32 lower = 0;
        uint32 upper = nCheckpoints - 1;
        while (upper > lower) {
            uint32 center = upper - (upper - lower) / 2; // ceil, avoiding overflow
            Checkpoint memory cp = checkpoints[account][center];
            if (cp.fromBlock == blockNumber) {
                return cp.votes;
            } else if (cp.fromBlock < blockNumber) {
                lower = center;
            } else {
                upper = center - 1;
            }
        }
        return checkpoints[account][lower].votes;
    }

    function _delegate(address delegator, address delegatee) internal {
        if(delegatee == delegator || delegator == ZERO_ADDRESS)
            return;

        address oldDelegate = _delegates[delegator];

        uint256 delegatorBalance = staking.votingFromStakedBalanceOf(delegator);
        _delegates[delegator] = delegatee;

        //ZERO_ADDRESS means that user wants to revoke delegation
        if(delegatee == ZERO_ADDRESS && oldDelegate != ZERO_ADDRESS){
            if(totalDelegators[oldDelegate] > 0)
                totalDelegators[oldDelegate]--;

            if(totalDelegators[oldDelegate] == 0 && oldDelegate != ZERO_ADDRESS){
                uint32 dstRepNum = numCheckpoints[oldDelegate];
                uint256 dstRepOld = dstRepNum > 0 ? checkpoints[oldDelegate][dstRepNum - 1].votes : 0;
                uint256 dstRepNew = 0;
                _writeCheckpoint(oldDelegate, dstRepNum, dstRepOld, dstRepNew);
                return;
            }
        }
        else if(delegatee != ZERO_ADDRESS){
            totalDelegators[delegatee]++;
            if(totalDelegators[oldDelegate] > 0)
                totalDelegators[oldDelegate]--;
        }

        emit DelegateChanged(delegator, oldDelegate, delegatee);
        _moveDelegates(oldDelegate, delegatee, delegatorBalance);
    }

    function moveDelegates(
        address srcRep,
        address dstRep,
        uint256 amount
    ) public {
        require(msg.sender == address(staking), "unauthorized");
        _moveDelegates(srcRep, dstRep, amount);
    }

    function moveDelegatesByVotingBalance(
        uint256 votingBalanceBefore,
        uint256 votingBalanceAfter,
        address account
    )
    public
    {
        require(msg.sender == address(staking), "unauthorized");
        address currentDelegate = _delegates[account];
        if(currentDelegate == ZERO_ADDRESS)
            return;

        if(votingBalanceBefore > votingBalanceAfter){
            _moveDelegates(currentDelegate, ZERO_ADDRESS,
                votingBalanceBefore.sub(votingBalanceAfter)
            );
        }
        else{
            _moveDelegates(ZERO_ADDRESS, currentDelegate,
                votingBalanceAfter.sub(votingBalanceBefore)
            );
        }
    }

    function _moveDelegates(address srcRep, address dstRep, uint256 amount) internal {
        if (srcRep != dstRep && amount > 0) {
            if (srcRep != ZERO_ADDRESS) {
                // decrease old representative
                uint32 srcRepNum = numCheckpoints[srcRep];
                uint256 srcRepOld = srcRepNum > 0 ? checkpoints[srcRep][srcRepNum - 1].votes : 0;
                uint256 srcRepNew = srcRepOld.sub((amount > srcRepOld)? srcRepOld : amount);
                _writeCheckpoint(srcRep, srcRepNum, srcRepOld, srcRepNew);
            }

            if (dstRep != ZERO_ADDRESS) {
                // increase new representative
                uint32 dstRepNum = numCheckpoints[dstRep];
                uint256 dstRepOld = dstRepNum > 0 ? checkpoints[dstRep][dstRepNum - 1].votes : 0;
                uint256 dstRepNew = dstRepOld.add(amount);
                _writeCheckpoint(dstRep, dstRepNum, dstRepOld, dstRepNew);
            }
        }
    }

    function _writeCheckpoint(address delegatee, uint32 nCheckpoints, uint256 oldVotes, uint256 newVotes) internal {
        uint32 blockNumber = safe32(block.number, "Staking::_writeCheckpoint: block number exceeds 32 bits");

        if (nCheckpoints > 0 && checkpoints[delegatee][nCheckpoints - 1].fromBlock == blockNumber) {
            checkpoints[delegatee][nCheckpoints - 1].votes = newVotes;
        } else {
            checkpoints[delegatee][nCheckpoints] = Checkpoint(blockNumber, newVotes);
            numCheckpoints[delegatee] = nCheckpoints + 1;
        }

        emit DelegateVotesChanged(delegatee, oldVotes, newVotes);
    }

    function safe32(uint n, string memory errorMessage) internal pure returns (uint32) {
        require(n < 2**32, errorMessage);
        return uint32(n);
    }

    function getChainId() internal pure returns (uint) {
        uint256 chainId;
        assembly { chainId := chainid() }
        return chainId;
    }
}
