pragma solidity ^0.5.16;
pragma experimental ABIEncoderV2;

import "@openzeppelin-2.5.0/token/ERC20/IERC20.sol";
import "./GovernorBravoInterfaces.sol";

contract GovernorBravoDelegate is GovernorBravoDelegateStorageV1, GovernorBravoEvents {

    /// @notice The name of this contract
    string public constant name = "Ooki Governor Bravo";

    /// @notice The minimum setable proposal threshold
    uint public constant MIN_PROPOSAL_THRESHOLD = 0.5e18; // 0.5% of OOKI

    /// @notice The maximum setable proposal threshold
    uint public constant MAX_PROPOSAL_THRESHOLD = 2e18; // 2% of OOKI

    /// @notice The minimum setable voting period
    uint public constant MIN_VOTING_PERIOD = 5760; // About 24 hours

    /// @notice The max setable voting period
    uint public constant MAX_VOTING_PERIOD = 80640; // About 2 weeks

    /// @notice The min setable voting delay
    uint public constant MIN_VOTING_DELAY = 1;

    /// @notice The max setable voting delay
    uint public constant MAX_VOTING_DELAY = 40320; // About 1 week

    /// @notice The min setable quorum percentage
    uint public constant MIN_QUORUM_PERCENTAGE = 2e18; // 2% of total OOKI supply

    /// @notice The max setable quorum percentage
    uint public constant MAX_QUORUM_PERCENTAGE = 6e18; // 6% of total OOKI supply

    /// @notice The maximum number of actions that can be included in a proposal
    uint public constant proposalMaxOperations = 100; // 100 actions

    /// @notice The EIP-712 typehash for the contract's domain
    bytes32 public constant DOMAIN_TYPEHASH = keccak256("EIP712Domain(string name,uint256 chainId,address verifyingContract)");

    /// @notice The EIP-712 typehash for the ballot struct used by the contract
    bytes32 public constant BALLOT_TYPEHASH = keccak256("Ballot(uint256 proposalId,uint8 support)");


    /**
      * @notice Used to initialize the contract during delegator contructor
      * @param timelock_ The address of the Timelock
      * @param staking_ The address of the STAKING
      * @param votingPeriod_ The initial voting period
      * @param votingDelay_ The initial voting delay
      * @param proposalThresholdPercentage_ The initial proposal threshold percentage
      */
    function initialize(address timelock_, address staking_, uint votingPeriod_, uint votingDelay_, uint proposalThresholdPercentage_, uint quorumPercentage_) public {
        require(address(timelock) == address(0), "GovernorBravo::initialize: can only initialize once");
        require(msg.sender == admin, "GovernorBravo::initialize: admin only");
        require(timelock_ != address(0), "GovernorBravo::initialize: invalid timelock address");
        require(staking_ != address(0), "GovernorBravo::initialize: invalid STAKING address");
        require(votingPeriod_ >= MIN_VOTING_PERIOD && votingPeriod_ <= MAX_VOTING_PERIOD, "GovernorBravo::initialize: invalid voting period");
        require(votingDelay_ >= MIN_VOTING_DELAY && votingDelay_ <= MAX_VOTING_DELAY, "GovernorBravo::initialize: invalid voting delay");
        require(proposalThresholdPercentage_ >= MIN_PROPOSAL_THRESHOLD && proposalThresholdPercentage_ <= MAX_PROPOSAL_THRESHOLD, "GovernorBravo::initialize: invalid proposal threshold");
        require(quorumPercentage_ >= MIN_QUORUM_PERCENTAGE && quorumPercentage_ <= MAX_QUORUM_PERCENTAGE, "GovernorBravo::initialize: invalid quorum percentage");

        timelock = TimelockInterface(timelock_);
        staking = StakingInterface(staking_);
        votingPeriod = votingPeriod_;
        votingDelay = votingDelay_;
        proposalThresholdPercentage = proposalThresholdPercentage_;
        quorumPercentage = quorumPercentage_;

        guardian = msg.sender;
    }

    /**
      * @notice Function used to propose a new proposal. Sender must have delegates above the proposal threshold
      * @param targets Target addresses for proposal calls
      * @param values Eth values for proposal calls
      * @param signatures Function signatures for proposal calls
      * @param calldatas Calldatas for proposal calls
      * @param description String description of the proposal
      * @return Proposal id of new proposal
      */
    function propose(address[] memory targets, uint[] memory values, string[] memory signatures, bytes[] memory calldatas, string memory description) public returns (uint) {
        require(targets.length == values.length && targets.length == signatures.length && targets.length == calldatas.length, "GovernorBravo::propose: proposal function information arity mismatch");
        require(targets.length != 0, "GovernorBravo::propose: must provide actions");
        require(targets.length <= proposalMaxOperations, "GovernorBravo::propose: too many actions");

        uint latestProposalId = latestProposalIds[msg.sender];
        if (latestProposalId != 0) {
            ProposalState proposersLatestProposalState = state(latestProposalId);
            require(proposersLatestProposalState != ProposalState.Active, "GovernorBravo::propose: one live proposal per proposer, found an already active proposal");
            require(proposersLatestProposalState != ProposalState.Pending, "GovernorBravo::propose: one live proposal per proposer, found an already pending proposal");
        }

        uint proposalId = proposalCount + 1;
        require(staking._setProposalVals(msg.sender, proposalId) > proposalThreshold(), "GovernorBravo::propose: proposer votes below proposal threshold");
        proposalCount = proposalId;

        uint startBlock = add256(block.number, votingDelay);
        uint endBlock = add256(startBlock, votingPeriod);

        Proposal memory newProposal = Proposal({
            id: proposalId,
            proposer: msg.sender,
            eta: 0,
            targets: targets,
            values: values,
            signatures: signatures,
            calldatas: calldatas,
            startBlock: startBlock,
            endBlock: endBlock,
            forVotes: 0,
            againstVotes: 0,
            abstainVotes: 0,
            canceled: false,
            executed: false
        });

        proposals[proposalId] = newProposal;
        latestProposalIds[msg.sender] = proposalId;
        quorumVotesForProposal[proposalId] = quorumVotes();

        emit ProposalCreated(proposalId, msg.sender, targets, values, signatures, calldatas, startBlock, endBlock, description);
        return proposalId;
    }

    /**
      * @notice Queues a proposal of state succeeded
      * @param proposalId The id of the proposal to queue
      */
    function queue(uint proposalId) external {
        require(state(proposalId) == ProposalState.Succeeded, "GovernorBravo::queue: proposal can only be queued if it is succeeded");
        Proposal storage proposal = proposals[proposalId];
        uint eta = add256(block.timestamp, timelock.delay());
        for (uint i = 0; i < proposal.targets.length; i++) {
            queueOrRevertInternal(proposal.targets[i], proposal.values[i], proposal.signatures[i], proposal.calldatas[i], eta);
        }
        proposal.eta = eta;
        emit ProposalQueued(proposalId, eta);
    }

    function queueOrRevertInternal(address target, uint value, string memory signature, bytes memory data, uint eta) internal {
        require(!timelock.queuedTransactions(keccak256(abi.encode(target, value, signature, data, eta))), "GovernorBravo::queueOrRevertInternal: identical proposal action already queued at eta");
        timelock.queueTransaction(target, value, signature, data, eta);
    }

    /**
      * @notice Executes a queued proposal if eta has passed
      * @param proposalId The id of the proposal to execute
      */
    function execute(uint proposalId) external payable {
        require(state(proposalId) == ProposalState.Queued, "GovernorBravo::execute: proposal can only be executed if it is queued");
        Proposal storage proposal = proposals[proposalId];
        proposal.executed = true;
        for (uint i = 0; i < proposal.targets.length; i++) {
            timelock.executeTransaction.value(proposal.values[i])(proposal.targets[i], proposal.values[i], proposal.signatures[i], proposal.calldatas[i], proposal.eta);
        }
        emit ProposalExecuted(proposalId);
    }

    /**
      * @notice Cancels a proposal only if sender is the proposer, or proposer delegates dropped below proposal threshold
      * @param proposalId The id of the proposal to cancel
      */
    function cancel(uint proposalId) external {
        require(state(proposalId) != ProposalState.Executed, "GovernorBravo::cancel: cannot cancel executed proposal");

        Proposal storage proposal = proposals[proposalId];
        require(msg.sender == proposal.proposer || staking.votingBalanceOfNow(proposal.proposer) < proposalThreshold() || msg.sender == guardian, "GovernorBravo::cancel: proposer above threshold");

        proposal.canceled = true;
        for (uint i = 0; i < proposal.targets.length; i++) {
            timelock.cancelTransaction(proposal.targets[i], proposal.values[i], proposal.signatures[i], proposal.calldatas[i], proposal.eta);
        }

        emit ProposalCanceled(proposalId);
    }

    /**
      * @notice Gets the current voting quroum
      * @return The number of votes in support of a proposal required in order for a quorum to be reached and for a vote to succeed
      */
    function quorumVotes() public view returns (uint256) {
        uint256 totalSupply = IERC20(0x0De05F6447ab4D22c8827449EE4bA2D5C288379B) // OOKI
            .totalSupply();
        return totalSupply * quorumPercentage / 1e20;
    }

    /**
      * @notice Gets the current proposal threshold
      * @return The number of votes required to create new proposal
      */
    function proposalThreshold() public view returns (uint256) {
        uint256 totalSupply = IERC20(0x0De05F6447ab4D22c8827449EE4bA2D5C288379B) // OOKI
            .totalSupply();
        return totalSupply * proposalThresholdPercentage / 1e20;
    }

    /**
      * @notice Gets actions of a proposal
      * @param proposalId the id of the proposal
      * @return Targets, values, signatures, and calldatas of the proposal actions
      */
    function getActions(uint proposalId) external view returns (address[] memory targets, uint[] memory values, string[] memory signatures, bytes[] memory calldatas) {
        Proposal storage p = proposals[proposalId];
        return (p.targets, p.values, p.signatures, p.calldatas);
    }

    /**
      * @notice Gets the receipt for a voter on a given proposal
      * @param proposalId the id of proposal
      * @param voter The address of the voter
      * @return The voting receipt
      */
    function getReceipt(uint proposalId, address voter) external view returns (Receipt memory) {
        return proposals[proposalId].receipts[voter];
    }

    /**
      * @notice Gets the state of a proposal
      * @param proposalId The id of the proposal
      * @return Proposal state
      */
    function state(uint proposalId) public view returns (ProposalState) {
        require(proposalCount >= proposalId && proposalId > initialProposalId, "GovernorBravo::state: invalid proposal id");
        Proposal storage proposal = proposals[proposalId];
        if (proposal.canceled) {
            return ProposalState.Canceled;
        } else if (block.number <= proposal.startBlock) {
            return ProposalState.Pending;
        } else if (block.number <= proposal.endBlock) {
            return ProposalState.Active;
        } else if (proposal.forVotes <= proposal.againstVotes || proposal.forVotes < quorumVotesForProposal[proposalId]) {
            return ProposalState.Defeated;
        } else if (proposal.eta == 0) {
            return ProposalState.Succeeded;
        } else if (proposal.executed) {
            return ProposalState.Executed;
        } else if (block.timestamp >= add256(proposal.eta, timelock.GRACE_PERIOD())) {
            return ProposalState.Expired;
        } else {
            return ProposalState.Queued;
        }
    }

    /**
      * @notice Cast a vote for a proposal
      * @param proposalId The id of the proposal to vote on
      * @param support The support value for the vote. 0=against, 1=for, 2=abstain
      */
    function castVote(uint proposalId, uint8 support) external {
        emit VoteCast(msg.sender, proposalId, support, castVoteInternal(msg.sender, proposalId, support), "");
    }

    /**
      * @notice Cast a vote for a proposal with a reason
      * @param proposalId The id of the proposal to vote on
      * @param support The support value for the vote. 0=against, 1=for, 2=abstain
      * @param reason The reason given for the vote by the voter
      */
    function castVoteWithReason(uint proposalId, uint8 support, string calldata reason) external {
        emit VoteCast(msg.sender, proposalId, support, castVoteInternal(msg.sender, proposalId, support), reason);
    }

    /**
      * @notice Cast a vote for a proposal by signature
      * @dev External function that accepts EIP-712 signatures for voting on proposals.
      */
    function castVoteBySig(uint proposalId, uint8 support, uint8 v, bytes32 r, bytes32 s) public {
        bytes32 domainSeparator = keccak256(abi.encode(DOMAIN_TYPEHASH, keccak256(bytes(name)), getChainIdInternal(), address(this)));
        bytes32 structHash = keccak256(abi.encode(BALLOT_TYPEHASH, proposalId, support));
        bytes32 digest = keccak256(abi.encodePacked("\x19\x01", domainSeparator, structHash));
        address signatory = ecrecover(digest, v, r, s);
        require(signatory != address(0), "GovernorBravo::castVoteBySig: invalid signature");
        emit VoteCast(signatory, proposalId, support, castVoteInternal(signatory, proposalId, support), "");
    }


    /**
      * @dev Allows batching to castVote function
      */
    function castVotes(uint[] calldata proposalIds, uint8[] calldata supportVals) external {
        require(proposalIds.length == supportVals.length, "count mismatch");
        for (uint256 i = 0; i < proposalIds.length; i++) {
            emit VoteCast(msg.sender, proposalIds[i], supportVals[i], castVoteInternal(msg.sender, proposalIds[i], supportVals[i]), "");
        }
    }

    /**
      * @dev Allows batching to castVoteWithReason function
      */
    function castVotesWithReason(uint[] calldata proposalIds, uint8[] calldata supportVals, string[] calldata reasons) external {
        require(proposalIds.length == supportVals.length && proposalIds.length == reasons.length, "count mismatch");
        for (uint256 i = 0; i < proposalIds.length; i++) {
            emit VoteCast(msg.sender, proposalIds[i], supportVals[i], castVoteInternal(msg.sender, proposalIds[i], supportVals[i]), reasons[i]);
        }
    }

    /**
      * @dev Allows batching to castVoteBySig function
      */
    function castVotesBySig(uint[] calldata proposalIds, uint8[] calldata supportVals, uint8[] calldata vs, bytes32[] calldata rs, bytes32[] calldata ss) external {
        require(proposalIds.length == supportVals.length && proposalIds.length == vs.length && proposalIds.length == rs.length && proposalIds.length == ss.length, "count mismatch");
        for (uint256 i = 0; i < proposalIds.length; i++) {
            castVoteBySig(proposalIds[i], supportVals[i], vs[i], rs[i], ss[i]);
        }
    }

    /**
      * @notice Internal function that caries out voting logic
      * @param voter The voter that is casting their vote
      * @param proposalId The id of the proposal to vote on
      * @param support The support value for the vote. 0=against, 1=for, 2=abstain
      * @return The number of votes cast
      */
    function castVoteInternal(address voter, uint proposalId, uint8 support) internal returns (uint96) {
        require(state(proposalId) == ProposalState.Active, "GovernorBravo::castVoteInternal: voting is closed");
        require(support <= 2, "GovernorBravo::castVoteInternal: invalid vote type");
        Proposal storage proposal = proposals[proposalId];
        Receipt storage receipt = proposal.receipts[voter];
        require(receipt.hasVoted == false, "GovernorBravo::castVoteInternal: voter already voted");
        // 2**96-1 is greater than total supply of OOKI thus guaranteeing it won't ever overflow
        uint96 votes = uint96(staking.votingBalanceOf(voter, proposalId));

        if (support == 0) {
            proposal.againstVotes = add256(proposal.againstVotes, votes);
        } else if (support == 1) {
            proposal.forVotes = add256(proposal.forVotes, votes);
        } else if (support == 2) {
            proposal.abstainVotes = add256(proposal.abstainVotes, votes);
        }

        receipt.hasVoted = true;
        receipt.support = support;
        receipt.votes = votes;

        return votes;
    }

    /**
      * @notice Admin function for setting the voting delay
      * @param newVotingDelay new voting delay, in blocks
      */
    function __setVotingDelay(uint newVotingDelay) external {
        require(msg.sender == admin, "GovernorBravo::__setVotingDelay: admin only");
        require(newVotingDelay >= MIN_VOTING_DELAY && newVotingDelay <= MAX_VOTING_DELAY, "GovernorBravo::__setVotingDelay: invalid voting delay");
        uint oldVotingDelay = votingDelay;
        votingDelay = newVotingDelay;

        emit VotingDelaySet(oldVotingDelay, votingDelay);
    }

    /**
      * @notice Admin function for setting the voting period
      * @param newVotingPeriod new voting period, in blocks
      */
    function __setVotingPeriod(uint newVotingPeriod) external {
        require(msg.sender == admin, "GovernorBravo::__setVotingPeriod: admin only");
        require(newVotingPeriod >= MIN_VOTING_PERIOD && newVotingPeriod <= MAX_VOTING_PERIOD, "GovernorBravo::__setVotingPeriod: invalid voting period");
        uint oldVotingPeriod = votingPeriod;
        votingPeriod = newVotingPeriod;

        emit VotingPeriodSet(oldVotingPeriod, votingPeriod);
    }

    /**
      * @notice Admin function for setting the quorum percentage
      * @param newQuorumPercentage new quorum percentage
      */
    function __setQuorumPercentage(uint newQuorumPercentage) external {
        require(msg.sender == admin, "GovernorBravo::__setQuorumPercentage: admin only");
        require(newQuorumPercentage >= MIN_QUORUM_PERCENTAGE && newQuorumPercentage <= MAX_QUORUM_PERCENTAGE, "GovernorBravo::__setQuorumPercentage: invalid quorum percentage");
        uint oldQuorumPercentage = quorumPercentage;
        quorumPercentage = newQuorumPercentage;

        emit QuorumPercentageSet(oldQuorumPercentage, newQuorumPercentage);
    }

    /**
      * @notice Admin function for setting the staking address
      * @param newStaking address of new staking
      */
    function __setStaking(address newStaking) external {
        require(msg.sender == admin, "GovernorBravo::__setStaking: admin only");
        require(newStaking != address(0) , "GovernorBravo::__setStaking: invalid address");
        address oldStaking = address(staking);
        staking = StakingInterface(newStaking);

        emit StakingAddressSet(oldStaking, newStaking);
    }

    /**
      * @notice Admin function for setting the proposal threshold
      * @dev newProposalThresholdPercentage must be greater than the hardcoded min
      * @param newProposalThresholdPercentage new proposal threshold
      */
    function __setProposalThresholdPercentage(uint newProposalThresholdPercentage) external {
        require(msg.sender == admin, "GovernorBravo::__setProposalThreshold: admin only");
        require(newProposalThresholdPercentage >= MIN_PROPOSAL_THRESHOLD && newProposalThresholdPercentage <= MAX_PROPOSAL_THRESHOLD, "GovernorBravo::__setProposalThreshold: invalid proposal threshold");
        uint oldProposalThresholdPercentage = proposalThresholdPercentage;
        proposalThresholdPercentage = newProposalThresholdPercentage;

        emit ProposalThresholdSet(oldProposalThresholdPercentage, proposalThresholdPercentage);
    }

    /**
      * @notice Begins transfer of admin rights. The newPendingAdmin must call `__acceptLocalAdmin` to finalize the transfer.
      * @dev Admin function to begin change of admin. The newPendingAdmin must call `__acceptLocalAdmin` to finalize the transfer.
      * @param newPendingAdmin New pending admin.
      */
    function __setPendingLocalAdmin(address newPendingAdmin) external {
        // Check caller = admin
        require(msg.sender == admin, "GovernorBravo:__setPendingLocalAdmin: admin only");

        // Save current value, if any, for inclusion in log
        address oldPendingAdmin = pendingAdmin;

        // Store pendingAdmin with value newPendingAdmin
        pendingAdmin = newPendingAdmin;

        // Emit NewPendingAdmin(oldPendingAdmin, newPendingAdmin)
        emit NewPendingAdmin(oldPendingAdmin, newPendingAdmin);
    }

    /**
      * @notice Accepts transfer of admin rights. msg.sender must be pendingAdmin
      * @dev Admin function for pending admin to accept role and update admin
      */
    function __acceptLocalAdmin() external {
        // Check caller is pendingAdmin and pendingAdmin ≠ address(0)
        require(msg.sender == pendingAdmin && msg.sender != address(0), "GovernorBravo:__acceptLocalAdmin: pending admin only");

        // Save current values for inclusion in log
        address oldAdmin = admin;
        address oldPendingAdmin = pendingAdmin;

        // Store admin with value pendingAdmin
        admin = pendingAdmin;

        // Clear the pending value
        pendingAdmin = address(0);

        emit NewAdmin(oldAdmin, admin);
        emit NewPendingAdmin(oldPendingAdmin, pendingAdmin);
    }

    function __changeGuardian(address guardian_) public {
        require(msg.sender == guardian, "GovernorBravo::__changeGuardian: sender must be gov guardian");
        require(guardian_ != address(0), "GovernorBravo::__changeGuardian: not allowed");
        guardian = guardian_;
    }

    function __acceptAdmin() public {
        require(msg.sender == guardian, "GovernorBravo::__acceptAdmin: sender must be gov guardian");
        timelock.acceptAdmin();
    }

    function __abdicate() public {
        require(msg.sender == guardian, "GovernorBravo::__abdicate: sender must be gov guardian");
        guardian = address(0);
    }

    function __queueSetTimelockPendingAdmin(address newPendingAdmin, uint eta) public {
        require(msg.sender == guardian, "GovernorBravo::__queueSetTimelockPendingAdmin: sender must be gov guardian");
        timelock.queueTransaction(address(timelock), 0, "setPendingAdmin(address)", abi.encode(newPendingAdmin), eta);
    }

    function __executeSetTimelockPendingAdmin(address newPendingAdmin, uint eta) public {
        require(msg.sender == guardian, "GovernorBravo::__executeSetTimelockPendingAdmin: sender must be gov guardian");
        timelock.executeTransaction(address(timelock), 0, "setPendingAdmin(address)", abi.encode(newPendingAdmin), eta);
    }

    function add256(uint256 a, uint256 b) internal pure returns (uint) {
        uint c = a + b;
        require(c >= a, "addition overflow");
        return c;
    }

    function sub256(uint256 a, uint256 b) internal pure returns (uint) {
        require(b <= a, "subtraction underflow");
        return a - b;
    }

    function getChainIdInternal() internal pure returns (uint) {
        uint chainId;
        assembly { chainId := chainid() }
        return chainId;
    }
}