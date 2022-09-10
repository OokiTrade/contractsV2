pragma solidity 0.5.17;

import "./LoanToken.sol";
import "../../../interfaces/ILoanTokenFactory.sol";

contract FactoryLoanToken is LoanToken {
    address factory;
    constructor()
        public
        LoanToken(address(0), address(0))
    {}

    function()
        external
        payable
    {
        if (gasleft() <= 2300) {
            return;
        }

        address target = _getTarget();
        bytes memory data = msg.data;
        require(ILoanTokenFactory(factory).isPaused(msg.data), "paused");
        assembly {
            let result := delegatecall(gas, target, add(data, 0x20), mload(data), 0, 0)
            let size := returndatasize
            let ptr := mload(0x40)
            returndatacopy(ptr, 0, size)
            switch result
            case 0 { revert(ptr, size) }
            default { return(ptr, size) }
        }
    }

    function _getTarget()
        internal
        returns (address)
    {
        return ILoanTokenFactory(factory).getTargetForLoanToken();
    }

}