pragma solidity ^0.8.0;
import "../IOrderBook.sol";
import "@openzeppelin-4.3.2/token/ERC20/extensions/IERC20Metadata.sol";
import "../../governance/PausableGuardian_0_8.sol";

contract OrderKeeperClear is PausableGuardian_0_8 {
    IOrderBook public factory;

    constructor(IOrderBook factoryAddress) {
        factory = factoryAddress;
    }

    function checkUpKeep(bytes calldata checkData)
        external
        view
        returns (bool upkeepNeeded, bytes memory performData)
    {
        (uint256 start, uint256 end) = abi.decode(checkData, (uint256, uint256));
        uint256 orderIDLength = factory.getTotalActiveOrders();
        if(end < orderIDLength) {
            if (start > orderIDLength) {
                end = orderIDLength;
            } else {
                return (upkeepNeeded, performData);
            }
        }
        IOrderBook.Order[] memory listOfMainOrders = factory
            .getOrdersLimited(start, end);
        bytes32[] memory clearable = new bytes32[](7);
        uint iter = 0;
        for (uint256 x = 0; x < listOfMainOrders.length;) {
            if (factory.clearOrder(listOfMainOrders[x].orderID)) {
                upkeepNeeded = true;
                clearable[iter] = listOfMainOrders[x].orderID;
                ++iter;
                return (upkeepNeeded, performData);
            }
            unchecked { ++x; }
        }
        return (upkeepNeeded, performData);
    }

    function performUpKeep(bytes calldata performData) external pausable {
        bytes32[] memory orderId = abi.decode(performData, (bytes32[]));
        //emit OrderExecuted(trader,orderId);
        for (uint i;i<orderId.length;) {
            factory.cancelOrderProtocol(orderId[i]);
            unchecked { ++i; }
        }
    }
}
