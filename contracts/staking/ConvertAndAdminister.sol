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
    struct TransferInfo {
        TransferType t;
        address sender;
        address receiver;
        address token;
        uint256 amount;
        uint64 seqnum; // only needed for LqWithdraw
        uint64 srcChainId;
        bytes32 refId;
    }

    enum TxStatus {
        Null,
        Success,
        Fail,
        Fallback
    }

    enum TransferType {
        Null,
        LqSend, // send through liquidity bridge
        LqWithdraw, // withdraw from liquidity bridge
        PegMint, // mint through pegged token bridge
        PegWithdraw // withdraw from original token vault
    }

    enum MsgType {
        MessageWithTransfer,
        MessageOnly
    }
    event Executed(MsgType msgType, bytes32 id, TxStatus status);

    address public constant crv3 = 0x6c3F90f043a72FA612cbac8115EE7e52BDe6E490;
    address public constant pool3 = 0xbEbc44782C7dB0a1A60Cb6fe97d0b483032FF1C7;
    IERC20 public constant USDC =
        IERC20(0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48);
    address public constant Staking = address(0); //set to staking contract
    event Distributed(address indexed sender, uint256 amount);

    mapping(bytes32 => TxStatus) public executedMessages;

    address public liquidityBridge; // liquidity bridge address
    address public pegBridge; // peg bridge address
    address public pegVault; // peg original vault address

    function distributeFees() public {
        _convertTo3Crv();
        _addRewards(IERC20(crv3).balanceOf(address(this)));
        emit Distributed(msg.sender, IERC20(crv3).balanceOf(address(this)));
    }

    //Message Handling

    function executeMessageWithTransfer(
        bytes calldata _message,
        TransferInfo calldata _transfer,
        bytes[] calldata _sigs,
        address[] calldata _signers,
        uint256[] calldata _powers
    ) external payable {
        // For message with token transfer, message Id is computed through transfer info
        // in order to guarantee that each transfer can only be used once.
        // This also indicates that different transfers can carry the exact same messages.
        bytes32 messageId = verifyTransfer(_transfer);
        require(
            executedMessages[messageId] == TxStatus.Null,
            "transfer already executed"
        );

        bytes32 domain = keccak256(
            abi.encodePacked(
                block.chainid,
                address(this),
                "MessageWithTransfer"
            )
        );
        IBridge(liquidityBridge).verifySigs(
            abi.encodePacked(domain, messageId, _message),
            _sigs,
            _signers,
            _powers
        );
        TxStatus status;
        bool success = executeMessageWithTransfer(_transfer, _message);
        if (success) {
            status = TxStatus.Success;
        } else {
            status = TxStatus.Fail;
        }
        executedMessages[messageId] = status;
        emit Executed(MsgType.MessageWithTransfer, messageId, status);
    }

    function executeMessageWithTransfer(
        TransferInfo calldata _transfer,
        bytes calldata _message
    ) private returns (bool) {
        if (_transfer.receiver == address(this)) {
            return false;
        }
        (bool ok, bytes memory res) = address(_transfer.receiver).call(
            "0xbb57ad20" //distributeFees().selector
        );
        if (ok) {
            bool success = abi.decode((res), (bool));
            return success;
        }
        return false;
    }

    function verifyTransfer(TransferInfo calldata _transfer)
        private
        view
        returns (bytes32)
    {
        bytes32 transferId;
        address bridgeAddr;
        if (_transfer.t == TransferType.LqSend) {
            transferId = keccak256(
                abi.encodePacked(
                    _transfer.sender,
                    _transfer.receiver,
                    _transfer.token,
                    _transfer.amount,
                    _transfer.srcChainId,
                    uint64(block.chainid),
                    _transfer.refId
                )
            );
            bridgeAddr = liquidityBridge;
            require(
                IBridge(bridgeAddr).transfers(transferId) == true,
                "bridge relay not exist"
            );
        } else if (_transfer.t == TransferType.LqWithdraw) {
            transferId = keccak256(
                abi.encodePacked(
                    uint64(block.chainid),
                    _transfer.seqnum,
                    _transfer.receiver,
                    _transfer.token,
                    _transfer.amount
                )
            );
            bridgeAddr = liquidityBridge;
            require(
                IBridge(bridgeAddr).withdraws(transferId) == true,
                "bridge withdraw not exist"
            );
        } else if (
            _transfer.t == TransferType.PegMint ||
            _transfer.t == TransferType.PegWithdraw
        ) {
            transferId = keccak256(
                abi.encodePacked(
                    _transfer.receiver,
                    _transfer.token,
                    _transfer.amount,
                    _transfer.sender,
                    _transfer.srcChainId,
                    _transfer.refId
                )
            );
            if (_transfer.t == TransferType.PegMint) {
                bridgeAddr = pegBridge;
                require(
                    IPeggedTokenBridge(bridgeAddr).records(transferId) == true,
                    "mint record not exist"
                );
            } else {
                // _transfer.t == TransferType.PegWithdraw
                bridgeAddr = pegVault;
                require(
                    IOriginalTokenVault(bridgeAddr).records(transferId) == true,
                    "withdraw record not exist"
                );
            }
        }
        return
            keccak256(
                abi.encodePacked(
                    MsgType.MessageWithTransfer,
                    bridgeAddr,
                    transferId
                )
            );
    }

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
}
