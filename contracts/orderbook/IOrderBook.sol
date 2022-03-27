pragma solidity ^0.8.0;

interface IOrderBook {
    enum OrderType {
        LIMIT_OPEN,
        LIMIT_CLOSE,
        MARKET_STOP
    }

    enum OrderStatus {
        ACTIVE,
        CANCELLED,
        EXECUTED
    }

    struct Order {
        bytes32 loanID;
        bytes32 orderID;
        uint256 amountReceived;
        uint256 leverage;
        uint256 loanTokenAmount;
        uint256 collateralTokenAmount;
        address trader;
        address iToken;
        address loanTokenAddress;
        address base;
        OrderType orderType;
        OrderStatus status;
        uint64 timeTillExpiration;
        bool isCollateral;
        bytes loanDataBytes;
    }

    function placeOrder(Order calldata order) external;

    function amendOrder(Order calldata order) external;

    function cancelOrder(bytes32 orderID) external;

    function getSwapAddress() external view returns (address);

    function getFeed() external view returns (address);

    function getOrdersLimited(uint256 start, uint256 end) external view returns (Order[] memory);

    function getOrders() external view returns (Order[] memory);

    function getOrderByOrderID(bytes32 orderID) external view returns (Order[] memory);

    function getActiveOrders(address trader) external view returns (Order[] memory);

    function getActiveOrderIDs(address trader) external view returns (bytes32[] memory);

    function getActiveOrdersLimited(address trader, uint256 start, uint256 end) external view returns (Order[] memory);

    function getTotalOrders(address trader) external view returns (uint256);

    function executeOrder(bytes32 orderID) external;

    function cancelOrderProtocol(bytes32 orderID) external;

    function clearOrder(bytes32 orderID) external view returns (bool);

    function prelimCheck(bytes32 orderID) external returns (bool);

    function getOrderIDs() external view returns (bytes32[] memory);

    function getOrders() external view returns (Order[] memory);

    function getOrdersLimited(uint start, uint end) external view returns (Order[] memory);

    function getTotalOrderIDs() external view returns (uint256);

    function getOrderIDsLimited(uint256 start, uint256 end) external view returns (bytes32[] memory);
}
