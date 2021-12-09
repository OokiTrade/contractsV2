pragma solidity ^0.8.4;
import "../Storage/OrderBookEvents.sol";
import "../Storage/OrderBookStorage.sol";

contract OrderBookData is OrderBookEvents, OrderBookStorage {
    function getRouter() public view returns (address) {
        return bZxRouterAddress;
    }

    function adjustAllowance(address spender, address token) public {
        require(
            IBZX(bZxRouterAddress).isLoanPool(spender) ||
                bZxRouterAddress == spender || vault == spender,
            "invalid spender"
        );
        IERC20Metadata(token).approve(spender, type(uint256).max);
    }

    function getActiveOrders(
        address smartWallet,
        uint256 start,
        uint256 count
    ) public view returns (IWalletFactory.OpenOrder[] memory fullList) {
        uint256[] memory idSet = OrderRecords.enums(
            HistOrders[smartWallet],
            start,
            count
        );

        fullList = new IWalletFactory.OpenOrder[](idSet.length);
        for (uint256 i = 0; i < idSet.length; i++) {
            fullList[i] = HistoricalOrders[smartWallet][idSet[i]];
        }
        return fullList;
    }

    function getOrderByOrderID(address smartWallet, uint256 orderID)
        public
        view
        returns (IWalletFactory.OpenOrder memory)
    {
        return HistoricalOrders[smartWallet][orderID];
    }

    function getActiveOrderIDs(
        address smartWallet,
        uint256 start,
        uint256 count
    ) public view returns (uint256[] memory) {
        return OrderRecords.enums(HistOrders[smartWallet], start, count);
    }

    function getTotalOrders(address smartWallet) public view returns (uint256) {
        return OrderRecords.length(HistOrders[smartWallet]);
    }

    function getTradersWithOrders(uint256 start, uint256 count)
        public
        view
        returns (address[] memory)
    {
        return ActiveTraders.enums(activeTraders, start, count);
    }

    function getTotalTradersWithOrders() public view returns (uint256) {
        return ActiveTraders.length(activeTraders);
    }

    function getTotalActiveOrders() public view returns (uint256) {
        return OrderRecords.length(AllOrderIDs);
    }

    function getOrders(uint256 start, uint256 count)
        public
        view
        returns (IWalletFactory.OpenOrder[] memory fullList)
    {
        uint256[] memory idSet = OrderRecords.enums(AllOrderIDs, start, count);

        fullList = new IWalletFactory.OpenOrder[](idSet.length);
        for (uint256 i = 0; i < idSet.length; i++) {
            fullList[i] = getOrderByOrderID(
                AllOrders[idSet[i]].trader,
                AllOrders[idSet[i]].orderID
            );
        }
        return fullList;
    }

    function getActiveTrades(address trader)
        public
        view
        returns (bytes32[] memory)
    {
        return
            OrderEntry.enums(
                ActiveTrades[trader],
                0,
                OrderEntry.length(ActiveTrades[trader])
            );
    }
}
