pragma solidity >=0.5.17;

interface ICurveSwaps {
    function get_exchange_amount(address pool, address from, address to, uint256 amount) external view returns(uint256);
    function get_input_amount(address pool,address from, address to, uint256 amount) external view returns(uint256);
    function exchange(address pool, address from, address to, uint256 amount, uint256 minRecv, address receiver) external returns(uint256);
}

interface ICurveProvider {
    function get_address(uint256 i) external view returns (address);
}