pragma solidity ^0.8.0;
import "../IOrderBook.sol";

contract OrderBookEvents {
    event OrderCancelled(address indexed trader, bytes32 orderID);
    event OrderPlaced(
        address indexed trader,
        IOrderBook.OrderType indexed OrderType,
        uint256 indexed execPrice,
        bytes32 orderID,
        address collateralTokenAddress,
        address loanTokenAddress
    );
    event OrderExecuted(address indexed trader, bytes32 orderID);
    event OrderAmended(
        address indexed trader,
        IOrderBook.OrderType indexed OrderType,
        uint256 indexed execPrice,
        bytes32 orderID,
        address collateralTokenAddress,
        address loanTokenAddress
    );
}