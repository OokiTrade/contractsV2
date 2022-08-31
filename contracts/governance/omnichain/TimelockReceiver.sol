pragma solidity ^0.8.0;

import "../PausableGuardian_0_8.sol";
import "../../interfaces/IExecutor.sol";
contract TimelockReceiver is PausableGuardian_0_8 {
    enum ExecutionStatus {
        Success,
        Fail,
        Retry
    }

    address public messageBus;

    address public timelockDistributor;

    address public executor;

    event SetMessageBus(address newMessageBus);

    event SetTimeLockDistributor(address newTimeLockDistributor);

    event SetExecutor(address newExecutor);

    event MessageToBeExecuted(
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
            return ExecutionStatus.Success;
        } catch Error(string memory reason) {
            if (keccak256(bytes(reason)) == keccak256(bytes("insufficient funding"))) return ExecutionStatus.Retry;
            return ExecutionStatus.Fail;
        }catch {
            return ExecutionStatus.Fail;
        }

        emit MessageToBeExecuted(exec, message, block.timestamp);
    }

}