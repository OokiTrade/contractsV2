pragma solidity ^0.8.4;
import "./OrderBookInterface.sol";

contract KeeperManagement {
    address factory;

    constructor(address factoryAddress) {
        factory = factoryAddress;
    }

    function checkUpkeep(bytes calldata checkData)
        public
        view
        returns (bool upkeepNeeded, bytes memory performData)
    {
        IOrderBook.OpenOrder[] memory listOfMainOrders = IOrderBook(factory)
            .getOrders(0, IOrderBook(factory).getTotalActiveOrders());
        for (uint256 x = 0; x < listOfMainOrders.length; x++) {
            if (
                IOrderBook(factory).prelimCheck(
                    listOfMainOrders[x].trader,
                    listOfMainOrders[x].orderID
                ) == true
            ) {
                upkeepNeeded = true;
                performData = abi.encode(
                    listOfMainOrders[x].trader,
                    listOfMainOrders[x].orderID
                );
                return (upkeepNeeded, performData);
            }
        }
        return (upkeepNeeded, performData);
    }

    function performUpkeep(bytes calldata performData) public {
        (address trader, uint256 orderId) = abi.decode(
            performData,
            (address, uint256)
        );
        //emit OrderExecuted(trader,orderId);
        IOrderBook(factory).executeOrder(
            payable(address(this)),
            trader,
            orderId
        );
    }
}
