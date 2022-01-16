pragma solidity ^0.8.0;

import "@celer/contracts/message/libraries/MessageSenderLib.sol";

contract TimelockMessagSender is Ownable {
    address public implementation;
    address public messageBus;
    mapping(uint64 => address) public destChainTimeLock;
    uint256 public constant FEE = 0; //to be set

    function sendToChain(uint64 chainID, bytes memory calldataQueue)
        public
        onlyOwner
    {
        MessageSenderLib.sendMessage(
            destChainTimeLock[chainID],
            chainID,
            calldataQueue,
            messageBus,
            FEE
        );
    }

    function setMessageBus(address messageBus_) public onlyOwner {
        messageBus = messageBus_;
    }

    function addChain(uint64 chainId, address chainTimelock) public onlyOwner {
        destChainTimeLock[chainId] = chainTimelock;
    }
}
