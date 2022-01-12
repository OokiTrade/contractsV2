pragma solidity ^0.8.0;
import "../Storage/OrderBookEvents.sol";
import "../Storage/OrderBookStorage.sol";
import "../OrderVault/IDeposits.sol";

contract OrderBookOrderPlacement is OrderBookEvents, OrderBookStorage {
	using EnumerableSet for EnumerableSet.Bytes32Set;

	function initialize(
		address target)
		public
		onlyOwner  
	{
		_setTarget(this.placeOrder.selector, target);
		_setTarget(this.currentSwapRate.selector, target);
		_setTarget(this.amendOrder.selector, target);
		_setTarget(this.cancelOrder.selector, target);
		_setTarget(this.cancelOrderProtocol.selector, target);
		_setTarget(this.changeStopType.selector, target);
		_setTarget(this.minimumAmount.selector, target);
	}

    function currentSwapRate(address start, address end)
        public
        view
        returns (uint256 executionPrice)
    {
        (executionPrice, ) = IPriceFeeds(IBZx(protocol).priceFeeds())
            .queryRate(end, start);
    }

    function _collateralTokenMatch(IOrderBook.OpenOrder memory checkOrder)
        internal
        view
        returns (bool)
    {
        return
            IBZx(protocol).getLoan(checkOrder.loanID).collateralToken ==
            checkOrder.base;
    }

    function _loanTokenMatch(IOrderBook.OpenOrder memory checkOrder)
        internal
        view
        returns (bool)
    {
        return
            IBZx(protocol).getLoan(checkOrder.loanID).loanToken ==
            checkOrder.loanTokenAddress;
    }

    function _abs(int256 x) private pure returns (int256) {
        return x >= 0 ? x : -x;
    }

    function placeOrder(IOrderBook.OpenOrder memory Order) public {
        require(
            _abs(
                int256(Order.loanTokenAmount) -
                    int256(Order.collateralTokenAmount)
            ) == int256(Order.loanTokenAmount + Order.collateralTokenAmount),
            "only one token can be used"
        );
        require(
            IBZx(protocol).supportedTokens(Order.loanTokenAddress) &&
                IBZx(protocol).supportedTokens(Order.base),
            "invalid pair"
        );
        require(
            Order.loanID != 0
                ? _collateralTokenMatch(Order) && _loanTokenMatch(Order)
                : true,
            "incorrect collateral and/or loan token specified"
        );
        require(
            Order.orderType == IOrderBook.OrderType.LIMIT_OPEN
                ? IBZx(protocol).isLoanPool(Order.iToken)
                : true
        );
        require(
            Order.orderType == IOrderBook.OrderType.LIMIT_OPEN
                ? Order.loanID == 0 ||
                    _activeTrades[msg.sender].contains(Order.loanID)
                : _activeTrades[msg.sender].contains(Order.loanID),
            "inactive loan"
        );
        uint256 amountUsed = Order.loanTokenAmount +
            Order.collateralTokenAmount; //one is always 0 so correct amount and no overflow issues
        address usedToken = Order.loanTokenAmount > Order.collateralTokenAmount
            ? Order.loanTokenAddress
            : Order.base;
        require(
            (currentSwapRate(usedToken, USDC) * amountUsed) /
                10**(IERC20Metadata(usedToken).decimals()) >
                MIN_AMOUNT_IN_USDC
        );
        require(Order.trader == msg.sender);
        require(!Order.isCancelled);
        mainOBID++;
        Order.orderID = keccak256(abi.encode(msg.sender, mainOBID));
        _orderExpiration[Order.orderID] = block.timestamp + DAYS_14;
        _allOrders[Order.orderID] = Order;
        _histOrders[msg.sender].add(Order.orderID);
        _allOrderIDs.add(Order.orderID);
        if (Order.orderType == IOrderBook.OrderType.LIMIT_OPEN) {
            IDeposits(vault).deposit(
                Order.orderID,
                amountUsed,
                msg.sender,
                usedToken
            );
        }
        emit OrderPlaced(
            msg.sender,
            Order.orderType,
            Order.price,
            Order.orderID,
            Order.base,
            Order.loanTokenAddress
        );
    }

    function amendOrder(IOrderBook.OpenOrder memory Order) public {
        require(
            _abs(
                int256(Order.loanTokenAmount) -
                    int256(Order.collateralTokenAmount)
            ) == int256(Order.loanTokenAmount + Order.collateralTokenAmount),
            "only one token can be used"
        );
        //uint256 swapRate = currentSwapRate(Order.loanTokenAddress, Order.base);
        require(
            Order.base == _allOrders[Order.orderID].base &&
                Order.loanTokenAddress ==
                _allOrders[Order.orderID].loanTokenAddress,
            "invalid tokens"
        );
        /*require(
            Order.price > swapRate
                ? (Order.price - swapRate) < (Order.price * 25) / 100
                : (swapRate - Order.price) < (swapRate * 25) / 100,
            "price too far away"
        );*/
        require(
            Order.orderType == IOrderBook.OrderType.LIMIT_OPEN
                ? IBZx(protocol).isLoanPool(Order.iToken)
                : true
        );
        require(
            Order.orderID == _allOrders[Order.orderID].orderID,
            "improper ID"
        );
        require(
            !_allOrders[Order.orderID].isCancelled,
            "inactive order specified"
        );
        require(
            Order.orderType == IOrderBook.OrderType.LIMIT_OPEN
                ? Order.loanID == 0 ||
                    _activeTrades[msg.sender].contains(Order.loanID)
                : _activeTrades[msg.sender].contains(Order.loanID),
            "inactive loan"
        );
        require(Order.trader == msg.sender);
        require(!_allOrders[Order.orderID].isCancelled);
        _orderExpiration[Order.orderID] = block.timestamp + DAYS_14;
        if (Order.orderType == IOrderBook.OrderType.LIMIT_OPEN) {
            uint256 amountUsed = Order.loanTokenAmount +
                Order.collateralTokenAmount; //one is always 0 so correct amount and no overflow issues
            address usedToken = Order.loanTokenAmount >
                Order.collateralTokenAmount
                ? Order.loanTokenAddress
                : Order.base;
            uint256 storedAmount = IDeposits(vault).getDeposit(
                msg.sender,
                Order.orderID
            );
            require(
                usedToken ==
                    IDeposits(vault).getTokenUsed(msg.sender, Order.orderID)
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
            Order.price,
            Order.orderID,
            Order.base,
            Order.loanTokenAddress
        );
    }

    function cancelOrder(bytes32 orderID) public {
        require(!_allOrders[orderID].isCancelled, "inactive order");
        _allOrders[orderID].isCancelled = true;
        _histOrders[msg.sender].remove(orderID);
        _allOrderIDs.remove(orderID);
        if (
            _allOrders[orderID].orderType == IOrderBook.OrderType.LIMIT_OPEN
        ) {
            address usedToken = IDeposits(vault).getTokenUsed(
                msg.sender,
                orderID
            );
            IDeposits(vault).withdrawToTrader(msg.sender, orderID);
        }
        emit OrderCancelled(msg.sender, orderID);
    }

    function cancelOrderProtocol(bytes32 orderID) public {
        address trader = _allOrders[orderID].trader;
        require(!_allOrders[orderID].isCancelled, "inactive order");
        uint256 swapRate = currentSwapRate(
            _allOrders[orderID].loanTokenAddress,
            _allOrders[orderID].base
        );
        require(
            (
                _allOrders[orderID].price > swapRate
                    ? (_allOrders[orderID].price - swapRate) >
                        (_allOrders[orderID].price * 25) / 100
                    : (swapRate - _allOrders[orderID].price) >
                        (swapRate * 25) / 100
            ) || _orderExpiration[orderID] < block.timestamp,
            "no conditions met"
        );
        _allOrders[orderID].isCancelled = true;
        _histOrders[trader].remove(orderID);
        _allOrderIDs.remove(orderID);
        if (
            _allOrders[orderID].orderType == IOrderBook.OrderType.LIMIT_OPEN
        ) {
            address usedToken = IDeposits(vault).getTokenUsed(trader, orderID);
            IDeposits(vault).withdrawToTrader(trader, orderID);
        }
        emit OrderCancelled(trader, orderID);
    }

    function changeStopType(bool stop) public {
        _useOracle[msg.sender] = stop;
    }

    function minimumAmount() public view returns (uint256) {
        return MIN_AMOUNT_IN_USDC;
    }
}
