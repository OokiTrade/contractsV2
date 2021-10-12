pragma solidity ^0.8.4;
import "@openzeppelin-4.3.2/access/Ownable.sol";
import "@openzeppelin-4.3.2/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin-4.3.2/token/ERC20/extensions/IERC20Metadata.sol";

contract Deposits is Ownable {
    mapping(address => mapping(uint256 => uint256)) storedBalance;
    mapping(address => mapping(uint256 => address)) correctTokenAddress;

    function deposit(
        uint256 orderID,
        uint256 TokenAmount,
        address trader,
        address token
    ) public {
        storedBalance[trader][orderID] += TokenAmount;
        correctTokenAddress[trader][orderID] = token;
        SafeERC20.safeTransferFrom(
            IERC20(token),
            msg.sender,
            address(this),
            TokenAmount
        );
    }

    function withdraw(address trader, uint256 orderID) public {
        SafeERC20.safeTransfer(
            IERC20(correctTokenAddress[trader][orderID]),
            msg.sender,
            storedBalance[trader][orderID]
        );
        storedBalance[trader][orderID] = 0;
    }

    function getDeposit(address trader, uint256 orderID)
        public
        view
        returns (uint256)
    {
        return storedBalance[trader][orderID];
    }

    function getTokenUsed(address trader, uint256 orderID)
        public
        view
        returns (address)
    {
        return correctTokenAddress[trader][orderID];
    }
}
