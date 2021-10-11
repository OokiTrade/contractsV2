pragma solidity 0.5.17;

interface ICurve {
    function exchange(
        uint128 i,
        uint128 j,
        uint256 dx,
        uint256 min_dy
    ) external;

    function get_dy(
        uint128 i,
        uint128 j,
        uint256 dx
    ) external returns (uint256);
}
