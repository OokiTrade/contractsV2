pragma solidity >=0.5.17 <0.9.0;

interface IwstETH {
    function wrap(uint256 _stETHAmount) external returns(uint256);
    function unwrap(uint256 _wstETHAmount) external returns(uint256);
    function getStETHByWstETH(uint256 _wstETHAmount) external view returns(uint256);
    function getWstETHBystETH(uint256 _stETHAmount) external view returns(uint256);
}