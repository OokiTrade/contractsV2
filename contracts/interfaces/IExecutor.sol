pragma solidity >=0.5.0 <0.9.0;

interface IExecutor {
    function executeMessage(bytes calldata message) external payable;
}