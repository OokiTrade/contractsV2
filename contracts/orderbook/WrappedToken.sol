pragma solidity ^0.8.0;

abstract contract WrappedToken {
    function deposit() public payable virtual;
}
