pragma solidity >=0.5.17 <0.9.0;

interface IBalancerPool {
    function getRate() external view returns (uint256);
}