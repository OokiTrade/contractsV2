pragma solidity 0.8.9;

import "../proxies/0_8/Upgradeable_0_8.sol";
import "./ITimelock.sol";

contract TimelockMessageReceiver is Upgradeable_0_8 {
    modifier onlyMessageBus() {
        require(msg.sender == messageBus, "caller is not message bus");
        _;
    }
	
    struct ProposalSlim {
        address[] targets;
        string[] signatures;
        uint256[] values;
        bytes[] calldatas;
        uint256 eta;
        bool executed;
    }

    event Executed(MsgType msgType, bytes32 id, TxStatus status);

    /// @notice An event emitted when a proposal has been queued in the Timelock
    event ProposalQueued(uint256 id, uint256 eta);

    /// @notice An event emitted when a proposal has been executed in the Timelock
    event ProposalExecuted(uint256 id);

    /// @notice The official record of all proposals ever proposed
    mapping(uint256 => ProposalSlim) public proposals;

    address public liquidityBridge; // liquidity bridge address

    ITimelock public timelock;
    address public timelockEthereum;
    address public messageBus;
	
    /**
     * @notice Queues a proposal of state succeeded
     * @param proposalId The id of the proposal to queue
     */
    function queue(uint256 proposalId, ProposalSlim memory proposal) public {
        require(
            msg.sender == address(this),
            "TimelockMessageReceiver::queue: can only be called by Timelock on Ethereum."
        );
        proposals[proposalId] = proposal;
        uint256 eta = block.timestamp + timelock.delay();
        for (uint256 i = 0; i < proposal.targets.length; i++) {
            queueOrRevertInternal(
                proposal.targets[i],
                proposal.values[i],
                proposal.signatures[i],
                proposal.calldatas[i],
                eta
            );
        }
        proposals[proposalId].eta = eta;
        emit ProposalQueued(proposalId, eta);
    }

    function queueOrRevertInternal(
        address target,
        uint256 value,
        string memory signature,
        bytes memory data,
        uint256 eta
    ) internal {
        require(
            !timelock.queuedTransactions(
                keccak256(abi.encode(target, value, signature, data, eta))
            ),
            "GovernorBravo::queueOrRevertInternal: identical proposal action already queued at eta"
        );
        timelock.queueTransaction(target, value, signature, data, eta);
    }

    /**
     * @notice Executes a queued proposal if eta has passed
     * @param proposalId The id of the proposal to execute
     */
    function execute(uint256 proposalId) external payable {
        ProposalSlim storage proposal = proposals[proposalId];
        proposal.executed = true;
        for (uint256 i = 0; i < proposal.targets.length; i++) {
            timelock.executeTransaction{value: proposal.values[i]}(
                proposal.targets[i],
                proposal.values[i],
                proposal.signatures[i],
                proposal.calldatas[i],
                proposal.eta
            );
        }
        emit ProposalExecuted(proposalId);
    }

    function computeMessageOnlyId(
        RouteInfo calldata _route,
        bytes calldata _message
    ) private pure returns (bytes32) {
        return
            keccak256(
                abi.encodePacked(
                    MsgType.MessageOnly,
                    _route.sender,
                    _route.receiver,
                    _route.srcChainId,
                    _message
                )
            );
    }

    function executeMessage(address sender, uint64 chainId, bytes memory _message)
        private
        returns (bool)
    {
        if (sender != timelockEthereum) {
            return false;
        }
		(address receiver, _message) = abi.decode(_message, (address, bytes));
        (bool ok, bytes memory res) = receiver.call{
            value: msg.value
        }(_message);
        if (ok) {
            bool success = abi.decode((res), (bool));
            return success;
        }
        return false;
    }

    function updateSettings(address _liquidityBridge) public onlyOwner {
        liquidityBridge = _liquidityBridge;
    }

    function setMessageBus(address _messageBus) public onlyOwner {
	    messageBus = _messageBus;
	}

    function setTimelocks(address timelockEthereum_, ITimelock timelock_)
        public
        onlyOwner
    {
        timelockEthereum = timelockEthereum_;
        timelock = timelock_;
    }
}
