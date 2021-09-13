pragma solidity ^0.8.4;
interface StructInterface{
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
interface FactoryCont{
	function getOrders(uint start, uint count) external view returns(StructInterface.OpenOrder[] memory);
	function prelimCheck(address trader, uint orderID) external view returns(bool);
	function executeOrder(address payable keeper, address trader, uint orderID) external;
	function getTotalActiveOrders() external view returns(uint);
}
contract KeeperManagement{
	address factory;
	constructor(address factoryAddress){
		factory = factoryAddress;
	}

	function checkUpkeep(bytes calldata checkData) public view returns(bool upkeepNeeded, bytes memory performData){
		StructInterface.OpenOrder[] memory listOfMainOrders = FactoryCont(factory).getOrders(0,FactoryCont(factory).getTotalActiveOrders());
		for(uint x =0; x < listOfMainOrders.length; x++){
			if(FactoryCont(factory).prelimCheck(listOfMainOrders[x].trader,listOfMainOrders[x].orderID) == true){
				upkeepNeeded = true;
				performData = abi.encode(listOfMainOrders[x].trader,listOfMainOrders[x].orderID);
				return (upkeepNeeded,performData);
			}
		}
		return (upkeepNeeded,performData);
	}
	function performUpkeep(bytes calldata performData) public {
		(address trader, uint orderId) = abi.decode(performData,(address,uint));
		//emit OrderExecuted(trader,orderId);
		FactoryCont(factory).executeOrder(payable(address(this)), trader, orderId);
	
	}
}