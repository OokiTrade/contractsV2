pragma solidity ^0.8.0;
import "../Storage/OrderBookEvents.sol";
import "../Storage/OrderBookStorage.sol";
import "./dexSwaps.sol";
import "./UniswapInterfaces.sol";
import "../OrderVault/IDeposits.sol";
import "../../utils/ExponentMath.sol";
import "../../interfaces/IDexRecords.sol";

contract OrderBook is OrderBookEvents, OrderBookStorage {
    using ExponentMath for uint256;
	using EnumerableSet for EnumerableSet.Bytes32Set;
	
	function initialize(
		address target)
		public
		onlyOwner  
	{
		_setTarget(this.getSwapAddress.selector, target);
		_setTarget(this.currentSwapRate.selector, target);
		_setTarget(this.getFeed.selector, target);
		_setTarget(this.dexSwapRate.selector, target);
		_setTarget(this.clearOrder.selector, target);
		_setTarget(this.prelimCheck.selector, target);
		_setTarget(this.currentDexRate.selector, target);
		_setTarget(this.priceCheck.selector, target);
		_setTarget(this.executeOrder.selector, target);
		_setTarget(this.setVaultAddress.selector, target);
	}
	
	
    function _executeTradeOpen(address trader, bytes32 orderID) internal {
        IOrderBook.OpenOrder memory internalOrder = _allOrders[orderID];
        IDeposits(vault).withdraw(trader, orderID);
        (bool result, bytes memory data) = _allOrders[orderID].iToken.call(
            abi.encodeWithSelector(
                IToken(internalOrder.iToken).marginTrade.selector,
                internalOrder.loanID,
                internalOrder.leverage,
                internalOrder.loanTokenAmount,
                internalOrder.collateralTokenAmount,
                internalOrder.base,
                address(this),
                internalOrder.loanDataBytes
            )
        );
        if (result) {
            (bytes32 loanID, , ) = abi.decode(
                data,
                (bytes32, uint256, uint256)
            );
            if (!_activeTrades[trader].contains(loanID)) {
                _activeTrades[trader].add(loanID);
            }
        }
    }

    function _executeTradeClose(
        address trader,
        bytes32 loanID,
        uint256 amount,
        bool iscollateral,
        address collateralAddress,
        bytes memory loanDataBytes
    ) internal {
        if (IBZx(protocol).getLoan(loanID).collateral == amount) {
            _activeTrades[trader].remove(loanID);
        }
        protocol.call(
            abi.encodeWithSelector(
                IBZx(protocol).closeWithSwap.selector,
                loanID,
                address(this),
                amount,
                iscollateral,
                loanDataBytes
            )
        );
    }

    function getSwapAddress() public view returns (address) {
        return IBZx(protocol).swapsImpl();
    }

    function currentSwapRate(address start, address end)
        public
        view
        returns (uint256 executionPrice)
    {
        (executionPrice, ) = IPriceFeeds(getFeed()).queryRate(end, start);
    }

    function getFeed() public view returns (address) {
        return IBZx(protocol).priceFeeds();
    }

    function isActiveLoan(bytes32 ID) internal view returns (bool) {
        return IBZx(protocol).loans(ID).active;
    }

    function dexSwapRate(IOrderBook.OpenOrder memory order)
        public
        view
        returns (uint256)
    {
        uint256 tradeSize;
        (uint256 dexID, bytes memory payload) = abi.decode(
            order.loanDataBytes,
            (uint256, bytes)
        );
        if (order.orderType == IOrderBook.OrderType.LIMIT_OPEN) {
            if (order.loanTokenAmount > 0) {
                tradeSize = (order.loanTokenAmount * order.leverage) / 1 ether;
            } else {
                (tradeSize, ) = dexSwaps(
                    IDexRecords(getSwapAddress()).retrieveDexAddress(dexID)
                ).dexAmountOut(
                        dexID != 1
                            ? payload
                            : abi.encode(order.base, order.loanTokenAddress),
                        order.collateralTokenAmount
                    );
                if (tradeSize == 0) {
                    return 0;
                }
                tradeSize = (tradeSize * order.leverage) / 1 ether;
            }
        }
        (uint256 fSwapRate, ) = order.orderType ==
            IOrderBook.OrderType.LIMIT_OPEN
            ? dexSwaps(IDexRecords(getSwapAddress()).retrieveDexAddress(dexID))
                .dexAmountOut(
                    dexID != 1
                        ? payload
                        : abi.encode(order.loanTokenAddress, order.base),
                    tradeSize
                )
            : dexSwaps(IDexRecords(getSwapAddress()).retrieveDexAddress(dexID))
                .dexAmountOut(
                    dexID != 1
                        ? payload
                        : abi.encode(order.base, order.loanTokenAddress),
                    order.collateralTokenAmount
                );
        if (fSwapRate == 0) {
            return 0;
        }
        return
            order.orderType == IOrderBook.OrderType.LIMIT_OPEN
                ? (tradeSize.TenExp(
                    18 - int8(IERC20Metadata(order.loanTokenAddress).decimals())
                ) * 1 ether) /
                    (
                        fSwapRate.TenExp(
                            18 - int8(IERC20Metadata(order.base).decimals())
                        )
                    )
                : (1 ether *
                    (
                        fSwapRate.TenExp(
                            18 -
                                int8(
                                    IERC20Metadata(order.loanTokenAddress)
                                        .decimals()
                                )
                        )
                    )) /
                    (
                        order.collateralTokenAmount.TenExp(
                            18 - int8(IERC20Metadata(order.base).decimals())
                        )
                    );
    }

    function clearOrder(bytes32 orderID) public view returns (bool) {
        if (_orderExpiration[orderID] < block.timestamp) {
            return true;
        }
        uint256 swapRate = currentSwapRate(
            _allOrders[orderID].loanTokenAddress,
            _allOrders[orderID].base
        );
        if (
            (
                _allOrders[orderID].price > swapRate
                    ? (_allOrders[orderID].price - swapRate) >
                        (_allOrders[orderID].price * 25) / 100
                    : (swapRate - _allOrders[orderID].price) >
                        (swapRate * 25) / 100
            )
        ) {
            return true;
        }
        return false;
    }

    function prelimCheck(bytes32 orderID) public view returns (bool) {
		IOrderBook.OpenOrder memory order = _allOrders[orderID];
        address trader = order.trader;
        if (_orderExpiration[orderID] < block.timestamp) {
            return false;
        }
        if (
            order.orderType == IOrderBook.OrderType.LIMIT_OPEN
        ) {
            if (
                !(order.loanID == 0) &&
                !isActiveLoan(order.loanID)
            ) {
                return false;
            }
            uint256 dSwapValue = dexSwapRate(order);

            if (order.price >= dSwapValue && dSwapValue > 0) {
                return true;
            }
        } else if (
            order.orderType ==
            IOrderBook.OrderType.LIMIT_CLOSE
        ) {
            if (!isActiveLoan(order.loanID)) {
                return false;
            }
            if (
                order.price <=
                dexSwapRate(order)
            ) {
                return true;
            }
        } else {
            if (!isActiveLoan(order.loanID)) {
                return false;
            }
            if (
                _useOracle[trader]
                    ? order.price >=
                        currentSwapRate(
                            order.base,
                            order.loanTokenAddress
                        )
                    : order.price >=
                        currentDexRate(
                            order.base,
                            order.loanTokenAddress
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
        if (src == WRAPPED_TOKEN || dest == WRAPPED_TOKEN) {
            address pairAddress = UniswapFactory(UNI_FACTORY).getPair(
                src,
                dest
            );
            (uint112 reserve0, uint112 reserve1, ) = UniswapPair(pairAddress)
                .getReserves();
            uint256 res0 = uint256(reserve0);
            uint256 res1 = uint256(reserve1);
            dexRate = UniswapPair(pairAddress).token0() == src
                ? (
                    res0.TenExp(
                        18 -
                            int8(
                                IERC20Metadata(
                                    UniswapPair(pairAddress).token0()
                                ).decimals()
                            ) +
                            18
                    )
                ) /
                    (
                        res1.TenExp(
                            18 -
                                int8(
                                    IERC20Metadata(
                                        UniswapPair(pairAddress).token1()
                                    ).decimals()
                                )
                        )
                    )
                : ((
                    res1.TenExp(
                        18 -
                            int8(
                                IERC20Metadata(
                                    UniswapPair(pairAddress).token1()
                                ).decimals()
                            ) +
                            18
                    )
                ) / res0).TenExp(
                        18 -
                            int8(
                                IERC20Metadata(
                                    UniswapPair(pairAddress).token0()
                                ).decimals()
                            )
                    );
        } else {
            address pairAddress0 = UniswapFactory(UNI_FACTORY).getPair(
                src,
                WRAPPED_TOKEN
            );
            (uint112 reserve0, uint112 reserve1, ) = UniswapPair(pairAddress0)
                .getReserves();
            uint256 res0 = uint256(reserve0);
            uint256 res1 = uint256(reserve1);
            uint256 midSwapRate = UniswapPair(pairAddress0).token0() ==
                WRAPPED_TOKEN
                ? (
                    res1.TenExp(
                        18 -
                            int8(
                                IERC20Metadata(
                                    UniswapPair(pairAddress0).token1()
                                ).decimals()
                            ) +
                            18
                    )
                ) /
                    (
                        res0.TenExp(
                            18 -
                                int8(
                                    IERC20Metadata(
                                        UniswapPair(pairAddress0).token0()
                                    ).decimals()
                                )
                        )
                    )
                : (
                    res0.TenExp(
                        18 -
                            int8(
                                IERC20Metadata(
                                    UniswapPair(pairAddress0).token0()
                                ).decimals()
                            ) +
                            18
                    )
                ) /
                    (
                        res1.TenExp(
                            18 -
                                int8(
                                    IERC20Metadata(
                                        UniswapPair(pairAddress0).token0()
                                    ).decimals()
                                )
                        )
                    );
            address pairAddress1 = UniswapFactory(UNI_FACTORY).getPair(
                dest,
                WRAPPED_TOKEN
            );
            (uint112 reserve2, uint112 reserve3, ) = UniswapPair(pairAddress1)
                .getReserves();
            uint256 res2 = uint256(reserve2);
            uint256 res3 = uint256(reserve3);
            dexRate = UniswapPair(pairAddress1).token0() == WRAPPED_TOKEN
                ? ((10**36 /
                    ((
                        res3.TenExp(
                            18 -
                                int8(
                                    IERC20Metadata(
                                        UniswapPair(pairAddress1).token1()
                                    ).decimals()
                                ) +
                                18
                        )
                    ) /
                        (
                            res2.TenExp(
                                18 -
                                    int8(
                                        IERC20Metadata(
                                            UniswapPair(pairAddress1).token0()
                                        ).decimals()
                                    )
                            )
                        ))) * midSwapRate) / 10**18
                : ((10**36 /
                    ((
                        res2.TenExp(
                            18 -
                                int8(
                                    IERC20Metadata(
                                        UniswapPair(pairAddress1).token0()
                                    ).decimals()
                                ) +
                                18
                        )
                    ) /
                        (
                            res3.TenExp(
                                18 -
                                    int8(
                                        IERC20Metadata(
                                            UniswapPair(pairAddress1).token1()
                                        ).decimals()
                                    )
                            )
                        ))) * midSwapRate) / 10**18;
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

    function executeOrder(address payable keeper, bytes32 orderID) public {
        require(!_allOrders[orderID].isCancelled, "non active");
		IOrderBook.OpenOrder memory order = _allOrders[orderID];
        address trader = _allOrders[orderID].trader;
        if (
            _allOrders[orderID].orderType == IOrderBook.OrderType.LIMIT_OPEN
        ) {
            require(
                _allOrders[orderID].price >= dexSwapRate(_allOrders[orderID]),
                "invalid swap rate"
            );
            _executeTradeOpen(trader, orderID);
            _allOrders[orderID].isCancelled = true;
            _allOrderIDs.remove(orderID);
            _histOrders[trader].remove(orderID);
            emit OrderExecuted(trader, orderID);
            return;
        }
        if (
            order.orderType ==
            IOrderBook.OrderType.LIMIT_CLOSE
        ) {
            require(
                order.price <= dexSwapRate(_allOrders[orderID]),
                "invalid swap rate"
            );
            _executeTradeClose(
                trader,
                order.loanID,
                order.collateralTokenAmount,
                order.isCollateral,
                order.base,
                order.loanDataBytes
            );
            _allOrders[orderID].isCancelled = true;
            _allOrderIDs.remove(orderID);
            _histOrders[trader].remove(orderID);
            emit OrderExecuted(trader, orderID);
            return;
        }
        if (
            order.orderType ==
            IOrderBook.OrderType.MARKET_STOP
        ) {
            require(
                _useOracle[trader]
                    ? order.price >=
                        currentDexRate(
                            order.base,
                            order.loanTokenAddress
                        ) &&
                        priceCheck(
                            order.loanTokenAddress,
                            order.base
                        )
                    : order.price >=
                        currentDexRate(
                            order.base,
                            order.loanTokenAddress
                        ) &&
                        priceCheck(
                            order.loanTokenAddress,
                            order.base
                        ),
                "invalid swap rate"
            );
            _executeTradeClose(
                trader,
                order.loanID,
                order.collateralTokenAmount,
                order.isCollateral,
                order.base,
                order.loanDataBytes
            );
            _allOrders[orderID].isCancelled = true;
            _allOrderIDs.remove(orderID);
            _histOrders[trader].remove(orderID);
            emit OrderExecuted(trader, orderID);
            return;
        }
    }

    function setVaultAddress(address nVault) public onlyOwner {
        vault = nVault;
    }
}
