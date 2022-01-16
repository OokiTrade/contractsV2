pragma solidity 0.8.9;

import "../proxies/0_8/Upgradeable_0_8.sol";
import "./ITimelock.sol";
import "@celer/contracts/interfaces/IBridge.sol";
import "@celer/contracts/interfaces/IOriginalTokenVault.sol";
import "@celer/contracts/interfaces/IPeggedTokenBridge.sol";
import "@celer/contracts/message/interfaces/IMessageReceiverApp.sol";

contract TimelockMessageReceiver is Upgradeable_0_8 {
    struct ProposalSlim {
        address[] targets;
        string[] signatures;
        uint256[] values;
        bytes[] calldatas;
        uint256 eta;
        bool executed;
    }
    struct TransferInfo {
        TransferType t;
        address sender;
        address receiver;
        address token;
        uint256 amount;
        uint64 seqnum; // only needed for LqWithdraw
        uint64 srcChainId;
        bytes32 refId;
    }

    struct RouteInfo {
        address sender;
        address receiver;
        uint64 srcChainId;
    }

    enum TxStatus {
        Null,
        Success,
        Fail,
        Fallback
    }

    enum TransferType {
        Null,
        LqSend, // send through liquidity bridge
        LqWithdraw, // withdraw from liquidity bridge
        PegMint, // mint through pegged token bridge
        PegWithdraw // withdraw from original token vault
    }

    enum MsgType {
        MessageWithTransfer,
        MessageOnly
    }
    event Executed(MsgType msgType, bytes32 id, TxStatus status);

    /// @notice An event emitted when a proposal has been queued in the Timelock
    event ProposalQueued(uint256 id, uint256 eta);

    /// @notice An event emitted when a proposal has been executed in the Timelock
    event ProposalExecuted(uint256 id);

    /// @notice The official record of all proposals ever proposed
    mapping(uint256 => ProposalSlim) public proposals;

    mapping(bytes32 => TxStatus) public executedMessages;

    address public liquidityBridge; // liquidity bridge address

    ITimelock public timelock;
    address public timelockEthereum;

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

    //Message Handling

    function executeMessage(
        bytes calldata _message,
        RouteInfo calldata _route,
        bytes[] calldata _sigs,
        address[] calldata _signers,
        uint256[] calldata _powers
    ) external payable {
        // For message without associated token transfer, message Id is computed through message info,
        // in order to guarantee that each message can only be applied once
        bytes32 messageId = computeMessageOnlyId(_route, _message);
        require(
            executedMessages[messageId] == TxStatus.Null,
            "message already executed"
        );

        bytes32 domain = keccak256(
            abi.encodePacked(block.chainid, address(this), "Message")
        );
        IBridge(liquidityBridge).verifySigs(
            abi.encodePacked(domain, messageId),
            _sigs,
            _signers,
            _powers
        );
        TxStatus status;
        bool success = executeMessage(_route, _message);
        if (success) {
            status = TxStatus.Success;
        } else {
            status = TxStatus.Fail;
        }
        executedMessages[messageId] = status;
        emit Executed(MsgType.MessageOnly, messageId, status);
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

    function executeMessage(RouteInfo calldata _route, bytes calldata _message)
        private
        returns (bool)
    {
        if (_route.sender != timelockEthereum) {
            return false;
        }
        (bool ok, bytes memory res) = address(_route.receiver).call{
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

    function setTimelocks(address timelockEthereum_, ITimelock timelock_)
        public
        onlyOwner
    {
        timelockEthereum = timelockEthereum_;
        timelock = timelock_;
    }
}
