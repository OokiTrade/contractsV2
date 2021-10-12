pragma solidity ^0.8.4;
import "../Enumerates/EnumLimits.sol";
import "../Enumerates/EnumTraders.sol";
import "../Enumerates/EnumOrders.sol";
import "../IWalletFactor.sol";
import "@openzeppelin-4.3.2/access/Ownable.sol";

contract OrderBookEvents is Ownable {
    using OrderRecords for OrderRecords.orderSet;
    mapping(address => bool) internal hasSmartWallet;
    mapping(address => address) internal smartWalletOwnership;
    mapping(address => bool) internal isSmartWallet;
    mapping(address => mapping(uint256 => IWalletFactory.OpenOrder))
        internal HistoricalOrders;
    mapping(uint256 => IWalletFactory.OrderQueue) AllOrders;
    mapping(address => mapping(uint256 => uint256)) internal orderExpiration;
    mapping(address => OrderRecords.orderSet) internal HistOrders;
    mapping(address => OrderEntry.orderSet) internal ActiveTrades;
    mapping(address => uint256) internal HistoricalOrderIDs;
    mapping(address => mapping(uint256 => uint256)) internal matchingID;
    mapping(bytes32 => address) internal loanIDOwnership;
    mapping(address => mapping(address => uint256)) internal allocatedBalances;
    OrderRecords.orderSet internal AllOrderIDs;
    ActiveTraders.orderSet internal activeTraders;
    event OrderCancelled(address indexed smartWallet, uint256 nonce);
    event OrderPlaced(
        address indexed smartWallet,
        IWalletFactory.OrderType indexed OrderType,
        uint256 indexed execPrice,
        uint256 orderID,
        address collateralTokenAddress,
        address loanTokenAddress
    );
    event OrderExecuted(address indexed smartWallet, uint256 nonce);
    event OrderAmended(
        address indexed smartWallet,
        IWalletFactory.OrderType indexed OrderType,
        uint256 indexed execPrice,
        uint256 orderID,
        address collateralTokenAddress,
        address loanTokenAddress
    );
}
