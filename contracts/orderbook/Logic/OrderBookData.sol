pragma solidity ^0.8.0;
import "../Storage/OrderBookEvents.sol";
import "../Storage/OrderBookStorage.sol";

interface IERC {
    function approve(address spender, uint amount) external; //for USDT
}

contract OrderBookData is OrderBookEvents, OrderBookStorage {
    using EnumerableSet for EnumerableSet.Bytes32Set;

    function initialize(address target) public onlyOwner {
        _setTarget(this.adjustAllowance.selector, target);
        _setTarget(this.getActiveOrders.selector, target);
        _setTarget(this.getActiveOrdersLimited.selector, target);
        _setTarget(this.getOrderByOrderID.selector, target);
        _setTarget(this.getActiveOrderIDs.selector, target);
        _setTarget(this.getTotalOrders.selector, target);
        _setTarget(this.getActiveOrders.selector, target);
        _setTarget(this.getTotalActiveOrders.selector, target);
        _setTarget(this.getOrders.selector, target);
        _setTarget(this.getOrdersLimited.selector, target);
    }

    function adjustAllowance(address spender, address token) external pausable {
        require(
            protocol.isLoanPool(spender) ||
                address(protocol) == spender ||
                vault == spender,
            "OrderBook: invalid spender"
        );
        IERC(token).approve(spender, 0); //needs to be zeroed out because of different iterations of ERC-20 standard
        IERC(token).approve(spender, type(uint256).max);
    }

    function getActiveOrders(address trader)
        external
        view
        returns (IOrderBook.Order[] memory fullList)
    {
        bytes32[] memory idSet = _histOrders[trader].values();

        fullList = new IOrderBook.Order[](idSet.length);
        for (uint256 i = 0; i < idSet.length;) {
            fullList[i] = _allOrders[idSet[i]];
            unchecked { ++i; }
        }
        return fullList;
    }

    function getActiveOrdersLimited(address trader, uint start, uint end)
        external
        view
        returns (IOrderBook.Order[] memory fullList)
    {
        require(end<=_histOrders[trader].length(), "OrderBook: end is past max orders");
        fullList = new IOrderBook.Order[](end-start);
        for (uint256 i = start; i < end;) {
            fullList[i] = _allOrders[_histOrders[trader].at(i)];
            unchecked { ++i; }
        }
        return fullList;
    }

    function getOrderByOrderID(bytes32 orderID)
        public
        view
        returns (IOrderBook.Order memory)
    {
        return _allOrders[orderID];
    }

    function getActiveOrderIDs(address trader)
        external
        view
        returns (bytes32[] memory)
    {
        return _histOrders[trader].values();
    }

    function getTotalOrders(address trader) external view returns (uint256) {
        return _histOrders[trader].length();
    }

    function getTotalActiveOrders() external view returns (uint256) {
        return _allOrderIDs.length();
    }

    function getOrders()
        external
        view
        returns (IOrderBook.Order[] memory fullList)
    {
        bytes32[] memory idSet = _allOrderIDs.values();

        fullList = new IOrderBook.Order[](idSet.length);
        for (uint256 i = 0; i < idSet.length;) {
            fullList[i] = getOrderByOrderID(idSet[i]);
            unchecked { ++i; }
        }
        return fullList;
    }

    function getOrdersLimited(uint start, uint end)
        external
        view
        returns (IOrderBook.Order[] memory fullList)
    {
        require(end<=_allOrderIDs.length(), "OrderBook: end is past max orders");
        fullList = new IOrderBook.Order[](end-start);
        for (uint256 i = start; i < end;) {
            fullList[i] = _allOrders[_allOrderIDs.at(i)];
            unchecked { ++i; }
        }
        return fullList;
    }
}
