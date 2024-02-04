pragma solidity ^0.8.0;

interface IDeposits {
    function deposit(
        bytes32 orderID,
        uint256 tokenAmount,
        address trader,
        address token
    ) external;

    function depositGasToken(address trader) external payable;

    function withdraw(bytes32 orderID) external;

    function withdrawToTrader(address trader, bytes32 orderID) external;

    function refund(bytes32 orderID, uint256 amount) external;

    function partialWithdraw(
        address trader,
        bytes32 orderID,
        uint256 amount
    ) external;

    function getDeposit(bytes32 orderID)
        external
        view
        returns (uint256);

    function getTokenUsed(bytes32 orderID)
        external
        view
        returns (address);
}
