pragma solidity ^0.8.0;

interface IDeposits {
    function deposit(
        bytes32 orderID,
        uint256 TokenAmount,
        address trader,
        address token
    ) external;

    function withdraw(address trader, bytes32 orderID) external;

    function withdrawToTrader(address trader, bytes32 orderID) external;

    function partialWithdraw(
        address trader,
        bytes32 orderID,
        uint256 amount
    ) external;

    function getDeposit(address trader, bytes32 orderID)
        external
        view
        returns (uint256);

    function getTokenUsed(address trader, bytes32 orderID)
        external
        view
        returns (address);
}
