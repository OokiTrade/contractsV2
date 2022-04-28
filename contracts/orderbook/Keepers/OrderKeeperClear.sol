pragma solidity ^0.8.0;
import "../IOrderBook.sol";
import "@openzeppelin-4.3.2/token/ERC20/extensions/IERC20Metadata.sol";
import "../../governance/PausableGuardian_0_8.sol";

contract OrderKeeperClear is PausableGuardian_0_8 {
    address public implementation;
    IOrderBook public orderBook;

    function checkUpkeep(bytes calldata checkData)
        external
        view
        returns (bool upkeepNeeded, bytes memory performData)
    {
        (uint256 start, uint256 end) = abi.decode(checkData, (uint256, uint256));
        uint256 orderIDLength = orderBook.getTotalOrderIDs();
        if (start > orderIDLength) {
            return (upkeepNeeded, performData);
        }
        if(end > orderIDLength) {
            end  = orderIDLength;
        }
        return orderBook.getClearOrderList(start, end);
    }

    function performUpkeep(bytes calldata performData) external pausable {
        bytes32[] memory orderId = abi.decode(performData, (bytes32[]));
        //emit OrderExecuted(trader,orderId);
        for (uint i;i<orderId.length;) {
            if(orderId[i]==0) {
                unchecked { ++i; }
                continue;
            }
            orderBook.cancelOrderProtocol(orderId[i]);
            unchecked { ++i; }
        }
    }

    function setOrderBook(IOrderBook contractAddress) external onlyOwner {
        orderBook = contractAddress;
    }
}
