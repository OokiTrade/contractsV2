pragma solidity ^0.8.0;

interface IOrderBook {
    enum OrderType {
        LIMIT_OPEN,
        LIMIT_CLOSE,
        MARKET_STOP
    }
    struct Order {
        address trader;
        bytes32 loanID;
        address iToken;
        address loanTokenAddress;
        uint256 amountReceived;
        uint256 leverage;
        uint256 loanTokenAmount;
        uint256 collateralTokenAmount;
        bool isCancelled;
        address base;
        OrderType orderType;
        bool isCollateral;
        bytes32 orderID;
        bytes loanDataBytes;
    }

    function getRouter() external view returns (address);

    function placeOrder(Order calldata order) external;

    function amendOrder(Order calldata order, uint256 orderID) external;

    function cancelOrder(uint256 orderID) external;

    function getSwapAddress() external view returns (address);

    function getFeed() external view returns (address);
}
