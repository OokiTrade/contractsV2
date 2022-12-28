/**
 * Copyright 2017-2023, OokiDao. All Rights Reserved.
 * Licensed under the Apache License, Version 2.0.
 */

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

import '../StakingStateV2.sol';
import '../../governance/PausableGuardian_0_8.sol';
import '../../utils/MathUtil.sol';

contract Common is StakingStateV2, PausableGuardian_0_8 {
  using MathUtil for uint256;

  function _getProposalState() internal view returns (ProposalState memory) {
    return
      ProposalState({
        proposalTime: block.timestamp - 1,
        iOOKIWeight: _calcIOOKIWeight(),
        lpOOKIBalance: 0, // IERC20(OOKI).balanceOf(LPToken),
        lpTotalSupply: 0 //IERC20(LPToken).totalSupply()
      });
  }

  function _calcIOOKIWeight() internal view returns (uint256) {
    uint256 total = IERC20(iOOKI).totalSupply();
    if (total != 0) return (IERC20(OOKI).balanceOf(iOOKI) * 1e50) / total;
    return 0;
  }

  function vestedBalanceForAmount(uint256 tokenBalance, uint256 lastUpdate, uint256 vestingEndTime) public view returns (uint256 vested) {
    vestingEndTime = vestingEndTime.min256(block.timestamp);
    if (vestingEndTime > lastUpdate) {
      if (vestingEndTime <= vestingCliffTimestamp || lastUpdate >= vestingEndTimestamp) {
        // time cannot be before vesting starts
        // OR all vested token has already been claimed
        return 0;
      }
      if (lastUpdate < vestingCliffTimestamp) {
        // vesting starts at the cliff timestamp
        lastUpdate = vestingCliffTimestamp;
      }
      if (vestingEndTime > vestingEndTimestamp) {
        // vesting ends at the end timestamp
        vestingEndTime = vestingEndTimestamp;
      }

      uint256 timeSinceClaim = vestingEndTime - lastUpdate;
      vested = (tokenBalance * timeSinceClaim) / vestingDurationAfterCliff; // will never divide by 0
    }
  }

  // Voting balance not including delegated votes
  function _votingFromStakedBalanceOf(address account, ProposalState memory proposal, bool skipVestingLastSyncCheck) internal view returns (uint256 totalVotes) {
    uint256 _vestingLastSync = vestingLastSync[account];
    if (proposal.proposalTime == 0 || (!skipVestingLastSyncCheck && _vestingLastSync > proposal.proposalTime - 1)) {
      return 0;
    }

    uint256 _vOOKIBalance = _balancesPerToken[vBZRX][account] * 10; // 10x for OOKI
    if (_vOOKIBalance != 0) {
      if (vestingEndTimestamp > proposal.proposalTime && vestingCliffTimestamp < proposal.proposalTime) {
        // staked vBZRX is prorated based on total vested
        totalVotes = (_vOOKIBalance * (vestingEndTimestamp - proposal.proposalTime)) / vestingDurationAfterCliff;
      }

      // user is attributed a staked balance of vested OOKI, from their last update to the present (10x for OOKI)
      totalVotes = vestedBalanceForAmount(_vOOKIBalance, _vestingLastSync, proposal.proposalTime) + totalVotes;
    }

    totalVotes = _balancesPerToken[OOKI][account] + ookiRewards[account] + totalVotes; // unclaimed BZRX rewards count as votes

    totalVotes = (_balancesPerToken[iOOKI][account] * proposal.iOOKIWeight) / 1e50 + totalVotes;

    // LPToken votes are measured based on amount of underlying BZRX staked
    /*totalVotes = proposal.lpBZRXBalance
            .mul(_balancesPerToken[LPToken][account])
            .div(proposal.lpTotalSupply)
            .add(totalVotes);*/
  }
}
