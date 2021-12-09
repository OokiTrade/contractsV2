pragma solidity ^0.8.4;

abstract contract WrappedToken {
    function deposit() public payable virtual;
}
