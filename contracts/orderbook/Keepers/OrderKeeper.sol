pragma solidity ^0.8.0;
import "../IOrderBook.sol";
import "@openzeppelin-4.3.2/token/ERC20/extensions/IERC20Metadata.sol";
import "../../governance/PausableGuardian_0_8.sol";

contract OrderKeeper is PausableGuardian_0_8 {
    address public implementation;
    IERC20Metadata public constant WRAPPED_TOKEN = IERC20Metadata(0x0d500B1d8E8eF31E21C99d1Db9A6444d3ADf1270);
    IOrderBook public orderBook;

    function checkUpkeep(bytes calldata checkData)
        external
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
        bytes32 orderIDForExec = orderBook
            .getExecuteOrder(start, end);
        return (orderIDForExec != 0, abi.encode(orderIDForExec));
    }

    function performUpkeep(bytes calldata performData) external pausable {
        bytes32 orderId = abi.decode(performData, (bytes32));
        //emit OrderExecuted(trader,orderId);
        try orderBook.executeOrder(orderId) {

        } catch(bytes memory){} catch Error (string memory) {}
    }

    function setOrderBook(IOrderBook contractAddress) external onlyOwner {
        orderBook = contractAddress;
    }

    function withdrawIncentivesReceived(address receiver) external onlyOwner {
        WRAPPED_TOKEN.transfer(receiver, WRAPPED_TOKEN.balanceOf(address(this)));
    }
}
