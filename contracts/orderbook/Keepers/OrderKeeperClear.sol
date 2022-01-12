pragma solidity ^0.8.0;
import "./OrderBookInterface.sol";
import "./IUniswapV2Router.sol";
import "../WrappedToken.sol";
import "@openzeppelin-4.3.2/token/ERC20/extensions/IERC20Metadata.sol";

contract OrderKeeperClear {
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
            .getOrders();
        for (uint256 x = 0; x < listOfMainOrders.length; x++) {
            if (
                IOrderBook(factory).clearOrder(
                    listOfMainOrders[x].orderID
                )
            ) {
                upkeepNeeded = true;
                performData = abi.encode(
                    listOfMainOrders[x].orderID
                );
                return (upkeepNeeded, performData);
            }
        }
        return (upkeepNeeded, performData);
    }

    function performUpkeep(bytes calldata performData) public {
        (bytes32 orderId) = abi.decode(
            performData,
            (bytes32)
        );
        //emit OrderExecuted(trader,orderId);
        IOrderBook(factory).cancelOrderProtocol(orderId);
    }
}
