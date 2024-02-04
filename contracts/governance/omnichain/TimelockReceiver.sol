pragma solidity ^0.8.0;

import "../PausableGuardian_0_8.sol";
import "../../interfaces/IExecutor.sol";
contract TimelockReceiver is PausableGuardian_0_8 {
    address public messageBus;

    address public timelockDistributor;

    address public executor;

    enum ExecutionStatus {
        Success,
        Fail,
        Retry
    }

    event SetMessageBus(address newMessageBus);

    event SetTimeLockDistributor(address newTimeLockDistributor);

    event SetExecutor(address newExecutor);

    event MessageExecuted(
        address indexed executor,
        bytes message,
        uint256 timestamp
    );

    event MessageFailed(
        address indexed executor,
        bytes message,
        uint256 timestamp
    );

    event MessageRetryable(
        address indexed executor,
        bytes message,
        uint256 timestamp
    );

    function setMessageBus(address msgBus) public onlyGuardian {
        messageBus = msgBus;

        emit SetMessageBus(msgBus);
    }

    function setTimelockDistributor(address distributor) public onlyGuardian {
        timelockDistributor = distributor;

        emit SetTimeLockDistributor(distributor);
    }

    function setExecutor(address exec) public onlyGuardian {
        executor = exec;

        emit SetExecutor(exec);
    }

    modifier onlyMessageBus() {
        require(msg.sender == messageBus, "unauthorized");_;
    }

    function executeMessage(
        address sender,
        uint64 srcChainId,
        bytes calldata message,
        address exec
    ) external payable onlyMessageBus returns (ExecutionStatus) {
        if (sender != timelockDistributor || srcChainId != 1) {
            return ExecutionStatus.Fail;
        }
        try IExecutor(executor).executeMessage{value: msg.value}(message) {
            emit MessageExecuted(exec, message, block.timestamp);
            return ExecutionStatus.Success;
        } catch Error(string memory reason) {
            if (keccak256(bytes(reason)) == keccak256(bytes("insufficient funding"))) {
                emit MessageRetryable(exec, message, block.timestamp);
                return ExecutionStatus.Retry;
            }
            emit MessageFailed(exec, message, block.timestamp);
            return ExecutionStatus.Fail;
        }catch {
            emit MessageFailed(exec, message, block.timestamp);
            return ExecutionStatus.Fail;
        }
    }

}