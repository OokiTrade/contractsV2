pragma solidity ^0.8.0;

import "@openzeppelin-4.3.2/token/ERC20/IERC20.sol";
import "../../interfaces/IStaking.sol";
import "../proxies/0_8/Upgradeable_0_8.sol";
import "@celer/contracts/interfaces/IBridge.sol";
import "@celer/contracts/interfaces/IOriginalTokenVault.sol";
import "@celer/contracts/interfaces/IPeggedTokenBridge.sol";
import "@celer/contracts/message/interfaces/IMessageReceiverApp.sol";

interface I3Pool {
    function add_liquidity(uint256[3] memory amounts, uint256 min_mint_amount)
        external;
}

contract ConvertAndAdminister is Upgradeable_0_8 {
    modifier onlyMessageBus() {
        require(msg.sender == messageBus, "caller is not message bus");
        _;
    }
	address public messageBus;
    address public constant crv3 = 0x6c3F90f043a72FA612cbac8115EE7e52BDe6E490;
    address public constant pool3 = 0xbEbc44782C7dB0a1A60Cb6fe97d0b483032FF1C7;
    IERC20 public constant USDC =
        IERC20(0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48);
    address public constant Staking = address(0); //set to staking contract
    event Distributed(address indexed sender, uint256 amount);

    function distributeFees() public {
        _convertTo3Crv();
        _addRewards(IERC20(crv3).balanceOf(address(this)));
        emit Distributed(msg.sender, IERC20(crv3).balanceOf(address(this)));
    }

    function executeMessageWithTransfer(
        address,
        address,
        uint256,
        uint64,
        bytes
    ) external payable virtual override onlyMessageBus returns (bool) {address(this).call(distributeFees.selector);}

    //internal functions

    function _convertTo3Crv() internal {
        I3Pool(pool3).add_liquidity([0, USDC.balanceOf(address(this)), 0], 0);
    }

    function _addRewards(uint256 amount) internal {
        IStaking(Staking).addRewards(0, amount);
    }

    //Owner functions

    function updateSettings(
        address _liquidityBridge,
        address _pegBridge,
        address _pegVault
    ) public onlyOwner {
        liquidityBridge = _liquidityBridge;
        pegBridge = _pegBridge;
        pegVault = _pegVault;
    }

    function setApprovals(
        address token,
        address spender,
        uint256 amount
    ) public onlyOwner {
        IERC20(token).approve(spender, 0);
        IERC20(token).approve(spender, amount);
    }

    function setMessageBus(address _messageBus) public onlyOwner {
	    messageBus = _messageBus;
	}
}
