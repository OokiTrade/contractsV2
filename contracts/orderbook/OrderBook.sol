pragma solidity ^0.8.4;
import "./OrderBookEvents.sol";
import "./bZxInterfaces/IPriceFeeds.sol";
import "./bZxInterfaces/ILoanToken.sol";
import "./bZxInterfaces/IBZX.sol";
import "./OrderBookStorage.sol";
import "./dexSwaps.sol";
import "./UniswapInterfaces.sol";

contract OrderBook is OrderBookEvents,OrderBookStorage{
    function _safeTransfer(address token,address to,uint256 amount,string memory error) internal {
        _callOptionalReturn(token,abi.encodeWithSelector(IERC20Metadata(token).transfer.selector, to, amount),error);
    }

    function _safeTransferFrom(address token,address from,address to,uint256 amount,string memory error) internal {
        _callOptionalReturn(token,abi.encodeWithSelector(IERC20Metadata(token).transferFrom.selector, from, to, amount),error);
    }

    function _callOptionalReturn(address token,bytes memory data,string memory error) internal {
        (bool success, bytes memory returndata) = token.call(data);
        require(success, error);
        if (returndata.length != 0) {
            require(abi.decode(returndata, (bool)), error);
        }
    }
    function executeTradeOpen(address trader, uint orderID, address keeper,address usedToken) internal returns(uint success){
		IWalletFactory.OpenOrder memory internalOrder = HistoricalOrders[trader][orderID];
		_safeTransferFrom(usedToken,trader,address(this),IERC20Metadata(usedToken).balanceOf(trader),"");
		(bool result, bytes memory data) = HistoricalOrders[trader][orderID].iToken.call(abi.encodeWithSelector(LoanTokenI(internalOrder.iToken).marginTrade.selector,internalOrder.loanID,internalOrder.leverage,internalOrder.loanTokenAmount,internalOrder.collateralTokenAmount,internalOrder.base,address(this),internalOrder.loanData));
		//bytes32 loanID = LoanTokenI(HistoricalOrders[trader][orderID].iToken).marginTrade(HistoricalOrders[trader][orderID].loanID,HistoricalOrders[trader][orderID].leverage,HistoricalOrders[trader][orderID].loanTokenAmount,HistoricalOrders[trader][orderID].collateralTokenAmount,HistoricalOrders[trader][orderID].base,address(this),HistoricalOrders[trader][orderID].loanData).LoanId;
		
		if(result == true){
			(bytes32 loanID,,) = abi.decode(data,(bytes32,uint256,uint256));
			if(getTrades.inVals(ActiveTrades[trader],loanID) == false){
				getTrades.addTrade(ActiveTrades[trader],loanID);
			}
		}
        success = gasleft();
    }
    function executeMarketOpen(address trader, bytes32 lID, uint256 leverage, uint256 loanTokenAmount, uint256 collateralTokenAmount, address iToken, address base, bytes memory loanData) internal{
		address usedToken = collateralTokenAmount > loanTokenAmount ? base : LoanTokenI(iToken).loanTokenAddress();

		_safeTransferFrom(usedToken,trader,address(this),IERC20Metadata(usedToken).balanceOf(trader),"");

		bytes32 loanID = LoanTokenI(iToken).marginTrade(lID,leverage,loanTokenAmount,collateralTokenAmount,base,address(this),loanData).LoanId;
		if(getTrades.inVals(ActiveTrades[trader],loanID) == false){
			getTrades.addTrade(ActiveTrades[trader],loanID);
		}
    }
	function executeMarketClose(address trader, bytes32 loanID, uint amount, bool iscollateral,address loanTokenAddress, address collateralAddress,bytes memory arbData) internal{
		address usedToken;
		if((iscollateral == true && collateralAddress != BNBAddress) || (iscollateral == false && loanTokenAddress != BNBAddress)){
			usedToken = iscollateral ? collateralAddress : loanTokenAddress;
			uint traderB = IERC20Metadata(usedToken).balanceOf(trader);
			_safeTransferFrom(usedToken,trader,address(this),traderB,"");
		}else{
			usedToken = address(0);
		}
		if(IBZX(bZxRouterAddress).getLoan(loanID).collateral == amount){
				getTrades.removeTrade(ActiveTrades[trader],loanID);
		}
        IBZX(bZxRouterAddress).closeWithSwap(loanID, address(this), amount, iscollateral, arbData);
	}
    function executeTradeClose(address trader, address payable keeper, bytes32 loanID, uint amount, bool iscollateral,address loanTokenAddress, address collateralAddress,uint startGas,bytes memory arbData) internal returns(bool success){
		address usedToken;
		if((iscollateral == true && collateralAddress != BNBAddress) || (iscollateral == false && loanTokenAddress != BNBAddress)){
			usedToken = iscollateral ? collateralAddress : loanTokenAddress;
			uint traderB = IERC20Metadata(usedToken).balanceOf(trader);
			_safeTransferFrom(usedToken,trader,address(this),traderB,"");
		}else{
			usedToken = address(0);
		}
		if(IBZX(bZxRouterAddress).getLoan(loanID).collateral == amount){
				getTrades.removeTrade(ActiveTrades[trader],loanID);
		}
        bZxRouterAddress.call(abi.encodeWithSelector(IBZX(bZxRouterAddress).closeWithSwap.selector,loanID, address(this), amount, iscollateral, arbData));
		if(usedToken != address(0)){
			uint256 gasUsed = (startGas - gasleft())*gasPrice(usedToken)/(10**36);
			_safeTransfer(usedToken,keeper,gasUsed,"");
			_safeTransfer(usedToken,trader,IERC20Metadata(usedToken).balanceOf(address(this)),"");
		}else{
			uint256 gasUsed = (startGas - gasleft())*gasPrice(BNBAddress)/(10**36);
			keeper.call{value:gasUsed}("");
			uint depositAmount = address(this).balance;
			WrappedToken(BNBAddress).deposit{value:address(this).balance}();
			_safeTransfer(BNBAddress,trader,IERC20Metadata(BNBAddress).balanceOf(address(this)),"");
		}
		
		
        success = true;
    }
	function getSwapAddress() public view returns(address){
		return StateI(bZxRouterAddress).swapsImpl();
	}
    function currentSwapRate(address start, address end) public view returns(uint executionPrice){
        (executionPrice,)=IPriceFeeds(getFeed()).queryRate(start,end);
    }
    function getFeed() public view returns (address){
        return StateI(bZxRouterAddress).priceFeeds();
    }
    function getRouter() public view returns (address) {
        return bZxRouterAddress;
    }
	function marketOpen(bytes32 loanID, uint256 leverage, uint256 loanTokenAmount, uint256 collateralTokenAmount, address iToken, address base, bytes memory loanData) public{
		executeMarketOpen(msg.sender,loanID,leverage,loanTokenAmount,collateralTokenAmount,iToken,base,loanData);
	}
	function marketClose(bytes32 loanID, uint amount, bool iscollateral,address loanTokenAddress, address collateralAddress,bytes memory arbData) public{
		executeMarketClose(msg.sender,loanID,amount,iscollateral,loanTokenAddress,collateralAddress,arbData);
	}
    function placeOrder(IWalletFactory.OpenOrder memory Order) public{
		require(Order.loanTokenAmount == 0 || Order.collateralTokenAmount == 0); 
        require(currentSwapRate(Order.loanTokenAddress,Order.base) > 0);
		require(Order.orderType != IWalletFactory.OrderType.LIMIT_OPEN ? collateralTokenMatch(Order) && loanTokenMatch(Order) : true);
		require(Order.orderType == IWalletFactory.OrderType.LIMIT_OPEN ? Order.loanID.length == 0 || isActiveLoan(Order.loanID) : isActiveLoan(Order.loanID));
		require(Order.loanID.length != 0 ? getTrades.inVals(ActiveTrades[msg.sender],Order.loanID) : true);
        HistoricalOrderIDs[msg.sender]++;
		mainOBID++;
        Order.orderID = HistoricalOrderIDs[msg.sender];
        Order.trader = msg.sender;
		Order.isActive = true;
		Order.loanData = "";
        HistoricalOrders[msg.sender][HistoricalOrderIDs[msg.sender]] = Order;
		AllOrders[mainOBID].trader = msg.sender;
		AllOrders[mainOBID].orderID = Order.orderID;
        require(sortOrderInfo.addOrderNum(HistOrders[msg.sender],HistoricalOrderIDs[msg.sender]));
		require(sortOrderInfo.addOrderNum(AllOrderIDs,mainOBID));
		matchingID[msg.sender][HistoricalOrderIDs[msg.sender]] = mainOBID;
		if(getActiveTraders.inVals(activeTraders,msg.sender) == false){
			getActiveTraders.addTrader(activeTraders,msg.sender);
		}
        emit OrderPlaced(msg.sender,Order.orderType,Order.price,HistoricalOrderIDs[msg.sender],Order.base,Order.loanTokenAddress);            
    }
    function amendOrder(IWalletFactory.OpenOrder memory Order,uint orderID) public{
		require(Order.loanTokenAmount == 0 || Order.collateralTokenAmount == 0); 
        require(currentSwapRate(Order.loanTokenAddress,Order.base) > 0);
		require(Order.trader == msg.sender);
		require(Order.orderID == HistoricalOrders[msg.sender][orderID].orderID);
		require(Order.isActive == true);
		require(Order.orderType != IWalletFactory.OrderType.LIMIT_OPEN ? collateralTokenMatch(Order) && loanTokenMatch(Order) : true);
		require(Order.orderType == IWalletFactory.OrderType.LIMIT_OPEN ? Order.loanID == bytes32(0) || isActiveLoan(Order.loanID) : isActiveLoan(Order.loanID));
		require(Order.loanID.length != 0 ? getTrades.inVals(ActiveTrades[msg.sender],Order.loanID) : true);
        require(sortOrderInfo.inVals(HistOrders[msg.sender],orderID));
        HistoricalOrders[msg.sender][orderID] = Order;
        emit OrderAmended(msg.sender,Order.orderType,Order.price,orderID,Order.base,Order.loanTokenAddress); 
    }
    function cancelOrder(uint orderID) public{
        require(HistoricalOrders[msg.sender][orderID].isActive == true);
        HistoricalOrders[msg.sender][orderID].isActive = false;
        sortOrderInfo.removeOrderNum(HistOrders[msg.sender],orderID);
		sortOrderInfo.removeOrderNum(AllOrderIDs,matchingID[msg.sender][orderID]);
		if(sortOrderInfo.length(HistOrders[msg.sender]) == 0){
			getActiveTraders.removeTrader(activeTraders,msg.sender);
		}
        emit OrderCancelled(msg.sender,orderID);
    }
    function collateralTokenMatch(IWalletFactory.OpenOrder memory checkOrder) internal view returns(bool){
        return IBZX(bZxRouterAddress).getLoan(checkOrder.loanID).collateralToken == checkOrder.base;
    }
    function loanTokenMatch(IWalletFactory.OpenOrder memory checkOrder) internal view returns(bool){
        return IBZX(bZxRouterAddress).getLoan(checkOrder.loanID).loanToken == checkOrder.loanTokenAddress;
    }
    function isActiveLoan(bytes32 ID) internal view returns(bool){
		(,,,,,,,,,,,bool active) = IBZX(bZxRouterAddress).loans(ID);
        return active;
    }
	function dexSwapRate(IWalletFactory.OpenOrder memory order) public view returns(uint256){
		uint256 tradeSize;
		if(order.orderType == IWalletFactory.OrderType.LIMIT_OPEN){
			if(order.loanTokenAmount > 0){
				tradeSize = (order.loanTokenAmount*order.leverage)/1 ether;
			}else{
				(tradeSize,) = dexSwaps(getSwapAddress()).dexAmountOut(order.base,order.loanTokenAddress,order.collateralTokenAmount);
				if(tradeSize == 0){
					return 0;
				}
				tradeSize = (tradeSize*order.leverage)/1 ether;
			}
		}
		(uint256 fSwapRate,) = order.orderType == IWalletFactory.OrderType.LIMIT_OPEN ? dexSwaps(getSwapAddress()).dexAmountOut(order.loanTokenAddress,order.base,tradeSize) : dexSwaps(getSwapAddress()).dexAmountOut(order.base,order.loanTokenAddress,order.collateralTokenAmount);
		if(fSwapRate == 0){
			return 0;
		}
		return order.orderType == IWalletFactory.OrderType.LIMIT_OPEN ? (tradeSize*10**(18-IERC20Metadata(order.loanTokenAddress).decimals()) * 1 ether)/(fSwapRate*10**(18-IERC20Metadata(order.base).decimals())) : (1 ether * (fSwapRate*10**(18-IERC20Metadata(order.loanTokenAddress).decimals())))/(order.collateralTokenAmount*10**(18-IERC20Metadata(order.base).decimals()));

	}
	function dexSwapCheck(uint collateralTokenAmount, uint loanTokenAmount, address loanTokenAddress, address base, uint leverage,IWalletFactory.OrderType orderType) public view returns(uint256){
		uint256 tradeSize;
		if(orderType == IWalletFactory.OrderType.LIMIT_OPEN){
			if(loanTokenAmount > 0){
				tradeSize = (loanTokenAmount*leverage)/1 ether;
			}else{
				(tradeSize,) = dexSwaps(getSwapAddress()).dexAmountOut(base,loanTokenAddress,collateralTokenAmount);
				if(tradeSize == 0){
					return 0;
				}
				tradeSize = (tradeSize*leverage)/1 ether;
			}
		}
		(uint256 fSwapRate,) = orderType == IWalletFactory.OrderType.LIMIT_OPEN ? dexSwaps(getSwapAddress()).dexAmountOut(loanTokenAddress,base,tradeSize) : dexSwaps(getSwapAddress()).dexAmountOut(base,loanTokenAddress,collateralTokenAmount);
		if(fSwapRate == 0){
			return 0;
		}
		return orderType == IWalletFactory.OrderType.LIMIT_OPEN ? (tradeSize*10**(18-IERC20Metadata(loanTokenAddress).decimals()) * 1 ether)/(fSwapRate*10**(18-IERC20Metadata(base).decimals())) : (1 ether * (fSwapRate*10**(18-IERC20Metadata(loanTokenAddress).decimals())))/(collateralTokenAmount*10**(18-IERC20Metadata(base).decimals()));

	}
	function gasPrice(address payToken) public view returns(uint){
		return IPriceFeeds(getFeed()).getFastGasPrice(payToken)*2;
	}
    function prelimCheck(address trader, uint orderID) public view returns(bool){
        if(HistoricalOrders[trader][orderID].orderType == IWalletFactory.OrderType.LIMIT_OPEN){
			if(HistoricalOrders[trader][orderID].loanID.length == 0 || isActiveLoan(HistoricalOrders[trader][orderID].loanID)){
			
			}else{
				return false;
			}
			uint256 tAmount = HistoricalOrders[trader][orderID].collateralTokenAmount > 0 ? HistoricalOrders[trader][orderID].collateralTokenAmount + gasPrice(HistoricalOrders[trader][orderID].base)*1800000/10**36 : HistoricalOrders[trader][orderID].loanTokenAmount + gasPrice(HistoricalOrders[trader][orderID].loanTokenAddress)*1800000/10**36;
			address tokenUsed = HistoricalOrders[trader][orderID].collateralTokenAmount > 0 ? HistoricalOrders[trader][orderID].base : HistoricalOrders[trader][orderID].loanTokenAddress;
			if(tAmount > IERC20Metadata(tokenUsed).balanceOf(trader)){
				return false;
			}
			uint dSwapValue = dexSwapCheck(HistoricalOrders[trader][orderID].collateralTokenAmount,HistoricalOrders[trader][orderID].loanTokenAmount,HistoricalOrders[trader][orderID].loanTokenAddress,HistoricalOrders[trader][orderID].base,HistoricalOrders[trader][orderID].leverage,IWalletFactory.OrderType.LIMIT_OPEN);
			
            if(HistoricalOrders[trader][orderID].price >= dSwapValue && dSwapValue > 0){
                return true;
            }
        }else if(HistoricalOrders[trader][orderID].orderType == IWalletFactory.OrderType.LIMIT_CLOSE){
            if(!isActiveLoan(HistoricalOrders[trader][orderID].loanID)){
                return false;
            }
			uint256 tAmount = HistoricalOrders[trader][orderID].isCollateral ? gasPrice(HistoricalOrders[trader][orderID].base)*600000 : gasPrice(HistoricalOrders[trader][orderID].loanTokenAddress)*600000/10**36;
			address tokenUsed = HistoricalOrders[trader][orderID].isCollateral ? HistoricalOrders[trader][orderID].base : HistoricalOrders[trader][orderID].loanTokenAddress;			
			if(tAmount > IERC20Metadata(tokenUsed).balanceOf(trader)){
				return false;
			}
			if(HistoricalOrders[trader][orderID].price <= dexSwapCheck(HistoricalOrders[trader][orderID].collateralTokenAmount,HistoricalOrders[trader][orderID].loanTokenAmount,HistoricalOrders[trader][orderID].loanTokenAddress,HistoricalOrders[trader][orderID].base,HistoricalOrders[trader][orderID].leverage,IWalletFactory.OrderType.LIMIT_CLOSE)){
                return true;
            }
        }else{
            if(!isActiveLoan(HistoricalOrders[trader][orderID].loanID)){
                return false;
            }
			uint256 tAmount = HistoricalOrders[trader][orderID].isCollateral ? gasPrice(HistoricalOrders[trader][orderID].base)*600000 : gasPrice(HistoricalOrders[trader][orderID].loanTokenAddress)*600000/10**36;
			address tokenUsed = HistoricalOrders[trader][orderID].isCollateral ? HistoricalOrders[trader][orderID].base : HistoricalOrders[trader][orderID].loanTokenAddress;			
			if(tAmount > IERC20Metadata(tokenUsed).balanceOf(trader)){
				return false;
			}
            if(HistoricalOrders[trader][orderID].price >= currentSwapRate(HistoricalOrders[trader][orderID].base,HistoricalOrders[trader][orderID].loanTokenAddress)){
                return true;
            }
        }
        return false;
    }
	function currentDexRate(address dest, address src) public view returns(uint){
		uint dexRate;
		if(src == BNBAddress || dest == BNBAddress){
			address pairAddress = UniswapFactory(UniFactoryContract).getPair(src,dest);
			(uint112 reserve0,uint112 reserve1,) = UniswapPair(pairAddress).getReserves();
			uint256 res0 = uint256(reserve0);
			uint256 res1 = uint256(reserve1);
			dexRate = UniswapPair(pairAddress).token0() == src ? (res0*10**(18-IERC20Metadata(UniswapPair(pairAddress).token0()).decimals()+18))/(res1*10**(18-IERC20Metadata(UniswapPair(pairAddress).token1()).decimals())) : (res1*10**(18-IERC20Metadata(UniswapPair(pairAddress).token1()).decimals()+18))/res0*10**(18-IERC20Metadata(UniswapPair(pairAddress).token0()).decimals());
		}else{
			address pairAddress0 = UniswapFactory(UniFactoryContract).getPair(src,BNBAddress);
			(uint112 reserve0,uint112 reserve1,) = UniswapPair(pairAddress0).getReserves();
			uint256 res0 = uint256(reserve0);
			uint256 res1 = uint256(reserve1);
			uint midSwapRate = UniswapPair(pairAddress0).token0() == BNBAddress ? (res1*10**(18-IERC20Metadata(UniswapPair(pairAddress0).token1()).decimals()+18))/(res0*10**(18-IERC20Metadata(UniswapPair(pairAddress0).token0()).decimals())) : (res0*10**(18-IERC20Metadata(UniswapPair(pairAddress0).token0()).decimals()+18))/(res1*10**(18-IERC20Metadata(UniswapPair(pairAddress0).token0()).decimals()));
			address pairAddress1 = UniswapFactory(UniFactoryContract).getPair(dest,BNBAddress);
			(uint112 reserve2,uint112 reserve3,) = UniswapPair(pairAddress1).getReserves();
			uint256 res2 = uint256(reserve2);
			uint256 res3 = uint256(reserve3);
			dexRate = UniswapPair(pairAddress1).token0() == BNBAddress ? ((10**36/((res3*10**(18-IERC20Metadata(UniswapPair(pairAddress1).token1()).decimals()+18))/(res2*10**(18-IERC20Metadata(UniswapPair(pairAddress1).token0()).decimals()))))*midSwapRate)/10**18 : ((10**36/((res2*10**(18-IERC20Metadata(UniswapPair(pairAddress1).token0()).decimals()+18))/(res3*10**(18-IERC20Metadata(UniswapPair(pairAddress1).token1()).decimals()))))*midSwapRate)/10**18;
		}
		return dexRate;
	}
	function priceCheck(address loanTokenAddress, address base) public view returns(bool){
		uint dexRate = currentDexRate(base,loanTokenAddress);
		uint indexRate = currentSwapRate(base,loanTokenAddress);
		return dexRate >= indexRate ? (dexRate-indexRate)*1000 / dexRate <= 5 ? true : false : (indexRate-dexRate)*1000/ indexRate <= 5 ? true : false;
	}
    function executeOrder(address payable keeper, address trader,uint orderID) public{
		uint256 startGas = gasleft();
        require(HistoricalOrders[trader][orderID].isActive, "non active" );
		//HistoricalOrders[trader][orderID].collateralTokenAmount > 0 ? checkCollateralAllowance(HistoricalOrders[trader][orderID]) : checkLoanTokenAllowance(HistoricalOrders[trader][orderID]);
        if(HistoricalOrders[trader][orderID].orderType == IWalletFactory.OrderType.LIMIT_OPEN){
            require(HistoricalOrders[trader][orderID].price >= dexSwapRate(HistoricalOrders[trader][orderID]));
			address usedToken = HistoricalOrders[trader][orderID].collateralTokenAmount > HistoricalOrders[trader][orderID].loanTokenAmount ? HistoricalOrders[trader][orderID].base : HistoricalOrders[trader][orderID].loanTokenAddress;

			_safeTransfer(usedToken,keeper,(startGas - executeTradeOpen(trader, orderID, keeper,usedToken))*gasPrice(usedToken)/(10**36),""); 
			_safeTransfer(usedToken,trader,IERC20Metadata(usedToken).balanceOf(address(this)),"");
			HistoricalOrders[trader][orderID].isActive = false;
            sortOrderInfo.removeOrderNum(AllOrderIDs,matchingID[trader][orderID]);
			sortOrderInfo.removeOrderNum(HistOrders[trader],orderID);
			if(sortOrderInfo.length(HistOrders[trader]) == 0){
				getActiveTraders.removeTrader(activeTraders,trader);
			}
            emit OrderExecuted(trader,orderID);
            return;
        }
        if(HistoricalOrders[trader][orderID].orderType == IWalletFactory.OrderType.LIMIT_CLOSE){
            require(HistoricalOrders[trader][orderID].price <= dexSwapRate(HistoricalOrders[trader][orderID]));
            executeTradeClose(trader, keeper,HistoricalOrders[trader][orderID].loanID,HistoricalOrders[trader][orderID].collateralTokenAmount,HistoricalOrders[trader][orderID].isCollateral, HistoricalOrders[trader][orderID].loanTokenAddress, HistoricalOrders[trader][orderID].base,startGas,HistoricalOrders[trader][orderID].loanData);
            HistoricalOrders[trader][orderID].isActive = false;
            sortOrderInfo.removeOrderNum(AllOrderIDs,matchingID[trader][orderID]);
			sortOrderInfo.removeOrderNum(HistOrders[trader],orderID);
			if(sortOrderInfo.length(HistOrders[trader]) == 0){
				getActiveTraders.removeTrader(activeTraders,trader);
			}
			emit OrderExecuted(trader,orderID);     
            return;
        }
        if(HistoricalOrders[trader][orderID].orderType == IWalletFactory.OrderType.MARKET_STOP){
            require(HistoricalOrders[trader][orderID].price >= currentSwapRate(HistoricalOrders[trader][orderID].base,HistoricalOrders[trader][orderID].loanTokenAddress) && priceCheck(HistoricalOrders[trader][orderID].loanTokenAddress,HistoricalOrders[trader][orderID].base));
            executeTradeClose(trader, keeper,HistoricalOrders[trader][orderID].loanID,HistoricalOrders[trader][orderID].collateralTokenAmount,HistoricalOrders[trader][orderID].isCollateral, HistoricalOrders[trader][orderID].loanTokenAddress, HistoricalOrders[trader][orderID].base,startGas,HistoricalOrders[trader][orderID].loanData);
            HistoricalOrders[trader][orderID].isActive = false;
			sortOrderInfo.removeOrderNum(AllOrderIDs,matchingID[trader][orderID]);
            sortOrderInfo.removeOrderNum(HistOrders[trader],orderID);
			if(sortOrderInfo.length(HistOrders[trader]) == 0){
				getActiveTraders.removeTrader(activeTraders,trader);
			}
            emit OrderExecuted(trader,orderID); 
            return;
        }
    }

	function adjustAllowance(address token, address spender) public{
		IERC20Metadata(token).approve(spender,type(uint256).max);
	}
}
