pragma solidity 0.5.17;

interface ICurve {
    function exchange(
        uint256 i,
        uint256 j,
        uint256 dx,
        uint256 min_dy
    ) external;
    function exchange_underlying(
        uint256 i,
        uint256 j,
        uint256 dx,
        uint256 min_dy
    ) external;
    function get_dy(
        uint256 i,
        uint256 j,
        uint256 dx
    ) external returns (uint256);
    function get_dy_underlying(
        uint256 i,
        uint256 j,
        uint256 dx
    ) external returns (uint256);
	function underlying_coins(
		uint256
	) external returns (address);
}
