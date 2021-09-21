pragma solidity ^0.8.4;
import "./EnumLimits.sol";
import "./EnumTraders.sol";
import "./EnumOrders.sol";
import "./IWalletFactor.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./WrappedToken.sol";
contract OrderBookEvents is Ownable{
    using sortOrderInfo for sortOrderInfo.orderSet;
    mapping(address=>bool) internal  hasSmartWallet;
    mapping(address=>address) internal smartWalletOwnership;
    mapping(address=>bool) internal isSmartWallet;
    mapping(address=>mapping(uint=>IWalletFactory.OpenOrder)) internal HistoricalOrders;
	mapping(uint=>IWalletFactory.OrderQueue) AllOrders;
    mapping(address=>sortOrderInfo.orderSet) internal HistOrders;
	mapping(address=>getTrades.orderSet) internal ActiveTrades;
    mapping(address=>uint) internal HistoricalOrderIDs;
	mapping(address=>mapping(uint=>uint)) internal matchingID;
	mapping(bytes32=>address) internal loanIDOwnership;
	sortOrderInfo.orderSet internal AllOrderIDs;
	getActiveTraders.orderSet internal activeTraders;
    event OrderCancelled(address indexed smartWallet,uint nonce);
    event OrderPlaced(address indexed smartWallet, IWalletFactory.OrderType indexed OrderType, uint indexed execPrice,uint orderID, address collateralTokenAddress, address loanTokenAddress);
    event OrderExecuted(address indexed smartWallet,uint nonce);
    event OrderAmended(address indexed smartWallet, IWalletFactory.OrderType indexed OrderType, uint indexed execPrice,uint orderID, address collateralTokenAddress, address loanTokenAddress);

}