pragma solidity >=0.5.0 <0.9.0;

interface IyVault {
    function pricePerShare() external view returns (uint256);
}