pragma solidity ^0.8.4;
import "../Enumerates/EnumLimits.sol";
import "../Enumerates/EnumTraders.sol";
import "../Enumerates/EnumOrders.sol";
import "../IWalletFactor.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
contract OrderBookEvents is Ownable{
	
    using OrderRecords for OrderRecords.orderSet;
    mapping(address=>bool) internal  hasSmartWallet;
    mapping(address=>address) internal smartWalletOwnership;
    mapping(address=>bool) internal isSmartWallet;
    mapping(address=>mapping(uint=>IWalletFactory.OpenOrder)) internal HistoricalOrders;
	mapping(uint=>IWalletFactory.OrderQueue) AllOrders;
    mapping(address=>OrderRecords.orderSet) internal HistOrders;
	mapping(address=>OrderEntry.orderSet) internal ActiveTrades;
    mapping(address=>uint) internal HistoricalOrderIDs;
	mapping(address=>mapping(uint=>uint)) internal matchingID;
	mapping(bytes32=>address) internal loanIDOwnership;
	OrderRecords.orderSet internal AllOrderIDs;
	ActiveTraders.orderSet internal activeTraders;
    event OrderCancelled(address indexed smartWallet,uint nonce);
    event OrderPlaced(address indexed smartWallet, IWalletFactory.OrderType indexed OrderType, uint indexed execPrice,uint orderID, address collateralTokenAddress, address loanTokenAddress);
    event OrderExecuted(address indexed smartWallet,uint nonce);
    event OrderAmended(address indexed smartWallet, IWalletFactory.OrderType indexed OrderType, uint indexed execPrice,uint orderID, address collateralTokenAddress, address loanTokenAddress);

}