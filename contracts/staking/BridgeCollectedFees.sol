pragma solidity ^0.8.0;

import "@openzeppelin-4.3.2/token/ERC20/IERC20.sol";
import "../proxies/0_8/Upgradeable_0_8.sol";

interface IHop {
    function swapAndSend(
        uint256 chainId,
        address recipient,
        uint256 amount,
        uint256 bonderFee,
        uint256 amountOutMin,
        uint256 deadline,
        uint256 destinationAmountOutMin,
        uint256 destinationDeadline
    ) external;
}

interface IHopExchange {
    function calculateSwap(
        uint8 tokenIndexFrom,
        uint8 tokenIndexTo,
        uint256 dx
    ) external returns (uint256);
}

contract BridgeCollectedFees is Upgradeable_0_8 {
    address public DestChainReceiver;
    address public HopExchange;
    IHop public Bridge;
    uint256 public DestChainID;
    IERC20 public constant USDC =
        IERC20(0x2791Bca1f2de4661ED88A30C99A7a9449Aa84174);
    uint256 public BonderFeePercent;
    uint256 public constant WEI_PERCENT_PRECISION = 1e20;
    uint256 public constant ONE_WEEK = 604800;
    uint256 public MaxFeeForBridge;
    uint256 public MaxSlippage;
    uint256 public minAmount;
    uint256 public MinBonderFee;
    event Bridged(address indexed sender, uint256 amount);

    function initialize(
        address exchange,
        IHop HopAddress,
        uint256 chainID,
        address receiver,
        uint256 bonderFee,
        uint256 maxSlippage,
        uint256 MaxFee,
        uint256 minBridge,
        uint256 minBondFee
    ) public onlyOwner {
        HopExchange = exchange;
        Bridge = HopAddress;
        DestChainReceiver = receiver;
        DestChainID = chainID;
        BonderFeePercent = bonderFee;
        MaxFeeForBridge = MaxFee;
        MaxSlippage = maxSlippage;
        minAmount = minBridge;
        MinBonderFee = minBondFee;
    }

    function setBonderFeePercent(uint256 amount) public onlyOwner {
        BonderFeePercent = amount;
    }

    function setMinBridgeAmount(uint256 amount) public onlyOwner {
        minAmount = amount;
    }

    function setMinBondFee(uint256 amount) public onlyOwner {
        MinBonderFee = amount;
    }

    function setApprovals(address spender, uint256 amount) public onlyOwner {
        USDC.approve(spender, 0);
        USDC.approve(spender, amount);
    }

    function bridgeUSDC() public {
        uint256 balance = USDC.balanceOf(address(this));
        require(balance >= minAmount, "balance too low for bridge");
        Bridge.swapAndSend(
            DestChainID, //destination chain
            DestChainReceiver, //receiver
            balance, //bridge amount
            (balance * BonderFeePercent) / WEI_PERCENT_PRECISION > MinBonderFee
                ? (balance * BonderFeePercent) / WEI_PERCENT_PRECISION
                : MinBonderFee, //MAX(minimmum bonder fee, 0.25% of bridge amount)
            balance - (balance * MaxSlippage) / WEI_PERCENT_PRECISION, //uses a defined max slippage for USDC to hUSDC
            block.timestamp,
            IHopExchange(HopExchange).calculateSwap(0, 1, balance) -
                MaxFeeForBridge, //MaxFeeForBridge >= bonder fee + tx cost on-chain
            block.timestamp + ONE_WEEK
        ); //1 week deadline for bridge
        emit Bridged(msg.sender, balance);
    }
}
