/**
 * Copyright 2017-2021, bZxDao. All Rights Reserved.
 * Licensed under the Apache License, Version 2.0.
 */

pragma solidity 0.5.17;
pragma experimental ABIEncoderV2;

import "../StakingStateV2.sol";
import "../../governance/PausableGuardian.sol";
import "../../utils/MathUtil.sol";

contract Common is StakingStateV2, PausableGuardian {
    using MathUtil for uint256;

    function initialize(address target) external onlyOwner {
        // _setTarget(this._isPaused.selector, target);
    }

    function _getProposalState() internal view returns (ProposalState memory) {
        return
            ProposalState({
                proposalTime: block.timestamp - 1,
                iBZRXWeight: _calcIBZRXWeight(),
                lpBZRXBalance: 0, // IERC20(BZRX).balanceOf(LPToken),
                lpTotalSupply: 0 //IERC20(LPToken).totalSupply()
            });
    }

    function _calcIBZRXWeight() internal view returns (uint256) {
        return IERC20(BZRX).balanceOf(iBZRX).mul(1e50).div(IERC20(iBZRX).totalSupply());
    }

    function vestedBalanceForAmount(
        uint256 tokenBalance,
        uint256 lastUpdate,
        uint256 vestingEndTime
    ) public view returns (uint256 vested) {
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

            uint256 timeSinceClaim = vestingEndTime.sub(lastUpdate);
            vested = tokenBalance.mul(timeSinceClaim) / vestingDurationAfterCliff; // will never divide by 0
        }
    }

    // Voting balance not including delegated votes
    function _votingFromStakedBalanceOf(
        address account,
        ProposalState memory proposal,
        bool skipVestingLastSyncCheck
    ) internal view returns (uint256 totalVotes) {
        uint256 _vestingLastSync = vestingLastSync[account];
        if (proposal.proposalTime == 0 || (!skipVestingLastSyncCheck && _vestingLastSync > proposal.proposalTime - 1)) {
            return 0;
        }

        // user is attributed a staked balance of vested BZRX, from their last update to the present
        totalVotes = vestedBalanceForAmount(_balancesPerToken[vBZRX][account], _vestingLastSync, proposal.proposalTime);

        totalVotes = _balancesPerToken[BZRX][account].add(bzrxRewards[account]).add(totalVotes); // unclaimed BZRX rewards count as votes

        totalVotes = _balancesPerToken[iBZRX][account].mul(proposal.iBZRXWeight).div(1e50).add(totalVotes);

        // LPToken votes are measured based on amount of underlying BZRX staked
        /*totalVotes = proposal.lpBZRXBalance
            .mul(_balancesPerToken[LPToken][account])
            .div(proposal.lpTotalSupply)
            .add(totalVotes);*/
    }
}
