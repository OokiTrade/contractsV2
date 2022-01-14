pragma solidity 0.5.17;

interface ICurve {
    function find_pool_for_coins(
        address from,
        address to,
        uint256 i
    ) external view returns (address);

    function pool_count() external view returns (uint256);

    function pool_list(uint256 i) external view returns (address);

    function add_liquidity(
        uint256[2] calldata amounts,
        uint256 min_out,
        address recv
    ) external returns (uint256);

    function get_balances() external view returns (uint256[2] memory);

    function fee() external view returns (uint256);

    function exchange(
        int128 i,
        int128 j,
        uint256 dx,
        uint256 dy
    ) external returns (uint256);
}
