pragma solidity ^0.8.4;
import "./Storage/OrderBookStorage.sol";
import "./Storage/OrderBookEvents.sol";

contract OrderBookProxy is OrderBookEvents, OrderBookStorage {
    mapping(bytes4 => address) internal implMatch;

    constructor(address bzx) {
        bZxRouterAddress = bzx;
    }

    fallback() external payable {
        if (gasleft() <= 2300) {
            return;
        }

        address impl = implMatch[msg.sig];

        bytes memory data = msg.data;
        assembly {
            let result := delegatecall(
                gas(),
                impl,
                add(data, 0x20),
                mload(data),
                0,
                0
            )
            let size := returndatasize()
            let ptr := mload(0x40)
            returndatacopy(ptr, 0, size)
            switch result
            case 0 {
                revert(ptr, size)
            }
            default {
                return(ptr, size)
            }
        }
    }

    function setTargets(bytes4[] calldata sigs, address[] calldata targets)
        public
        onlyOwner
    {
        require(sigs.length == targets.length);
        for (uint256 i = 0; i < targets.length; i++) {
            implMatch[sigs[i]] = targets[i];
        }
    }

    function getTarget(bytes4 sig) public view returns (address) {
        return implMatch[sig];
    }
}
