pragma solidity ^0.8.0;
import "../Storage/OrderBookEvents.sol";
import "../Storage/OrderBookStorage.sol";

contract OrderBookData is OrderBookEvents, OrderBookStorage {
    using EnumerableSet for EnumerableSet.Bytes32Set;

	function initialize(
		address target)
		public
		onlyOwner
	{
		_setTarget(this.getProtocolAddress.selector, target);
		_setTarget(this.adjustAllowance.selector, target);
		_setTarget(this.getActiveOrders.selector, target);
		_setTarget(this.getOrderByOrderID.selector, target);
		_setTarget(this.getActiveOrderIDs.selector, target);
		_setTarget(this.getTotalOrders.selector, target);
		_setTarget(this.getTotalActiveOrders.selector, target);
		_setTarget(this.getOrders.selector, target);
		_setTarget(this.getActiveTrades.selector, target);
	}
	
	function getProtocolAddress() public view returns (address) {
        return protocol;
    }

    function adjustAllowance(address spender, address token) public {
        require(
            IBZx(protocol).isLoanPool(spender) ||
                protocol == spender ||
                vault == spender,
            "invalid spender"
        );
        IERC20Metadata(token).approve(spender, type(uint256).max);
    }

    function getActiveOrders(
        address trader
    ) public view returns (IOrderBook.OpenOrder[] memory fullList) {
        bytes32[] memory idSet = _histOrders[trader].values();

        fullList = new IOrderBook.OpenOrder[](idSet.length);
        for (uint256 i = 0; i < idSet.length; i++) {
            fullList[i] = _allOrders[idSet[i]];
        }
        return fullList;
    }

    function getOrderByOrderID(bytes32 orderID)
        public
        view
        returns (IOrderBook.OpenOrder memory)
    {
        return _allOrders[orderID];
    }

    function getActiveOrderIDs(
        address trader
    ) public view returns (bytes32[] memory) {
        return _histOrders[trader].values();
    }

    function getTotalOrders(address trader) public view returns (uint256) {
        return _histOrders[trader].length();
    }

    function getTotalActiveOrders() public view returns (uint256) {
        return _allOrderIDs.length();
    }

    function getOrders()
        public
        view
        returns (IOrderBook.OpenOrder[] memory fullList)
    {
        bytes32[] memory idSet = _allOrderIDs.values();

        fullList = new IOrderBook.OpenOrder[](idSet.length);
        for (uint256 i = 0; i < idSet.length; i++) {
            fullList[i] = getOrderByOrderID(idSet[i]);
        }
        return fullList;
    }

    function getActiveTrades(address trader)
        public
        view
        returns (bytes32[] memory)
    {
        return
            _activeTrades[trader].values();
    }
}
