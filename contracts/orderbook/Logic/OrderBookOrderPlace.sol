pragma solidity ^0.8.0;
import "../Storage/OrderBookEvents.sol";
import "../Storage/OrderBookStorage.sol";
import "../OrderVault/IDeposits.sol";

contract OrderBookOrderPlace is OrderBookEvents, OrderBookStorage {
    using EnumerableSet for EnumerableSet.Bytes32Set;

    function initialize(address target) public onlyOwner {
        _setTarget(this.placeOrder.selector, target);
        _setTarget(this.amendOrder.selector, target);
        _setTarget(this.cancelOrder.selector, target);
        _setTarget(this.cancelOrderProtocol.selector, target);
        _setTarget(this.changeStopType.selector, target);
        _setTarget(this.recoverFundsFromFailedOrder.selector, target);
    }

    function queryRateReturn(
        address start,
        address end,
        uint256 amount
    ) public view returns (uint256) {
        (uint256 executionPrice, uint256 precision) = IPriceFeeds(
            protocol.priceFeeds()
        ).queryRate(start, end);
        return (executionPrice * amount) / precision;
    }

    function _caseChecks(bytes32 ID, address collateral, address loanToken)
        internal
        view
        returns (bool)
    {
        return 
            protocol.getLoan(ID).loanToken ==
            loanToken &&
            protocol.getLoan(ID).collateralToken ==
            collateral &&
            protocol.delegatedManagers(ID, address(this));
    }

    function _isActiveLoan(bytes32 ID) internal view returns (bool) {
        return protocol.loans(ID).active;
    }

    function _abs(int256 x) private pure returns (int256) {
        return x >= 0 ? x : -x;
    }

    function placeOrder(IOrderBook.Order calldata Order) external pausable {
        require(Order.loanDataBytes.length < 3500, "OrderBook: loanDataBytes too complex");
        require(
            _abs(
                int256(Order.loanTokenAmount) -
                    int256(Order.collateralTokenAmount)
            ) == int256(Order.loanTokenAmount + Order.collateralTokenAmount),
            "OrderBook: only one token can be used"
        );
        require(
            protocol.supportedTokens(Order.loanTokenAddress) &&
                protocol.supportedTokens(Order.base),
            "OrderBook: invalid pair"
        );
        require(
            Order.loanID != 0
                ? _caseChecks(Order.loanID, Order.base, Order.loanTokenAddress)
                : true,
            "OrderBook: cases not passed"
        );
        require(
            Order.orderType == IOrderBook.OrderType.LIMIT_OPEN
                ? protocol.isLoanPool(Order.iToken)
                : true,
            "OrderBook: invalid iToken specified"
        );
        require(
            Order.orderType == IOrderBook.OrderType.LIMIT_OPEN
                ? Order.loanID == 0 ||
                    _isActiveLoan(Order.loanID)
                : _isActiveLoan(Order.loanID),
            "OrderBook: inactive loan"
        );
        (uint256 amountUsed, address usedToken) = Order.loanTokenAmount > Order.collateralTokenAmount
            ? (Order.loanTokenAmount, Order.loanTokenAddress)
            : (Order.collateralTokenAmount, Order.base);
        require(
            queryRateReturn(usedToken, USDC, amountUsed) >=
                MIN_AMOUNT_IN_USDC,
            "OrderBook: Order too small"
        );
        require(Order.trader == msg.sender, "OrderBook: invalid trader");
        require(!Order.isCancelled, "OrderBook: invalid order state");
        mainOBID++;
        bytes32 ID = keccak256(abi.encode(msg.sender, mainOBID));
        require(IDeposits(vault).getTokenUsed(ID) == address(0), "Orderbook: collision"); //in the very unlikely chance of collision on ID error is thrown
        _allOrders[ID] = Order;
        _allOrders[ID].orderID = ID;
        _histOrders[msg.sender].add(ID);
        _allOrderIDs.add(ID);
        if (Order.orderType == IOrderBook.OrderType.LIMIT_OPEN) {
            IDeposits(vault).deposit(ID, amountUsed, msg.sender, usedToken);
        }
        emit OrderPlaced(
            msg.sender,
            Order.orderType,
            Order.amountReceived,
            ID,
            Order.base,
            Order.loanTokenAddress
        );
    }

    function amendOrder(IOrderBook.Order calldata Order) external pausable {
        require(Order.loanDataBytes.length < 3500, "OrderBook: loanDataBytes too complex");
        require(
            _abs(
                int256(Order.loanTokenAmount) -
                    int256(Order.collateralTokenAmount)
            ) == int256(Order.loanTokenAmount + Order.collateralTokenAmount),
            "OrderBook: only one token can be used"
        );
        require(
            Order.base == _allOrders[Order.orderID].base &&
                Order.loanTokenAddress ==
                _allOrders[Order.orderID].loanTokenAddress,
            "OrderBook: invalid tokens"
        );
        /*require(
            Order.price > swapRate
                ? (Order.price - swapRate) < (Order.price * 25) / 100
                : (swapRate - Order.price) < (swapRate * 25) / 100,
            "price too far away"
        );*/
        require(
            Order.orderType == IOrderBook.OrderType.LIMIT_OPEN
                ? protocol.isLoanPool(Order.iToken)
                : true,
            "OrderBook: invalid iToken specified"
        );
        require(
            !_allOrders[Order.orderID].isCancelled,
            "OrderBook: inactive order specified"
        );
        require(
            Order.orderType == IOrderBook.OrderType.LIMIT_OPEN
                ? Order.loanID == 0 ||
                    _isActiveLoan(Order.loanID)
                : _isActiveLoan(Order.loanID),
            "OrderBook: inactive loan"
        );
        require(Order.trader == msg.sender, "OrderBook: invalid trader");
        if (Order.orderType == IOrderBook.OrderType.LIMIT_OPEN) {
            (uint256 amountUsed, address usedToken) = Order.loanTokenAmount > Order.collateralTokenAmount
                ? (Order.loanTokenAmount, Order.loanTokenAddress)
                : (Order.collateralTokenAmount, Order.base);
            uint256 storedAmount = IDeposits(vault).getDeposit(
                Order.orderID
            );
            require(
                usedToken ==
                    IDeposits(vault).getTokenUsed(Order.orderID),
                "OrderBook: invalid used token"
            );
            uint256 amountUsedOld = _allOrders[Order.orderID].loanTokenAmount +
                _allOrders[Order.orderID].collateralTokenAmount;
            if (amountUsedOld > amountUsed) {
                IDeposits(vault).partialWithdraw(
                    msg.sender,
                    Order.orderID,
                    amountUsedOld - amountUsed
                );
            } else {
                IDeposits(vault).deposit(
                    Order.orderID,
                    amountUsed - amountUsedOld,
                    msg.sender,
                    usedToken
                );
            }
        }
        _allOrders[Order.orderID] = Order;
        emit OrderAmended(
            msg.sender,
            Order.orderType,
            Order.amountReceived,
            Order.orderID,
            Order.base,
            Order.loanTokenAddress
        );
    }

    function cancelOrder(bytes32 orderID) external pausable {
        require(!_allOrders[orderID].isCancelled, "OrderBook: inactive order");
        _allOrders[orderID].isCancelled = true;
        require(_histOrders[msg.sender].remove(orderID), "OrderBook: not owner of order");
        _allOrderIDs.remove(orderID);
        if (_allOrders[orderID].orderType == IOrderBook.OrderType.LIMIT_OPEN) {
            address usedToken = IDeposits(vault).getTokenUsed(
                orderID
            );
            IDeposits(vault).withdrawToTrader(msg.sender, orderID);
        }
        emit OrderCancelled(msg.sender, orderID);
    }

    function recoverFundsFromFailedOrder(bytes32 orderID) external pausable {
        IOrderBook.Order memory order = _allOrders[orderID];
        require(msg.sender == order.trader, "OrderBook: Not trade owner");
        require(order.isCancelled, "OrderBook: Order not executed");
        require(!_allOrderIDs.contains(orderID), "OrderBook: Order still in records");
        IDeposits(vault).withdrawToTrader(msg.sender, orderID);
    }

    function cancelOrderProtocol(bytes32 orderID) external pausable {
        IOrderBook.Order memory order = _allOrders[orderID];
        address trader = order.trader;
        require(!order.isCancelled, "OrderBook: inactive order");
        uint256 amountUsed = order.collateralTokenAmount +
            order.loanTokenAmount;
        uint256 swapRate;
        if (order.orderType == IOrderBook.OrderType.LIMIT_OPEN) {
            swapRate = queryRateReturn(
                order.loanTokenAddress,
                order.base,
                amountUsed
            );
        } else {
            swapRate = queryRateReturn(
                order.base,
                order.loanTokenAddress,
                amountUsed
            );
        }
        require(
            (
                order.amountReceived > swapRate
                    ? (order.amountReceived - swapRate) >
                        (order.amountReceived * 25) / 100
                    : (swapRate - order.amountReceived) >
                        (swapRate * 25) / 100
            ) || order.timeTillExpiration < block.timestamp,
            "OrderBook: no conditions met"
        );

        order.isCancelled = true;
        _histOrders[trader].remove(orderID);
        _allOrderIDs.remove(orderID);
        if (order.orderType == IOrderBook.OrderType.LIMIT_OPEN) {
            address usedToken = IDeposits(vault).getTokenUsed(orderID);
            IDeposits(vault).withdrawToTrader(trader, orderID);
        }
        emit OrderCancelled(trader, orderID);
    }

    function changeStopType(bool stop) external pausable {
        _useOracle[msg.sender] = stop;
    }
}
