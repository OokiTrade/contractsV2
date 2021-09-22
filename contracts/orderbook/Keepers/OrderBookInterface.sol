pragma solidity ^0.8.4;

interface IOrderBook{
	function getOrders(uint start, uint count) external view returns(OpenOrder[] memory);
	function prelimCheck(address trader, uint orderID) external view returns(bool);
	function executeOrder(address payable keeper, address trader, uint orderID) external;
	function getTotalActiveOrders() external view returns(uint);
    struct OpenOrder{
        address trader;
        bytes32 loanID;
        address iToken;
		address loanTokenAddress;
        uint price;
        uint leverage;
        uint loanTokenAmount;
        uint collateralTokenAmount;
        bool isActive;
        address base;
        uint orderType;
        bool isCollateral;
        uint orderID;
        bytes loanData;
    }
	struct OrderQueue{
		address trader;
		uint orderID;
	}
}