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

    /// Returns Deposits contract address
    /// @return vault Deposits Contract
    function vault() external view returns(address vault);

    /// Returns Protocol contract address
    /// @return protocol bZxProtocol Contract
    function protocol() external view returns(address protocol);

    /// Returns minimum trade size in USDC
    /// @return size USDC amount
    function MIN_AMOUNT_IN_USDC() external view returns(uint256 size);

    /// Places new Order
    /// @param order Order Struct
    function placeOrder(Order calldata order) external;

    /// Amends Order
    /// @param order Order Struct
    function amendOrder(Order calldata order) external;

    /// Cancels Order
    /// @param orderID ID of order to be canceled
    function cancelOrder(bytes32 orderID) external;

    /// Cancels Order
    /// @param orderID ID of order to be canceled
    function cancelOrderProtocol(bytes32 orderID) external;

    /// Changes stop type between index and dex price
    /// @param stopType true = index, false = dex price
    function changeStopType(bool stopType) external;

    /// Withdraws funds from a trade that failed
    /// @param orderID order ID for trade that failed to execute
    function recoverFundsFromFailedOrder(bytes32 orderID) external;

    /// Return price feed contract address
    /// @return priceFeed Price Feed Contract Address
    function getFeed() external view returns (address priceFeed);

    function getDexRate(address srcToken, address destToken, bytes calldata payload, uint256 amountIn) external returns(uint256);

    function clearOrder(bytes32 orderID) external view returns (bool);

    function getClearOrderList(uint start, uint end) external view returns (bool hasOrders, bytes memory payload);

    function getExecuteOrder(uint start, uint end) external returns (bytes32 ID);

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
