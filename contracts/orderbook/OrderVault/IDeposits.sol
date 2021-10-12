pragma solidity ^0.8.4;

interface IDeposits {
    function deposit(
        uint256 orderID,
        uint256 TokenAmount,
        address trader,
        address token
    ) external;

    function withdraw(address trader, uint256 orderID) external;

    function getDeposit(address trader, uint256 orderID)
        external
        view
        returns (uint256);

    function getTokenUsed(address trader, uint256 orderID)
        external
        view
        returns (address);
}
