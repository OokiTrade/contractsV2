pragma solidity 0.5.17;

interface ICurvePoolRegistration {
    function addPool(
        address tokenPool,
        address[] calldata tokensInPool,
        uint128[] calldata tokenIDs
    ) external;

    function disablePool(address tokenPool) external;

    function CheckPoolValidity(address pool) external view returns (bool);
	
	function getPoolType(address tokenPool) external view returns (uint256);
}
