pragma solidity ^0.8.0;

interface IOrderBook {
    function getOrders() external view returns (OpenOrder[] memory);

    function prelimCheck(bytes32 orderID) external view returns (bool);

    function executeOrder(address payable keeper, bytes32 orderID) external;

    function cancelOrderProtocol(bytes32 orderID) external;

    function clearOrder(bytes32 orderID) external view returns (bool);

    struct OpenOrder {
        address trader;
        bytes32 loanID;
        address iToken;
        address loanTokenAddress;
        uint256 price;
        uint256 leverage;
        uint256 loanTokenAmount;
        uint256 collateralTokenAmount;
        bool isActive;
        address base;
        uint256 orderType;
        bool isCollateral;
        bytes32 orderID;
        bytes loanData;
    }
}
