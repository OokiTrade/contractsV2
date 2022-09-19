pragma solidity ^0.8.0;

import "../core/State.sol";


contract Receiver is State {
    function initialize(
        address target)
        external
        onlyOwner
    {
        _setTarget(0, target);
    }
    fallback() external payable {

    }
}