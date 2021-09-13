pragma solidity ^0.8.4;
import "./OrderBookStorage.sol";
import "./OrderBookEvents.sol";

contract OrderBookProxy is OrderBookEvents, OrderBookStorage{
	mapping(bytes4 => address) internal implMatch;
    constructor(address bzx){
        owner = msg.sender;
		bZxRouterAddress = bzx;
    }

	function transferOwner(address nOwner) public{
		require(msg.sender == owner);
		owner = nOwner;
	}
    fallback() external payable {
        if (gasleft() <= 2300) {
            return;
        }

        address impl = implMatch[msg.sig];

        bytes memory data = msg.data;
        assembly {
            let result := delegatecall(gas(), impl, add(data, 0x20), mload(data), 0, 0)
            let size := returndatasize()
            let ptr := mload(0x40)
            returndatacopy(ptr, 0, size)
            switch result
            case 0 { revert(ptr, size) }
            default { return(ptr, size) }
        }
    }
	function setTargets(bytes4[] calldata sigs, address[] calldata targets) public{
		require(msg.sender == owner);
		require(sigs.length == targets.length);
		for(uint i = 0;i<targets.length;i++){
			implMatch[sigs[i]] = targets[i];
		}
	}
	function getTarget(bytes4 sig) public view returns(address){
		return implMatch[sig];
	}
		
}