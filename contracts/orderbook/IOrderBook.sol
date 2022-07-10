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

    /*
    Used values for different order types:
        LIMIT_OPEN:
            loanID
            orderID
            amountReceived
            leverage
            loanTokenAmount
            collateralTokenAmount
            trader
            iToken
            loanTokenAddress
            base
            orderType
            status
            timeTillExpiration
            loanDataBytes
        LIMIT_CLOSE and MARKET_STOP:
            loanID
            orderID
            amountReceived
            loanTokenAmount
            collateralTokenAmount
            trader
            iToken
            loanTokenAddress
            base
            orderType
            status
            timeTillExpiration
            loanDataBytes
    */
    struct Order {
        bytes32 loanID; //ID of the loan on OOKI protocol
        bytes32 orderID; //order ID
        uint256 amountReceived; //amount received from the trade executing. Denominated in base for limit open and loanTokenAddress for limit close and market stop
        uint256 leverage; //leverage amount
        uint256 loanTokenAmount; //loan token amount denominated in loanTokenAddress
        uint256 collateralTokenAmount; //collateral token amount denominated in base
        address trader; //trader placing order
        address iToken; //iToken being interacted with
        address loanTokenAddress; //loan token
        address base; //collateral token
        OrderType orderType; //order type
        OrderStatus status; //order status
        uint64 timeTillExpiration; //Time till expiration. Useful for GTD and time-based cancellation
        bytes loanDataBytes; //data passed for margin trades
    }

    /// Returns proxy owner
    /// @return owner Contract owner
    function owner() external view returns(address owner);

    /// Returns guardian
    /// @return guardian Protocol guardian address
    function getGuardian() external view returns(address guardian);

    /// Returns Deposits contract address
    /// @return vault Deposits Contract
    function VAULT() external view returns(address vault);

    /// Returns Protocol contract address
    /// @return protocol ooki protocol contract
    function PROTOCOL() external view returns(address protocol);

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
    function cancelOrderProtocol(bytes32 orderID) external returns (uint256);

    /// Force cancels order
    /// @param orderID ID of order to be canceled
    function cancelOrderGuardian(bytes32 orderID) external;

    /// Changes stop type between index and dex price
    /// @param stopType true = index, false = dex price
    function changeStopType(bool stopType) external;

    /// Set price feed contract address
    /// @param newFeed new price feed contract
    function setPriceFeed(address newFeed) external;

    /// Set gas price to be used for incentives (if price feed does not already contain it)
    /// @param gasPrice gas price in gwei
    function setGasPrice(uint256 gasPrice) external;

    /// Return price feed contract address
    /// @return priceFeed Price Feed Contract Address
    function priceFeed() external view returns (address priceFeed);

    /// Returns gas price used for incentive calculations
    /// @return gasPrice gas price in gwei
    function getGasPrice() external view returns (uint256 gasPrice);

    /// Deposit Gas Token to pay out incentives for orders to be executed
    /// @param amount when depositing wrapped token, this is amount to be deposited (leave as 0 if sending native token)
    function depositGasFeeToken(uint256 amount) external payable;

    /// Withdraw Gas Token (received as native token)
    /// @param amount amount to be withdrawn
    function withdrawGasFeeToken(uint256 amount) external;

    /// Return amount received through a specified swap
    /// @param srcToken source token address
    /// @param destToken destination token address
    /// @param payload loanDataBytes passed for margin trades
    /// @param amountIn amount in for the swap
    function getDexRate(address srcToken, address destToken, bytes calldata payload, uint256 amountIn) external returns(uint256);

    /// Checks if order is able to be cleared from books due to failing to meet all requirements
    /// @param orderID order ID
    function clearOrder(bytes32 orderID) external view returns (bool);

    /// Returns list of orders that are up to be cleared. Used for Chainlink Keepers
    /// @param start starting index
    /// @param end ending index
    /// @return hasOrders true if the payload contains any orders
    /// @return payload bytes32[] encoded with the order IDs up for clearing from books
    function getClearOrderList(uint start, uint end) external view returns (bool hasOrders, bytes memory payload);

    /// Returns an order ID available for execution. Used for Chainlink Keepers
    /// @param start starting index
    /// @param end ending index
    /// @return ID order ID up for execution. If equal to 0 there is no order ID up for execution in the specified index range
    function getExecuteOrder(uint start, uint end) external returns (bytes32 ID);

    /// Checks if order meets requirements for execution
    /// @param orderID order ID of order being checked
    function prelimCheck(bytes32 orderID) external returns (bool);

    /// Returns oracle rate for a swap
    /// @param srcToken source token address
    /// @param destToken destination token address
    /// @param amount swap amount
    function queryRateReturn(address srcToken, address destToken, uint256 amount) external view returns(uint256);

    /// Checks if dex rate is within acceptable bounds from oracle rate
    /// @param srcToken source token address
    /// @param destToken destination token address
    /// @param payload loanDataBytes used for margin trade
    function priceCheck(address srcToken, address destToken, bytes calldata payload) external returns(bool);

    /// Executes Order
    /// @param orderID order ID
    /// @return incentiveAmountReceived amount received in gas token from exeuction of order
    function executeOrder(bytes32 orderID) external returns(uint256 incentiveAmountReceived);

    /// sets token allowances
    /// @param spenders addresses that will be given allowance
    /// @param tokens token addresses
    function adjustAllowance(address[] calldata spenders, address[] calldata tokens) external;

    /// revokes token allowances
    /// @param spenders addresses that will have allowance revoked
    /// @param tokens token addresses
    function revokeAllowance(address[] calldata spenders, address[] calldata tokens) external;

    /// Retrieves active orders for a trader
    /// @param trader address of trader
    function getUserOrders(address trader) external view returns (Order[] memory);

    /// Retrieves active orders for a trader
    /// @param trader address of trader
    /// @param start starting index
    /// @param end ending index
    function getUserOrdersLimited(address trader, uint256 start, uint256 end) external view returns (Order[] memory);

    /// Retrieves order corresponding to an order ID
    /// @param orderID order ID
    function getOrderByOrderID(bytes32 orderID) external view returns (Order memory);

    /// Retrieves active order IDs for a trader
    /// @param trader address of trader
    function getUserOrderIDs(address trader) external view returns (bytes32[] memory);

    /// Returns total active orders count for a trader
    /// @param trader address of trader
    function getUserOrdersCount(address trader) external view returns (uint256);

    /// Returns total active orders count
    function getGlobalOrdersCount() external view returns (uint256);

    /// Returns total active order IDs
    function getGlobalOrderIDs() external view returns (bytes32[] memory);
    
    /// Returns total active orders
    function getGlobalOrders() external view returns (Order[] memory);

    /// Returns active order IDs
    /// @param start starting index
    /// @param end ending index
    function getGlobalOrderIDsLimited(uint256 start, uint256 end) external view returns (bytes32[] memory);

    /// Returns active orders
    /// @param start starting index
    /// @param end ending index
    function getGlobalOrdersLimited(uint256 start, uint256 end) external view returns (Order[] memory);
}
