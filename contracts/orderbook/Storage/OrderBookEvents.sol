pragma solidity ^0.8.0;
import "../IOrderBook.sol";
import "../../governance/PausableGuardian_0_8.sol";
import "@openzeppelin-4.3.2/utils/structs/EnumerableSet.sol";

contract OrderBookEvents is PausableGuardian_0_8 {
    using EnumerableSet for EnumerableSet.Bytes32Set;
    mapping(bytes32 => IOrderBook.Order) internal _allOrders;
    mapping(bytes32 => uint256) internal _orderExpiration;
    mapping(address => EnumerableSet.Bytes32Set) internal _histOrders;
    mapping(address => bool) internal _useOracle;
    EnumerableSet.Bytes32Set internal _allOrderIDs;

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
