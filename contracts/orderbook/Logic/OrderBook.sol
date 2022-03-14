pragma solidity ^0.8.0;
import "../Storage/OrderBookEvents.sol";
import "../Storage/OrderBookStorage.sol";
import "../../swaps/ISwapsImpl.sol";
import "../OrderVault/IDeposits.sol";
import "../../interfaces/IDexRecords.sol";
import "../../mixins/Flags.sol";
contract OrderBook is OrderBookEvents, OrderBookStorage, Flags {
    using EnumerableSet for EnumerableSet.Bytes32Set;

    function initialize(address target) public onlyOwner {
        _setTarget(this.getSwapAddress.selector, target);
        _setTarget(this.getFeed.selector, target);
        _setTarget(this.getDexRate.selector, target);
        _setTarget(this.clearOrder.selector, target);
        _setTarget(this.prelimCheck.selector, target);
        _setTarget(this.queryRateReturn.selector, target);
        _setTarget(this.priceCheck.selector, target);
        _setTarget(this.executeOrder.selector, target);
        _setTarget(this.setVaultAddress.selector, target);
    }

    function _executeTradeOpen(
        IOrderBook.Order memory internalOrder
    ) internal {
        IDeposits(vault).withdraw(internalOrder.orderID);
        (bool result, bytes memory data) = internalOrder.iToken.call(
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
        if (result && internalOrder.loanID==0) {
            (bytes32 loanID) = abi.decode(
                data,
                (bytes32)
            );
            _activeTrades[internalOrder.trader].add(loanID);
        } else if (!result) {
            IDeposits(vault).refund(internalOrder.orderID, (internalOrder.loanTokenAmount + internalOrder.collateralTokenAmount)); //unlikely to be needed
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
        if (protocol.getLoan(loanID).collateral == amount) {
            _activeTrades[trader].remove(loanID);
        }
        address(protocol).call(
            abi.encodeWithSelector(
                protocol.closeWithSwap.selector,
                loanID,
                address(this),
                amount,
                iscollateral,
                loanDataBytes
            )
        );
    }

    function getSwapAddress() public view returns (address) {
        return protocol.swapsImpl();
    }

    function getFeed() public view returns (address) {
        return protocol.priceFeeds();
    }

    function _isActiveLoan(bytes32 ID) internal view returns (bool) {
        return protocol.loans(ID).active;
    }

    function clearOrder(bytes32 orderID) public view pausable returns (bool) {
        if (_allOrders[orderID].timeTillExpiration < block.timestamp) {
            return true;
        }
        uint256 amountUsed = _allOrders[orderID].collateralTokenAmount +
            _allOrders[orderID].loanTokenAmount;
        uint256 swapRate;
        if (_allOrders[orderID].orderType == IOrderBook.OrderType.LIMIT_OPEN) {
            swapRate = queryRateReturn(
                _allOrders[orderID].loanTokenAddress,
                _allOrders[orderID].base,
                amountUsed
            );
        } else {
            swapRate = queryRateReturn(
                _allOrders[orderID].base,
                _allOrders[orderID].loanTokenAddress,
                amountUsed
            );
        }
        if (
            (
                _allOrders[orderID].amountReceived > swapRate
                    ? (_allOrders[orderID].amountReceived - swapRate) >
                        (_allOrders[orderID].amountReceived * 25) / 100
                    : (swapRate - _allOrders[orderID].amountReceived) >
                        (swapRate * 25) / 100
            )
        ) {
            return true;
        }
        return false;
    }

    function queryRateReturn(
        address start,
        address end,
        uint256 amount
    ) public view returns (uint256) {
        (uint256 executionPrice, uint256 precision) = IPriceFeeds(getFeed())
            .queryRate(start, end);
        return (executionPrice * amount) / precision;
    }

    function _prepDexAndPayload(bytes memory input)
        internal
        pure
        returns (uint256 dexID, bytes memory payload)
    {
        if (input.length != 0) {
            (uint128 flag, bytes[] memory payloads) = abi.decode(
                input,
                (uint128, bytes[])
            );
            if(flag & DEX_SELECTOR_FLAG != 0){
                (dexID, payload) = abi.decode(payloads[0], (uint256, bytes));
            }
        }
    }

    function prelimCheck(bytes32 orderID) external returns (bool) {
        IOrderBook.Order memory order = _allOrders[orderID];
        uint256 amountUsed;
        address srcToken;
        (uint256 dexID, bytes memory payload) = _prepDexAndPayload(order.loanDataBytes);
        if (payload.length == 0) {
            if (order.orderType == IOrderBook.OrderType.LIMIT_OPEN) {
                payload = abi.encode(order.loanTokenAddress, order.base);
            } else {
                payload = abi.encode(order.base, order.loanTokenAddress);
            }
            dexID = 1;
        }
        ISwapsImpl swapImpl = ISwapsImpl(
            IDexRecords(getSwapAddress()).retrieveDexAddress(dexID)
        );
        srcToken = order.collateralTokenAmount > order.loanTokenAmount ? order.base : order.loanTokenAddress;
        if (order.timeTillExpiration < block.timestamp) {
            return false;
        }
        if (order.orderType == IOrderBook.OrderType.LIMIT_OPEN) {
            if (order.loanID != 0 && !_isActiveLoan(order.loanID)) {
                return false;
            }
            uint256 dSwapValue;
            if (srcToken == order.loanTokenAddress) {
                amountUsed = order.loanTokenAmount + (order.loanTokenAmount * order.leverage) / 10**18; //adjusts leverage
                (dSwapValue, ) = swapImpl.dexAmountOutFormatted(
                    payload,
                    amountUsed
                );
            } else {
                amountUsed = queryRateReturn(
                    order.base,
                    order.loanTokenAddress,
                    order.collateralTokenAmount
                );
                amountUsed = (amountUsed * order.leverage) / 10**18;
                (dSwapValue, ) = swapImpl.dexAmountOutFormatted(
                    payload,
                    amountUsed
                );
                dSwapValue += order.collateralTokenAmount;
            }


            if (order.amountReceived <= dSwapValue) {
                return true;
            }
        } else if (order.orderType == IOrderBook.OrderType.LIMIT_CLOSE) {
            if (!_isActiveLoan(order.loanID)) {
                return false;
            }
            uint256 dSwapValue;
            if (order.isCollateral) {
                (dSwapValue, ) = swapImpl.dexAmountInFormatted(
                    payload,
                    order.collateralTokenAmount
                );
            } else {
                (dSwapValue, ) = swapImpl.dexAmountOutFormatted(
                    payload,
                    order.collateralTokenAmount
                );
            }
            if (order.amountReceived <= dSwapValue) {
                return true;
            }
        } else {
            if (!_isActiveLoan(order.loanID)) {
                return false;
            }
            bool operand;
            if (_useOracle[order.trader]) {
                operand =
                    order.amountReceived >=
                    queryRateReturn(
                        order.base,
                        order.loanTokenAddress,
                        order.collateralTokenAmount
                    );
            } else {
                operand =
                    order.amountReceived >=
                    getDexRate(
                        swapImpl,
                        order.base,
                        order.loanTokenAddress,
                        payload,
                        order.collateralTokenAmount
                    );
            }
            if (operand) {
                return true;
            }
        }
        return false;
    }

    function getDexRate(
        ISwapsImpl swapImpl,
        address base,
        address loanTokenAddress,
        bytes memory payload,
        uint256 amountIn
    ) public returns (uint256 rate) {
        (rate, ) = swapImpl.dexAmountOutFormatted(
            payload,
            10**IERC20Metadata(base).decimals()
        );
        rate = (rate * amountIn) / 10**IERC20Metadata(base).decimals();
    }

    function priceCheck(
        address loanTokenAddress,
        address base,
        ISwapsImpl swapImpl,
        bytes memory payload
    ) public returns (bool) {
        uint256 dexRate = getDexRate(
            swapImpl,
            base,
            loanTokenAddress,
            payload,
            10**IERC20Metadata(base).decimals()
        );
        uint256 indexRate = queryRateReturn(
            base,
            loanTokenAddress,
            10**IERC20Metadata(base).decimals()
        );
        if (dexRate >= indexRate) {
            if (((dexRate - indexRate) * 1000) / dexRate <= 5) {
                return true;
            } else {
                return false;
            }
        } else {
            if (((indexRate - dexRate) * 1000) / indexRate <= 5) {
                return true;
            } else {
                return false;
            }
        }
    }

    function executeOrder(bytes32 orderID) external pausable {
        require(!_allOrders[orderID].isCancelled, "OrderBook: non active");
        IOrderBook.Order memory order = _allOrders[orderID];
        address srcToken;
        uint256 amountUsed;
        (uint256 dexID, bytes memory payload) = _prepDexAndPayload(order.loanDataBytes);
        if (payload.length == 0) {
            if (order.orderType == IOrderBook.OrderType.LIMIT_OPEN) {
                payload = abi.encode(order.loanTokenAddress, order.base);
            } else {
                payload = abi.encode(order.base, order.loanTokenAddress);
            }
            dexID = 1;
        }
        ISwapsImpl swapImpl = ISwapsImpl(
            IDexRecords(getSwapAddress()).retrieveDexAddress(dexID)
        );
        srcToken = order.collateralTokenAmount > order.loanTokenAmount ? order.base : order.loanTokenAddress;
        require(order.timeTillExpiration > block.timestamp, "OrderBook: Order Expired");
        if (_allOrders[orderID].orderType == IOrderBook.OrderType.LIMIT_OPEN) {
            uint256 dSwapValue;
            if (srcToken == order.loanTokenAddress) {
                amountUsed = order.loanTokenAmount + (order.loanTokenAmount * order.leverage) / 10**18; //adjusts leverage
                (dSwapValue, ) = swapImpl.dexAmountOutFormatted(
                    payload,
                    amountUsed
                );
            } else {
                amountUsed = queryRateReturn(
                    order.base,
                    order.loanTokenAddress,
                    order.collateralTokenAmount
                );
                amountUsed = (amountUsed * order.leverage) / 10**18;
                (dSwapValue, ) = swapImpl.dexAmountOutFormatted(
                    payload,
                    amountUsed
                );
                dSwapValue += order.collateralTokenAmount;
            }

            require(
                order.amountReceived <= dSwapValue,
                "OrderBook: amountOut too low"
            );
            _executeTradeOpen(order);
            _allOrders[orderID].isCancelled = true;
            _allOrderIDs.remove(orderID);
            _histOrders[order.trader].remove(orderID);
            emit OrderExecuted(order.trader, orderID);
            return;
        }
        if (order.orderType == IOrderBook.OrderType.LIMIT_CLOSE) {
            uint256 dSwapValue;
            if (order.isCollateral) {
                (dSwapValue, ) = swapImpl.dexAmountInFormatted(
                    payload,
                    order.collateralTokenAmount
                );
                require(order.amountReceived <= dSwapValue, "OrderBook: amountIn too low");
            } else {
                (dSwapValue, ) = swapImpl.dexAmountOutFormatted(
                    payload,
                    order.collateralTokenAmount
                );
                require(order.amountReceived <= dSwapValue, "OrderBook: amountOut too low");
            }
            _executeTradeClose(
                order.trader,
                order.loanID,
                order.collateralTokenAmount,
                order.isCollateral,
                order.base,
                order.loanDataBytes
            );
            _allOrders[orderID].isCancelled = true;
            _allOrderIDs.remove(orderID);
            _histOrders[order.trader].remove(orderID);
            emit OrderExecuted(order.trader, orderID);
            return;
        }
        if (order.orderType == IOrderBook.OrderType.MARKET_STOP) {
            bool operand;
            if (_useOracle[order.trader]) {
                operand =
                    order.amountReceived >=
                    queryRateReturn(
                        order.base,
                        order.loanTokenAddress,
                        order.collateralTokenAmount
                    ); //TODO: Adjust for precision
            } else {
                operand =
                    order.amountReceived >=
                    getDexRate(
                        swapImpl,
                        order.base,
                        order.loanTokenAddress,
                        payload,
                        order.collateralTokenAmount
                    );
            }
            require(
                operand &&
                    priceCheck(
                        order.loanTokenAddress,
                        order.base,
                        swapImpl,
                        payload
                    ),
                "OrderBook: invalid swap rate"
            );
            _executeTradeClose(
                order.trader,
                order.loanID,
                order.collateralTokenAmount,
                order.isCollateral,
                order.base,
                order.loanDataBytes
            );
            _allOrders[orderID].isCancelled = true;
            _allOrderIDs.remove(orderID);
            _histOrders[order.trader].remove(orderID);
            emit OrderExecuted(order.trader, orderID);
            return;
        }
    }

    function setVaultAddress(address nVault) external onlyOwner {
        vault = nVault;
    }
}
