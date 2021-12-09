pragma solidity ^0.8.4;
import "../Storage/OrderBookEvents.sol";
import "../Storage/OrderBookStorage.sol";
import "./dexSwaps.sol";
import "./UniswapInterfaces.sol";
import "../OrderVault/IDeposits.sol";
import "../../utils/ExponentMath.sol";

contract OrderBook is OrderBookEvents, OrderBookStorage {
	using ExponentMath for uint256;
    function executeTradeOpen(
        address trader,
        uint256 orderID,
        address keeper,
        address usedToken
    ) internal returns (uint256 success) {
        IWalletFactory.OpenOrder memory internalOrder = HistoricalOrders[
            trader
        ][orderID];
        IDeposits(vault).withdraw(trader, orderID);
        SafeERC20.safeTransferFrom(
            IERC20(usedToken),
            trader,
            address(this),
            IERC20Metadata(usedToken).balanceOf(trader)
        );
        (bool result, bytes memory data) = HistoricalOrders[trader][orderID]
            .iToken
            .call(
                abi.encodeWithSelector(
                    LoanTokenI(internalOrder.iToken).marginTrade.selector,
                    internalOrder.loanID,
                    internalOrder.leverage,
                    internalOrder.loanTokenAmount,
                    internalOrder.collateralTokenAmount,
                    internalOrder.base,
                    address(this),
                    internalOrder.loanData
                )
            );
        if (result == true) {
            (bytes32 loanID, , ) = abi.decode(
                data,
                (bytes32, uint256, uint256)
            );
            if (OrderEntry.inVals(ActiveTrades[trader], loanID) == false) {
                OrderEntry.addTrade(ActiveTrades[trader], loanID);
            }
        }
        success = gasleft();
    }

    function executeTradeClose(
        address trader,
        address payable keeper,
        bytes32 loanID,
        uint256 amount,
        bool iscollateral,
        address loanTokenAddress,
        address collateralAddress,
        uint256 startGas,
        bytes memory arbData
    ) internal returns (bool success) {
        address usedToken;
        usedToken = iscollateral ? collateralAddress : loanTokenAddress;
        uint256 traderB = IERC20Metadata(usedToken).balanceOf(trader);
        SafeERC20.safeTransferFrom(
            IERC20(usedToken),
            trader,
            address(this),
            traderB
        );
        if (IBZX(bZxRouterAddress).getLoan(loanID).collateral == amount) {
            OrderEntry.removeTrade(ActiveTrades[trader], loanID);
        }
        bZxRouterAddress.call(
            abi.encodeWithSelector(
                IBZX(bZxRouterAddress).closeWithSwap.selector,
                loanID,
                address(this),
                amount,
                iscollateral,
                arbData
            )
        );
        if (usedToken == wrapToken) {
            WrappedToken(wrapToken).deposit{value: address(this).balance}();
        }
        uint256 gasUsed = ((startGas - gasleft()) * gasPrice(usedToken)) /
            (10**36);
        SafeERC20.safeTransfer(IERC20(usedToken), keeper, gasUsed);
        SafeERC20.safeTransfer(
            IERC20(usedToken),
            trader,
            IERC20Metadata(usedToken).balanceOf(address(this))
        );

        success = true;
    }

    function getSwapAddress() public view returns (address) {
        return StateI(bZxRouterAddress).swapsImpl();
    }

    function currentSwapRate(address start, address end)
        public
        view
        returns (uint256 executionPrice)
    {
        (executionPrice, ) = IPriceFeeds(getFeed()).queryRate(end, start);
    }

    function getFeed() public view returns (address) {
        return StateI(bZxRouterAddress).priceFeeds();
    }

    function isActiveLoan(bytes32 ID) internal view returns (bool) {
        (, , , , , , , , , , , bool active) = IBZX(bZxRouterAddress).loans(ID);
        return active;
    }

    function dexSwapRate(IWalletFactory.OpenOrder memory order)
        public
        view
        returns (uint256)
    {
        uint256 tradeSize;
        if (order.orderType == IWalletFactory.OrderType.LIMIT_OPEN) {
            if (order.loanTokenAmount > 0) {
                tradeSize = (order.loanTokenAmount * order.leverage) / 1 ether;
            } else {
                (tradeSize, ) = dexSwaps(getSwapAddress()).dexAmountOut(
                    order.base,
                    order.loanTokenAddress,
                    order.collateralTokenAmount
                );
                if (tradeSize == 0) {
                    return 0;
                }
                tradeSize = (tradeSize * order.leverage) / 1 ether;
            }
        }
        (uint256 fSwapRate, ) = order.orderType ==
            IWalletFactory.OrderType.LIMIT_OPEN
            ? dexSwaps(getSwapAddress()).dexAmountOut(
                order.loanTokenAddress,
                order.base,
                tradeSize
            )
            : dexSwaps(getSwapAddress()).dexAmountOut(
                order.base,
                order.loanTokenAddress,
                order.collateralTokenAmount
            );
        if (fSwapRate == 0) {
            return 0;
        }
        return
            order.orderType == IWalletFactory.OrderType.LIMIT_OPEN
                ? (tradeSize.TenExp(18 - int8(IERC20Metadata(order.loanTokenAddress).decimals())) * 1 ether) /
                    (fSwapRate.TenExp(18 - int8(IERC20Metadata(order.base).decimals())))
                : (1 ether *(fSwapRate.TenExp(18 - int8(IERC20Metadata(order.loanTokenAddress).decimals())))) /
                    (order.collateralTokenAmount.TenExp(18 - int8(IERC20Metadata(order.base).decimals())));
    }

    function dexSwapCheck(
        uint256 collateralTokenAmount,
        uint256 loanTokenAmount,
        address loanTokenAddress,
        address base,
        uint256 leverage,
        IWalletFactory.OrderType orderType
    ) public view returns (uint256) {
        uint256 tradeSize;
        if (orderType == IWalletFactory.OrderType.LIMIT_OPEN) {
            if (loanTokenAmount > 0) {
                tradeSize = (loanTokenAmount * leverage) / 1 ether;
            } else {
                (tradeSize, ) = dexSwaps(getSwapAddress()).dexAmountOut(
                    base,
                    loanTokenAddress,
                    collateralTokenAmount
                );
                if (tradeSize == 0) {
                    return 0;
                }
                tradeSize = (tradeSize * leverage) / 1 ether;
            }
        }
        (uint256 fSwapRate, ) = orderType == IWalletFactory.OrderType.LIMIT_OPEN
            ? dexSwaps(getSwapAddress()).dexAmountOut(
                loanTokenAddress,
                base,
                tradeSize
            )
            : dexSwaps(getSwapAddress()).dexAmountOut(
                base,
                loanTokenAddress,
                collateralTokenAmount
            );
        if (fSwapRate == 0) {
            return 0;
        }
        return
            orderType == IWalletFactory.OrderType.LIMIT_OPEN
                ? (tradeSize.TenExp(18 - int8(IERC20Metadata(loanTokenAddress).decimals())) *
                    1 ether) /
                    (fSwapRate.TenExp(18 - int8(IERC20Metadata(base).decimals())))
                : (1 ether *
                    (fSwapRate.TenExp(18 -
                                int8(IERC20Metadata(loanTokenAddress).decimals())))) /
                    (collateralTokenAmount.TenExp(18 - int8(IERC20Metadata(base).decimals())));
    }

    function gasPrice(address payToken) public view returns (uint256) {
        return IPriceFeeds(getFeed()).getFastGasPrice(payToken) * 2;
    }

	function clearOrder(address trader, uint256 orderID)
		public
		view
		returns (bool)
	{
		if(orderExpiration[trader][orderID] < block.timestamp){
			return true;
		}
		uint256 swapRate = currentSwapRate(HistoricalOrders[trader][orderID].loanTokenAddress, HistoricalOrders[trader][orderID].base);
		if(!(HistoricalOrders[trader][orderID].price > swapRate
                ? (HistoricalOrders[trader][orderID].price - swapRate) < (HistoricalOrders[trader][orderID].price * 4) / 100
                : (swapRate - HistoricalOrders[trader][orderID].price) < (swapRate * 4) / 100)){
			return true;
		}
		return false;
	}

    function prelimCheck(address trader, uint256 orderID)
        public
        view
        returns (bool)
    {
        if (orderExpiration[trader][orderID] < block.timestamp) {
            return false;
        }
        if (
            HistoricalOrders[trader][orderID].orderType ==
            IWalletFactory.OrderType.LIMIT_OPEN
        ) {
            if (
                HistoricalOrders[trader][orderID].loanID == 0 ||
                isActiveLoan(HistoricalOrders[trader][orderID].loanID)
            ) {} else {
                return false;
            }
            uint256 tAmount = HistoricalOrders[trader][orderID]
                .collateralTokenAmount > 0
                ? HistoricalOrders[trader][orderID].collateralTokenAmount +
                    (gasPrice(HistoricalOrders[trader][orderID].base) *
                        2300000) /
                    10**36
                : HistoricalOrders[trader][orderID].loanTokenAmount +
                    (gasPrice(
                        HistoricalOrders[trader][orderID].loanTokenAddress
                    ) * 2300000) /
                    10**36;
            address tokenUsed = HistoricalOrders[trader][orderID]
                .collateralTokenAmount > 0
                ? HistoricalOrders[trader][orderID].base
                : HistoricalOrders[trader][orderID].loanTokenAddress;
            if (
                tAmount >
                IERC20Metadata(tokenUsed).balanceOf(trader) +
                    IDeposits(vault).getDeposit(trader, orderID)
            ) {
                return false;
            }
            uint256 dSwapValue = dexSwapCheck(
                HistoricalOrders[trader][orderID].collateralTokenAmount,
                HistoricalOrders[trader][orderID].loanTokenAmount,
                HistoricalOrders[trader][orderID].loanTokenAddress,
                HistoricalOrders[trader][orderID].base,
                HistoricalOrders[trader][orderID].leverage,
                IWalletFactory.OrderType.LIMIT_OPEN
            );

            if (
                HistoricalOrders[trader][orderID].price >= dSwapValue &&
                dSwapValue > 0
            ) {
                return true;
            }
        } else if (
            HistoricalOrders[trader][orderID].orderType ==
            IWalletFactory.OrderType.LIMIT_CLOSE
        ) {
            if (!isActiveLoan(HistoricalOrders[trader][orderID].loanID)) {
                return false;
            }
            uint256 tAmount = HistoricalOrders[trader][orderID].isCollateral
                ? (gasPrice(HistoricalOrders[trader][orderID].base) * 1600000) /
                    10**36
                : (gasPrice(
                    HistoricalOrders[trader][orderID].loanTokenAddress
                ) * 1600000) / 10**36;
            address tokenUsed = HistoricalOrders[trader][orderID].isCollateral
                ? HistoricalOrders[trader][orderID].base
                : HistoricalOrders[trader][orderID].loanTokenAddress;
            if (tAmount > IERC20Metadata(tokenUsed).balanceOf(trader)) {
                return false;
            }
            if (
                HistoricalOrders[trader][orderID].price <=
                dexSwapCheck(
                    HistoricalOrders[trader][orderID].collateralTokenAmount,
                    HistoricalOrders[trader][orderID].loanTokenAmount,
                    HistoricalOrders[trader][orderID].loanTokenAddress,
                    HistoricalOrders[trader][orderID].base,
                    HistoricalOrders[trader][orderID].leverage,
                    IWalletFactory.OrderType.LIMIT_CLOSE
                )
            ) {
                return true;
            }
        } else {
            if (!isActiveLoan(HistoricalOrders[trader][orderID].loanID)) {
                return false;
            }
            uint256 tAmount = HistoricalOrders[trader][orderID].isCollateral
                ? (gasPrice(HistoricalOrders[trader][orderID].base) * 1600000) /
                    10**36
                : (gasPrice(
                    HistoricalOrders[trader][orderID].loanTokenAddress
                ) * 1600000) / 10**36;
            address tokenUsed = HistoricalOrders[trader][orderID].isCollateral
                ? HistoricalOrders[trader][orderID].base
                : HistoricalOrders[trader][orderID].loanTokenAddress;
            if (tAmount > IERC20Metadata(tokenUsed).balanceOf(trader)) {
                return false;
            }
            if (
                HistoricalOrders[trader][orderID].price >=
                currentSwapRate(
                    HistoricalOrders[trader][orderID].base,
                    HistoricalOrders[trader][orderID].loanTokenAddress
                )
            ) {
                return true;
            }
        }
        return false;
    }

    function currentDexRate(address dest, address src)
        public
        view
        returns (uint256)
    {
        uint256 dexRate;
        if (src == wrapToken || dest == wrapToken) {
            address pairAddress = UniswapFactory(UniFactoryContract).getPair(
                src,
                dest
            );
            (uint112 reserve0, uint112 reserve1, ) = UniswapPair(pairAddress)
                .getReserves();
            uint256 res0 = uint256(reserve0);
            uint256 res1 = uint256(reserve1);
            dexRate = UniswapPair(pairAddress).token0() == src
                ? (res0.TenExp(18 -
                            int8(IERC20Metadata(UniswapPair(pairAddress).token0())
                                .decimals()) +
                            18)) /
                    (res1.TenExp(18 -
                                int8(IERC20Metadata(
                                    UniswapPair(pairAddress).token1()
                                ).decimals())))
                : ((res1.TenExp(18 -
                            int8(IERC20Metadata(UniswapPair(pairAddress).token1())
                                .decimals()) +
                            18)) / res0).TenExp(18 -
                            int8(IERC20Metadata(UniswapPair(pairAddress).token0())
                                .decimals()));
        } else {
            address pairAddress0 = UniswapFactory(UniFactoryContract).getPair(
                src,
                wrapToken
            );
            (uint112 reserve0, uint112 reserve1, ) = UniswapPair(pairAddress0)
                .getReserves();
            uint256 res0 = uint256(reserve0);
            uint256 res1 = uint256(reserve1);
            uint256 midSwapRate = UniswapPair(pairAddress0).token0() ==
                wrapToken
                ? (res1.TenExp(18 -
                            int8(IERC20Metadata(UniswapPair(pairAddress0).token1())
                                .decimals()) +
                            18)) /
                    (res0.TenExp(18 -
                                int8(IERC20Metadata(
                                    UniswapPair(pairAddress0).token0()
                                ).decimals())))
                : (res0.TenExp(18 - int8(IERC20Metadata(UniswapPair(pairAddress0).token0()).decimals()) + 18)) /
                    (res1.TenExp(18 - int8(IERC20Metadata(UniswapPair(pairAddress0).token0()).decimals())));
            address pairAddress1 = UniswapFactory(UniFactoryContract).getPair(
                dest,
                wrapToken
            );
            (uint112 reserve2, uint112 reserve3, ) = UniswapPair(pairAddress1)
                .getReserves();
            uint256 res2 = uint256(reserve2);
            uint256 res3 = uint256(reserve3);
            dexRate = UniswapPair(pairAddress1).token0() == wrapToken
                ? ((10**36 /
                    ((res3.TenExp(18 -
                                int8(IERC20Metadata(
                                    UniswapPair(pairAddress1).token1()
                                ).decimals()) +
                                18)) /
                        (res2.TenExp(18 -
                                    int8(IERC20Metadata(
                                        UniswapPair(pairAddress1).token0()
                                    ).decimals()))))) * midSwapRate) / 10**18
                : ((10**36 /
                    ((res2.TenExp(18 -
                                int8(IERC20Metadata(
                                    UniswapPair(pairAddress1).token0()
                                ).decimals()) +
                                18)) /
                        (res3.TenExp(18 -
                                    int8(IERC20Metadata(
                                        UniswapPair(pairAddress1).token1()
                                    ).decimals()))))) * midSwapRate) / 10**18;
        }
        return dexRate;
    }

    function priceCheck(address loanTokenAddress, address base)
        public
        view
        returns (bool)
    {
        uint256 dexRate = currentDexRate(base, loanTokenAddress);
        uint256 indexRate = currentSwapRate(base, loanTokenAddress);
        return
            dexRate >= indexRate
                ? ((dexRate - indexRate) * 1000) / dexRate <= 5 ? true : false
                : ((indexRate - dexRate) * 1000) / indexRate <= 5
                ? true
                : false;
    }

    function executeOrder(
        address payable keeper,
        address trader,
        uint256 orderID
    ) public {
        uint256 startGas = gasleft();
        require(HistoricalOrders[trader][orderID].isActive, "non active");
        //HistoricalOrders[trader][orderID].collateralTokenAmount > 0 ? checkCollateralAllowance(HistoricalOrders[trader][orderID]) : checkLoanTokenAllowance(HistoricalOrders[trader][orderID]);
        if (
            HistoricalOrders[trader][orderID].orderType ==
            IWalletFactory.OrderType.LIMIT_OPEN
        ) {
            require(
                HistoricalOrders[trader][orderID].price >=
                    dexSwapRate(HistoricalOrders[trader][orderID]),
                "invalid swap rate"
            );
            address usedToken = HistoricalOrders[trader][orderID]
                .collateralTokenAmount >
                HistoricalOrders[trader][orderID].loanTokenAmount
                ? HistoricalOrders[trader][orderID].base
                : HistoricalOrders[trader][orderID].loanTokenAddress;

            SafeERC20.safeTransfer(
                IERC20(usedToken),
                keeper,
                ((startGas -
                    executeTradeOpen(trader, orderID, keeper, usedToken)) *
                    gasPrice(usedToken)) / (10**36)
            );
            SafeERC20.safeTransfer(
                IERC20(usedToken),
                trader,
                IERC20Metadata(usedToken).balanceOf(address(this))
            );
            HistoricalOrders[trader][orderID].isActive = false;
            OrderRecords.removeOrderNum(
                AllOrderIDs,
                matchingID[trader][orderID]
            );
            OrderRecords.removeOrderNum(HistOrders[trader], orderID);
            if (OrderRecords.length(HistOrders[trader]) == 0) {
                ActiveTraders.removeTrader(activeTraders, trader);
            }
            emit OrderExecuted(trader, orderID);
            return;
        }
        if (
            HistoricalOrders[trader][orderID].orderType ==
            IWalletFactory.OrderType.LIMIT_CLOSE
        ) {
            require(
                HistoricalOrders[trader][orderID].price <=
                    dexSwapRate(HistoricalOrders[trader][orderID]),
                "invalid swap rate"
            );
            executeTradeClose(
                trader,
                keeper,
                HistoricalOrders[trader][orderID].loanID,
                HistoricalOrders[trader][orderID].collateralTokenAmount,
                HistoricalOrders[trader][orderID].isCollateral,
                HistoricalOrders[trader][orderID].loanTokenAddress,
                HistoricalOrders[trader][orderID].base,
                startGas,
                HistoricalOrders[trader][orderID].loanData
            );
            HistoricalOrders[trader][orderID].isActive = false;
            OrderRecords.removeOrderNum(
                AllOrderIDs,
                matchingID[trader][orderID]
            );
            OrderRecords.removeOrderNum(HistOrders[trader], orderID);
            if (OrderRecords.length(HistOrders[trader]) == 0) {
                ActiveTraders.removeTrader(activeTraders, trader);
            }
            emit OrderExecuted(trader, orderID);
            return;
        }
        if (
            HistoricalOrders[trader][orderID].orderType ==
            IWalletFactory.OrderType.MARKET_STOP
        ) {
            require(
                HistoricalOrders[trader][orderID].price >=
                    currentSwapRate(
                        HistoricalOrders[trader][orderID].base,
                        HistoricalOrders[trader][orderID].loanTokenAddress
                    ) &&
                    priceCheck(
                        HistoricalOrders[trader][orderID].loanTokenAddress,
                        HistoricalOrders[trader][orderID].base
                    ),
                "invalid swap rate"
            );
            executeTradeClose(
                trader,
                keeper,
                HistoricalOrders[trader][orderID].loanID,
                HistoricalOrders[trader][orderID].collateralTokenAmount,
                HistoricalOrders[trader][orderID].isCollateral,
                HistoricalOrders[trader][orderID].loanTokenAddress,
                HistoricalOrders[trader][orderID].base,
                startGas,
                HistoricalOrders[trader][orderID].loanData
            );
            HistoricalOrders[trader][orderID].isActive = false;
            OrderRecords.removeOrderNum(
                AllOrderIDs,
                matchingID[trader][orderID]
            );
            OrderRecords.removeOrderNum(HistOrders[trader], orderID);
            if (OrderRecords.length(HistOrders[trader]) == 0) {
                ActiveTraders.removeTrader(activeTraders, trader);
            }
            emit OrderExecuted(trader, orderID);
            return;
        }
    }
	function setVaultAddress(address nVault) onlyOwner() public{
		vault = nVault;
	}
}
