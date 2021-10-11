pragma solidity 0.5.17;

interface ICurvePoolRegistration {
    function addPool(
        address tokenPool,
        address[] calldata tokensInPool,
        uint128[] calldata tokenIDs
    ) external;

    function disablePool(address tokenPool) external;

    function CheckPoolValidity(address pool) external view returns (bool);

    function CheckTokenPoolValidity(address pool, address token)
        external
        view
        returns (bool);

    function GetTokenPoolID(address pool, address token)
        external
        view
        returns (uint128);
}
