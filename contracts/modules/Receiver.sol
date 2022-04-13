pragma solidity 0.5.17;

import "../core/State.sol";


contract Receiver is State {
    function initialize(
        address target)
        external
        onlyOwner
    {
        _setTarget(0, target);
    }
    function() external payable {

    }
}