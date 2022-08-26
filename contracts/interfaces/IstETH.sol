pragma solidity >=0.5.17 <0.9.0;

interface IstETH {
    function submit(address _referral) external payable returns (uint256);
}