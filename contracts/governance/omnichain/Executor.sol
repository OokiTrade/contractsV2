pragma solidity ^0.8.0;

import "../PausableGuardian_0_8.sol";

contract Executor is PausableGuardian_0_8 {
    struct TxnData {
        address to;
        bytes data;
        uint256 etherSendAmount;
    }

    event MessageExecute(
        bytes message,
        uint256 timestamp
    );
    function executeMessage(bytes calldata message) external payable onlyGuardian {
        TxnData[] memory transactions = abi.decode(message, (TxnData[]));
        uint256 unspentBalance = msg.value;
        for (uint i; i < transactions.length;) {
            if (transactions[i].etherSendAmount > unspentBalance) {
                revert("insufficient funding");
            }
            unspentBalance -= transactions[i].etherSendAmount;
            (bool success, ) = transactions[i].to.call{value:transactions[i].etherSendAmount}(transactions[i].data);
            require(success, "fail");
            unchecked { ++i; }
        }

        emit MessageExecute(message, block.timestamp);
    }
}