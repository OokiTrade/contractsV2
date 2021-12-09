pragma solidity ^0.8.4;
import "../Storage/OrderBookEvents.sol";
import "../Storage/OrderBookStorage.sol";
import "../OrderVault/IDeposits.sol";
contract OrderBookOrderPlacement is OrderBookEvents, OrderBookStorage {
	
    function currentSwapRate(address start, address end)
        public
        view
        returns (uint256 executionPrice)
    {
        (executionPrice, ) = IPriceFeeds(StateI(bZxRouterAddress).priceFeeds())
            .queryRate(end, start);
    }

    function collateralTokenMatch(IWalletFactory.OpenOrder memory checkOrder)
        internal
        view
        returns (bool)
    {
        return
            IBZX(bZxRouterAddress).getLoan(checkOrder.loanID).collateralToken ==
            checkOrder.base;
    }

    function loanTokenMatch(IWalletFactory.OpenOrder memory checkOrder)
        internal
        view
        returns (bool)
    {
        return
            IBZX(bZxRouterAddress).getLoan(checkOrder.loanID).loanToken ==
            checkOrder.loanTokenAddress;
    }

    function placeOrder(IWalletFactory.OpenOrder memory Order) public {
        require(
            (Order.loanTokenAmount == 0 && Order.collateralTokenAmount > 0) ||
                (Order.loanTokenAmount > 0 && Order.collateralTokenAmount == 0),
            "only one token can be used"
        );
        //uint256 swapRate = currentSwapRate(Order.loanTokenAddress, Order.base);
        require(IBZX(bZxRouterAddress).supportedTokens(Order.loanTokenAddress) && IBZX(bZxRouterAddress).supportedTokens(Order.base), "invalid pair");
        /*require(
            Order.price > swapRate
                ? (Order.price - swapRate) < (Order.price * 4) / 100
                : (swapRate - Order.price) < (swapRate * 4) / 100,
            "price too far away"
        );*/
        require(
            Order.loanID != 0
                ? collateralTokenMatch(Order) && loanTokenMatch(Order)
                : true,
            "incorrect collateral and/or loan token specified"
        );
        require(
            Order.orderType == IWalletFactory.OrderType.LIMIT_OPEN
                ? Order.loanID == 0 || OrderEntry.inVals(ActiveTrades[msg.sender], Order.loanID)
                : OrderEntry.inVals(ActiveTrades[msg.sender], Order.loanID),
            "inactive loan"
        );
		uint256 amountUsed = Order.loanTokenAmount +
			Order.collateralTokenAmount; //one is always 0 so correct amount and no overflow issues
		address usedToken = Order.loanTokenAmount >
			Order.collateralTokenAmount
			? Order.loanTokenAddress
			: Order.base;
		require(currentSwapRate(usedToken,USDC)*amountUsed/10**(IERC20Metadata(usedToken).decimals()) > MIN_AMOUNT_IN_USDC);
        HistoricalOrderIDs[msg.sender]++;
        mainOBID++;
        Order.orderID = HistoricalOrderIDs[msg.sender];
        Order.trader = msg.sender;
        Order.isActive = true;
        Order.loanData = "";
        orderExpiration[msg.sender][Order.orderID] = block.timestamp + DAYS_14;
        HistoricalOrders[msg.sender][HistoricalOrderIDs[msg.sender]] = Order;
        AllOrders[mainOBID].trader = msg.sender;
        AllOrders[mainOBID].orderID = Order.orderID;
        OrderRecords.addOrderNum(
            HistOrders[msg.sender],
            HistoricalOrderIDs[msg.sender]
        );
        OrderRecords.addOrderNum(AllOrderIDs, mainOBID);
        matchingID[msg.sender][HistoricalOrderIDs[msg.sender]] = mainOBID;
        if (ActiveTraders.inVals(activeTraders, msg.sender) == false) {
            ActiveTraders.addTrader(activeTraders, msg.sender);
        }
        if (Order.orderType == IWalletFactory.OrderType.LIMIT_OPEN) {


            SafeERC20.safeTransferFrom(
                IERC20(usedToken),
                msg.sender,
                address(this),
                amountUsed
            );
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
            HistoricalOrderIDs[msg.sender],
            Order.base,
            Order.loanTokenAddress
        );
    }

    function amendOrder(IWalletFactory.OpenOrder memory Order, uint256 orderID)
        public
    {
        require(
            (Order.loanTokenAmount == 0 && Order.collateralTokenAmount > 0) ||
                (Order.loanTokenAmount > 0 && Order.collateralTokenAmount == 0),
            "only one token can be used"
        );
        //uint256 swapRate = currentSwapRate(Order.loanTokenAddress, Order.base);
        require(Order.base==HistoricalOrders[msg.sender][orderID].base&&Order.loanTokenAddress==HistoricalOrders[msg.sender][orderID].loanTokenAddress, "invalid tokens");
        /*require(
            Order.price > swapRate
                ? (Order.price - swapRate) < (Order.price * 4) / 100
                : (swapRate - Order.price) < (swapRate * 4) / 100,
            "price too far away"
        );*/
        require(Order.trader == msg.sender, "trader of order != sender");
        require(
            Order.orderID == HistoricalOrders[msg.sender][orderID].orderID,
            "improper ID"
        );
        require(
            HistoricalOrders[msg.sender][orderID].isActive == true,
            "inactive order specified"
        );
        require(
            Order.orderType == IWalletFactory.OrderType.LIMIT_OPEN
                ? Order.loanID == 0 || OrderEntry.inVals(ActiveTrades[msg.sender], Order.loanID)
                : OrderEntry.inVals(ActiveTrades[msg.sender], Order.loanID),
            "inactive loan"
        );
        orderExpiration[msg.sender][Order.orderID] = block.timestamp + DAYS_14;
        Order.loanData = "";
        if (Order.orderType == IWalletFactory.OrderType.LIMIT_OPEN) {
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
            IDeposits(vault).withdraw(msg.sender, Order.orderID);
            if (storedAmount > amountUsed) {
                IDeposits(vault).deposit(
                    Order.orderID,
                    amountUsed,
                    msg.sender,
                    usedToken
                );
            } else {
                SafeERC20.safeTransferFrom(
                    IERC20(usedToken),
                    msg.sender,
                    address(this),
                    amountUsed - storedAmount
                );
                IDeposits(vault).deposit(
                    Order.orderID,
                    amountUsed,
                    msg.sender,
                    usedToken
                );
            }
            SafeERC20.safeTransfer(
                IERC20(usedToken),
                msg.sender,
                IERC20Metadata(usedToken).balanceOf(address(this))
            );
        }
        HistoricalOrders[msg.sender][orderID] = Order;

        emit OrderAmended(
            msg.sender,
            Order.orderType,
            Order.price,
            orderID,
            Order.base,
            Order.loanTokenAddress
        );
    }

    function cancelOrder(uint256 orderID) public {
        require(
            HistoricalOrders[msg.sender][orderID].isActive == true,
            "inactive order"
        );
        HistoricalOrders[msg.sender][orderID].isActive = false;
        OrderRecords.removeOrderNum(HistOrders[msg.sender], orderID);
        OrderRecords.removeOrderNum(
            AllOrderIDs,
            matchingID[msg.sender][orderID]
        );
        if (OrderRecords.length(HistOrders[msg.sender]) == 0) {
            ActiveTraders.removeTrader(activeTraders, msg.sender);
        }
        if (
            HistoricalOrders[msg.sender][orderID].orderType ==
            IWalletFactory.OrderType.LIMIT_OPEN
        ) {
            address usedToken = IDeposits(vault).getTokenUsed(
                msg.sender,
                orderID
            );
            IDeposits(vault).withdraw(msg.sender, orderID);
            SafeERC20.safeTransfer(
                IERC20(usedToken),
                msg.sender,
                IERC20Metadata(usedToken).balanceOf(address(this))
            );
        }
        emit OrderCancelled(msg.sender, orderID);
    }
	
    function cancelOrderProtocol(address trader, uint256 orderID) public {
        require(
            HistoricalOrders[trader][orderID].isActive == true,
            "inactive order"
        );
		require(orderExpiration[trader][orderID] < block.timestamp);
		uint256 swapRate = currentSwapRate(HistoricalOrders[trader][orderID].loanTokenAddress, HistoricalOrders[trader][orderID].base);
        require(
            HistoricalOrders[trader][orderID].price > swapRate
                ? (HistoricalOrders[trader][orderID].price - swapRate) < (HistoricalOrders[trader][orderID].price * 4) / 100
                : (swapRate - HistoricalOrders[trader][orderID].price) < (swapRate * 4) / 100,
            "price too far away"
        );
        HistoricalOrders[trader][orderID].isActive = false;
        OrderRecords.removeOrderNum(HistOrders[trader], orderID);
        OrderRecords.removeOrderNum(
            AllOrderIDs,
            matchingID[trader][orderID]
        );
        if (OrderRecords.length(HistOrders[trader]) == 0) {
            ActiveTraders.removeTrader(activeTraders, trader);
        }
        if (
            HistoricalOrders[trader][orderID].orderType ==
            IWalletFactory.OrderType.LIMIT_OPEN
        ) {
            address usedToken = IDeposits(vault).getTokenUsed(
                trader,
                orderID
            );
            IDeposits(vault).withdraw(trader, orderID);
            SafeERC20.safeTransfer(
                IERC20(usedToken),
                trader,
                IERC20Metadata(usedToken).balanceOf(address(this))
            );
        }
        emit OrderCancelled(trader, orderID);
    }
	
	function minimumAmount() public view returns(uint256){
		return MIN_AMOUNT_IN_USDC;
	}
}
