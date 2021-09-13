pragma solidity ^0.8.4;
import "./OrderBookEvents.sol";
import "./OrderBookStorage.sol";
contract OrderBookData is OrderBookEvents,OrderBookStorage{
    function getActiveOrders(address smartWallet, uint start, uint count) public view returns(IWalletFactory.OpenOrder[] memory fullList){
        uint[] memory idSet = sortOrderInfo.enums(HistOrders[smartWallet],start,count);
        
        fullList = new IWalletFactory.OpenOrder[](idSet.length);
        for(uint i = 0;i<idSet.length;i++){
            fullList[i] = HistoricalOrders[smartWallet][idSet[i]];
        }
        return fullList;
    }
    function getOrderByOrderID(address smartWallet, uint orderID) public view returns(IWalletFactory.OpenOrder memory){
        return HistoricalOrders[smartWallet][orderID];
    }
    function getActiveOrderIDs(address smartWallet, uint start, uint count) public view returns(uint[] memory){
        return sortOrderInfo.enums(HistOrders[smartWallet],start,count);
    }
    function getTotalOrders(address smartWallet) public view returns(uint){
        return sortOrderInfo.length(HistOrders[smartWallet]);
    }
	function getTradersWithOrders(uint start, uint count) public view returns(address[] memory){
		return getActiveTraders.enums(activeTraders,start,count);
	}
	function getTotalTradersWithOrders() public view returns(uint){
		return getActiveTraders.length(activeTraders);
	}
	function getTotalActiveOrders() public view returns(uint){
		return sortOrderInfo.length(AllOrderIDs);
	}
	function getOrders(uint start,uint count) public view returns(IWalletFactory.OpenOrder[] memory fullList){
        uint[] memory idSet = sortOrderInfo.enums(AllOrderIDs,start,count);
        
        fullList = new IWalletFactory.OpenOrder[](idSet.length);
        for(uint i = 0;i<idSet.length;i++){
            fullList[i] = getOrderByOrderID(AllOrders[idSet[i]].trader,AllOrders[idSet[i]].orderID);
        }
        return fullList;
	}
	function getActiveTrades(address trader) public view returns(bytes32[] memory){
		return getTrades.enums(ActiveTrades[trader],0,getTrades.length(ActiveTrades[trader]));
	}

}