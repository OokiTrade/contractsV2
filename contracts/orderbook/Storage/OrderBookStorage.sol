pragma solidity ^0.8.0;

import "../IOrderBook.sol";
import "../../governance/PausableGuardian_0_8.sol";
import "@openzeppelin-4.3.2/utils/structs/EnumerableSet.sol";
import "../../../interfaces/IPriceFeeds.sol";
import "../../../interfaces/IToken.sol";
import "@openzeppelin-4.3.2/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin-4.3.2/token/ERC20/extensions/IERC20Metadata.sol";
import "./OrderBookConstants.sol";

contract OrderBookStorage is OrderBookConstants, PausableGuardian_0_8 {

    using EnumerableSet for EnumerableSet.Bytes32Set;
    mapping(bytes32 => IOrderBook.Order) internal _allOrders;
    mapping(bytes32 => uint256) internal _orderExpiration;
    mapping(address => EnumerableSet.Bytes32Set) internal _histOrders;
    mapping(address => bool) internal _useOracle;
    EnumerableSet.Bytes32Set internal _allOrderIDs;

    mapping(bytes4 => address) public logicTargets;

    uint256 public mainOBID;

    address public priceFeed = address(0);

    uint256 public chainGasPrice;

    function _setTarget(bytes4 sig, address target) internal {
        logicTargets[sig] = target;
    }
}
