pragma solidity ^0.8.0;

import "@celer/contracts/message/messagebus/MessageBus.sol";
import "../proxies/0_8/Upgradeable_0_8.sol";

contract TimelockMessageSender is Upgradeable_0_8 {
    address public messageBus;
    mapping(uint64 => address) public destChainTimeLock;
    uint256 public constant FEE = 0; //to be set

    function sendToChain(uint64 chainID, bytes memory calldataQueue)
        public
        onlyOwner
    {
        MessageBus(messageBus).sendMessage{value: FEE}(destChainTimeLock[chainID], chainID, calldataQueue);
    }

    function setMessageBus(address messageBus_) public onlyOwner {
        messageBus = messageBus_;
    }

    function addChain(uint64 chainId, address chainTimelock) public onlyOwner {
        destChainTimeLock[chainId] = chainTimelock;
    }
}
