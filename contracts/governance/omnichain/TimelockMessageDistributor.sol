pragma solidity ^0.8.0;

import "../../utils/MessageSenderLib.sol";
import "@celer/contracts/message/interfaces/IMessageBus.sol";
import "../../governance/PausableGuardian_0_8.sol";

contract TimelockMessageDistributor is PausableGuardian_0_8 {
    mapping(uint64 => address) public chainIdToDest;

    IMessageBus public messageBus;

    event SetMessageBus(address newMessageBus);

    event SendMessage(uint64 indexed destChainId, address indexed destAddress, bytes message);

    event SetDestinationForChainId(uint64 indexed destChainId, address destination);

    function setMessageBus(IMessageBus msgBus) external onlyGuardian {
        messageBus = msgBus;
        emit SetMessageBus(address(messageBus));
    }

    function setDestForID(uint64 chainId, address destination) external onlyGuardian {
        chainIdToDest[chainId] = destination;
        emit SetDestinationForChainId(chainId, destination);
    }

    function sendMessageToChain(uint64 chainId, bytes memory message) external payable onlyGuardian {
        address destAddress = chainIdToDest[chainId];
        MessageSenderLib.sendMessage(destAddress, chainId, message, address(messageBus), computeFee(message));
        emit SendMessage(chainId, destAddress, message);
    }

    function computeFee(bytes memory message) public view returns (uint256) {
        return messageBus.calcFee(message);
    }
}