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
        bytes loanDataBytes;
    }

    function vault() external view returns(address);

    function protocol() external view returns(address);

    function MIN_AMOUNT_IN_USDC() external view returns(uint256);

    function placeOrder(Order calldata order) external;

    function amendOrder(Order calldata order) external;

    function cancelOrder(bytes32 orderID) external;

    function cancelOrderProtocol(bytes32 orderID) external;

    function changeStopType(bool stopType) external;

    function recoverFundsFromFailedOrder(bytes32 orderID) external;

    function getFeed() external view returns (address);

    function getDexRate(address srcToken, address destToken, bytes calldata payload, uint256 amountIn) external returns(uint256);

    function clearOrder(bytes32 orderID) external view returns (bool);

    function prelimCheck(bytes32 orderID) external returns (bool);

    function queryRateReturn(address srcToken, address destToken, uint256 amount) external view returns(uint256);

    function priceCheck(address srcToken, address destToken, bytes calldata payload) external returns(bool);

    function executeOrder(bytes32 orderID) external;

    function adjustAllowance(address[] calldata spenders, address[] calldata tokens) external;

    function getActiveOrders(address trader) external view returns (Order[] memory);

    function getActiveOrdersLimited(address trader, uint256 start, uint256 end) external view returns (Order[] memory);

    function getOrderByOrderID(bytes32 orderID) external view returns (Order[] memory);

    function getActiveOrderIDs(address trader) external view returns (bytes32[] memory);

    function getTotalOrders(address trader) external view returns (uint256);

    function getTotalOrderIDs() external view returns (uint256);

    function getOrderIDs() external view returns (bytes32[] memory);

    function getOrders() external view returns (Order[] memory);

    function getOrderIDsLimited(uint256 start, uint256 end) external view returns (bytes32[] memory);

    function getOrdersLimited(uint256 start, uint256 end) external view returns (Order[] memory);
}
