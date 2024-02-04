pragma solidity ^0.8.0;
import "../../governance/PausableGuardian_0_8.sol";
import "@openzeppelin-4.7.0/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin-4.7.0/token/ERC20/extensions/IERC20Metadata.sol";
import "../../interfaces/IWeth.sol";

contract Deposits is PausableGuardian_0_8 {
    struct DepositInfo {
        address depositToken;
        uint256 depositAmount;
    }
    mapping(bytes32 => DepositInfo) internal _depositInfo;
    address public constant WRAPPED_TOKEN = 0x0d500B1d8E8eF31E21C99d1Db9A6444d3ADf1270;
    address public orderBook = address(0);

    function deposit(
        bytes32 orderID,
        uint256 tokenAmount,
        address trader,
        address token
    ) external pausable {
        require(msg.sender == orderBook, "unauthorized");
        require(_depositInfo[orderID].depositToken == address(0)|| _depositInfo[orderID].depositToken == token,
            "Deposits: invalid token specified");
        _depositInfo[orderID].depositToken = token;
        _depositInfo[orderID].depositAmount += tokenAmount;
        SafeERC20.safeTransferFrom(
            IERC20(token),
            trader,
            address(this),
            tokenAmount
        );
    }

    function depositGasToken(address trader) external pausable payable {
        require(msg.sender == orderBook, "unauthorized");
        IWeth(WRAPPED_TOKEN).deposit{value:msg.value}();
        bytes32 orderID = keccak256(abi.encode(trader, 0));
        _depositInfo[orderID].depositToken = WRAPPED_TOKEN;
        _depositInfo[orderID].depositAmount += msg.value;
    }

    function setOrderBook(address n) external onlyOwner {
        orderBook = n;
    }

    function withdraw(bytes32 orderID) external pausable {
        require(msg.sender == orderBook, "unauthorized");
        SafeERC20.safeTransfer(
            IERC20(_depositInfo[orderID].depositToken),
            msg.sender,
            _depositInfo[orderID].depositAmount
        );
        _depositInfo[orderID].depositAmount = 0;
    }

    function withdrawToTrader(address trader, bytes32 orderID) external pausable {
        require(msg.sender == orderBook, "unauthorized");
        SafeERC20.safeTransfer(
            IERC20(_depositInfo[orderID].depositToken),
            trader,
            _depositInfo[orderID].depositAmount
        );
        _depositInfo[orderID].depositAmount = 0;
    }

    function refund(bytes32 orderID, uint256 amount) external pausable {
        require(msg.sender == orderBook, "unauthorized");
        SafeERC20.safeTransferFrom(
            IERC20(_depositInfo[orderID].depositToken),
            orderBook,
            address(this),
            amount
        );
        _depositInfo[orderID].depositAmount += amount;
    }

    function partialWithdraw(
        address trader,
        bytes32 orderID,
        uint256 amount
    ) external pausable {
        require(msg.sender == orderBook, "unauthorized");
        SafeERC20.safeTransfer(
            IERC20(_depositInfo[orderID].depositToken),
            trader,
            amount
        );
        _depositInfo[orderID].depositAmount -= amount;
    }

    function getDeposit(bytes32 orderID)
        external
        view
        returns (uint256)
    {
        return _depositInfo[orderID].depositAmount;
    }

    function getTokenUsed(bytes32 orderID)
        external
        view
        returns (address)
    {
        return _depositInfo[orderID].depositToken;
    }
}
