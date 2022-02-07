pragma solidity ^0.8.0;

import "@openzeppelin-4.3.2/token/ERC20/IERC20.sol";
import "../../interfaces/IStaking.sol";
import "../proxies/0_8/Upgradeable_0_8.sol";

interface I3Pool {
    function add_liquidity(uint256[3] memory amounts, uint256 min_mint_amount)
        external;
		
	function get_virtual_price() external view returns(uint256);
}

contract ConvertAndAdminister is Upgradeable_0_8 {
    address public constant crv3 = 0x6c3F90f043a72FA612cbac8115EE7e52BDe6E490;
    address public constant pool3 = 0xbEbc44782C7dB0a1A60Cb6fe97d0b483032FF1C7;
    IERC20 public constant USDC =
        IERC20(0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48);
    address public constant STAKING = 0x16f179f5C344cc29672A58Ea327A26F64B941a63; //set to staking contract
	address public constant TREASURY = 0xfedC4dD5247B93feb41e899A09C44cFaBec29Cbc;
    event Distributed(address indexed sender, uint256 treasury, uint256 stakers);

    bool public isPaused;

    modifier checkPause() {
        require(!isPaused || msg.sender == owner(), "paused");
        _;
    }

    function distributeFees() external checkPause {
        _convertTo3Crv();
		uint256 total = IERC20(crv3).balanceOf(address(this));
		uint256 toTreasury = total*1000/3500;
		IERC20(crv3).transfer(TREASURY,toTreasury); //20% goes to treasury and the amount sent here is 70%. Formula is 0.7/0.7/0.5 = 0.2
		uint256 toStakers = IERC20(crv3).balanceOf(address(this));
        _addRewards(toStakers);
        emit Distributed(msg.sender, toTreasury, toStakers);
    }

    //internal functions

    function _convertTo3Crv() internal returns(uint256 amountUsed) {
		amountUsed = USDC.balanceOf(address(this));
		uint256 min_amount = (amountUsed*1e12*1e18/I3Pool(pool3).get_virtual_price())*995/1000; //0.5% slippage on minting
        I3Pool(pool3).add_liquidity([0, amountUsed, 0], min_amount);
    }

    function _addRewards(uint256 amount) internal {
        IStaking(STAKING).addRewards(0, amount);
    }

    //Owner functions

    function setApprovals(
        address token,
        address spender,
        uint256 amount
    ) external onlyOwner {
        IERC20(token).approve(spender, 0);
        IERC20(token).approve(spender, amount);
    }

    function togglePause(bool _isPaused) external onlyOwner {
        isPaused = _isPaused;
    }
}
