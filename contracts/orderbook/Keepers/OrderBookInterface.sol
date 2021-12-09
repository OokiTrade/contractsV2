pragma solidity ^0.8.4;

interface IOrderBook {
    function getOrders(uint256 start, uint256 count)
        external
        view
        returns (OpenOrder[] memory);

    function prelimCheck(address trader, uint256 orderID)
        external
        view
        returns (bool);

    function executeOrder(
        address payable keeper,
        address trader,
        uint256 orderID
    ) external;
	function cancelOrderProtocol(address trader, uint256 orderID) external;
	function clearOrder(address trader, uint256 orderID)
		external
		view
		returns (bool);
    function getTotalActiveOrders() external view returns (uint256);

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
        uint256 orderID;
        bytes loanData;
    }
    struct OrderQueue {
        address trader;
        uint256 orderID;
    }
}
