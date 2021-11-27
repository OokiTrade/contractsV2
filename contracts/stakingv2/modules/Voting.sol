/**
 * Copyright 2017-2021, bZxDao. All Rights Reserved.
 * Licensed under the Apache License, Version 2.0.
 */

pragma solidity 0.5.17;
pragma experimental ABIEncoderV2;

import "../StakingStateV2.sol";
import "../../governance/PausableGuardian.sol";
import "./Common.sol";
import "../../governance/GovernorBravoInterfaces.sol";
import "../delegation/VoteDelegator.sol";

contract Voting is Common {
    function initialize(address target) external onlyOwner {
        _setTarget(this.votingFromStakedBalanceOf.selector, target);
        _setTarget(this.votingBalanceOf.selector, target);
        _setTarget(this.votingBalanceOfNow.selector, target);
        _setTarget(this._setProposalVals.selector, target);
    }

    function votingFromStakedBalanceOf(address account) external view returns (uint256 totalVotes) {
        return _votingFromStakedBalanceOf(account, _getProposalState(), true);
    }

    function votingBalanceOf(address account, uint256 proposalId) external view returns (uint256 totalVotes) {
        (, , , uint256 startBlock, , , , , , ) = GovernorBravoDelegateStorageV1(governor).proposals(proposalId);

        if (startBlock == 0) return 0;

        return _votingBalanceOf(account, _proposalState[proposalId], startBlock - 1);
    }

    function votingBalanceOfNow(address account) external view returns (uint256 totalVotes) {
        return _votingBalanceOf(account, _getProposalState(), block.number - 1);
    }

    function _setProposalVals(address account, uint256 proposalId) public returns (uint256) {
        require(msg.sender == governor, "unauthorized");
        require(_proposalState[proposalId].proposalTime == 0, "proposal exists");
        ProposalState memory newProposal = _getProposalState();
        _proposalState[proposalId] = newProposal;

        return _votingBalanceOf(account, newProposal, block.number - 1);
    }

    // Voting balance including delegated votes
    function _votingBalanceOf(
        address account,
        ProposalState memory proposal,
        uint256 blocknumber
    ) internal view returns (uint256 totalVotes) {
        VoteDelegator _voteDelegator = VoteDelegator(voteDelegator);
        address _delegate = _voteDelegator.delegates(account);

        if (_delegate == ZERO_ADDRESS) {
            // has not delegated yet
            return _voteDelegator.getPriorVotes(account, blocknumber).add(_votingFromStakedBalanceOf(account, proposal, false));
        }

        return _voteDelegator.getPriorVotes(account, blocknumber);
    }
}
