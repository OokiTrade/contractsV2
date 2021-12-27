pragma solidity ^0.8.0;

import "../utils/FxBaseChildTunnel.sol";
import "../proxies/0_8/Upgradeable_0_8.sol";

contract ReceiveDataPolygon is Upgradeable_0_8, FxBaseChildTunnel {
	event ProposalExecuted();
	event ExecuteTransaction(address target, uint value, string signature, bytes data, uint eta);
    struct Proposal {
        address[] targets;
        uint[] values;
        string[] signatures;
        bytes[] calldatas;
		uint eta;
    }
	
	function _execute(Proposal memory proposal) internal {
		for (uint i = 0; i < proposal.targets.length; i++) {
			_executeTransaction(proposal.targets[i], proposal.values[i], proposal.signatures[i], proposal.calldatas[i], proposal.eta);
		}
		emit ProposalExecuted();
	}

    function _executeTransaction(address target, uint value, string memory signature, bytes memory data, uint eta) internal returns (bytes memory) {
        bytes memory callData;

        if (bytes(signature).length == 0) {
            callData = data;
        } else {
            callData = abi.encodePacked(bytes4(keccak256(bytes(signature))), data);
        }

        // solium-disable-next-line security/no-call-value
        (bool success, bytes memory returnData) = target.call{value:value}(callData);
        require(success, "Timelock::executeTransaction: Transaction execution reverted.");

        emit ExecuteTransaction(target, value, signature, data, eta);

        return returnData;
    }
	
	function _processMessageFromRoot(
		uint256 stateId,
		address sender,
		bytes memory message
	) internal virtual override validateSender(sender){
		(Proposal memory proposed) = abi.decode(message,(Proposal));
		_execute(proposed);
	}
	

}