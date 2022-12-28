pragma solidity 0.5.17;
pragma experimental ABIEncoderV2;

import "../../core/State.sol";
import "@openzeppelin-2.5.0/token/ERC20/SafeERC20.sol";
import "../ISwapsImpl.sol";
import "../../interfaces/IBalancerVault.sol";

contract SwapsImplBalancer_POLYGON is State, ISwapsImpl {
    using SafeERC20 for IERC20;
    IBalancerVault public constant VAULT = IBalancerVault(0xBA12222222228d8Ba445958a75a0704d566BF2C8);

    function dexSwap(
        address sourceTokenAddress,
        address destTokenAddress,
        address receiverAddress,
        address returnToSenderAddress,
        uint256 minSourceTokenAmount,
        uint256 maxSourceTokenAmount,
        uint256 requiredDestTokenAmount,
        bytes memory payload
    )
        public
        returns (uint256 destTokenAmountReceived, uint256 sourceTokenAmountUsed)
    {
        require(sourceTokenAddress != destTokenAddress, "source == dest");
        require(
            supportedTokens[sourceTokenAddress] &&
            supportedTokens[destTokenAddress],
            "unsupported tokens"
        );

        IERC20 sourceToken = IERC20(sourceTokenAddress);
        address _thisAddress = address(this);
        (sourceTokenAmountUsed, destTokenAmountReceived) = _swap(
            sourceTokenAddress,
            destTokenAddress,
            receiverAddress,
            minSourceTokenAmount,
            maxSourceTokenAmount,
            requiredDestTokenAmount,
            payload
        );

        if (
            returnToSenderAddress != _thisAddress &&
            sourceTokenAmountUsed < maxSourceTokenAmount
        ) {
            // send unused source token back
            sourceToken.safeTransfer(
                returnToSenderAddress,
                maxSourceTokenAmount - sourceTokenAmountUsed
            );
        }
    }

    function dexExpectedRate(
        address sourceTokenAddress,
        address destTokenAddress,
        uint256 sourceTokenAmount
    ) public view returns (uint256 expectedRate) {
        revert("unsupported");
    }

    function dexAmountOut(bytes memory payload, uint256 amountIn)
        public
        returns (uint256 amountOut, address midToken)
    {
        (IBalancerVault.BatchSwapStep[] memory swapParams, address[] memory tokens) = abi.decode(payload, (IBalancerVault.BatchSwapStep[], address[]));
        uint256 amountInSpecified = 0;
        for (uint i; i < swapParams.length; ++i) {
            if (swapParams[i].assetInIndex == 0) {
                amountInSpecified = amountInSpecified.add(swapParams[i].amount);
            }
        }
        if (amountInSpecified > amountIn) {
            swapParams[0].amount = swapParams[0].amount.sub(amountInSpecified-amountIn);
        } else if (amountInSpecified < amountIn) {
            swapParams[0].amount += amountIn - amountInSpecified;
        }
        if (amountIn != 0) {
            IBalancerVault.FundManagement memory funds = IBalancerVault.FundManagement({
                sender: address(this),
                fromInternalBalance: false,
                recipient: address(uint160(address(this))),
                toInternalBalance: false
            });
            int256[] memory deltas = VAULT.queryBatchSwap(IBalancerVault.SwapKind.GIVEN_IN, swapParams, tokens, funds);
            amountOut = uint256(-deltas[deltas.length-1]);
        }
    }

    function dexAmountOutFormatted(bytes memory payload, uint256 amountIn)
        public
        returns (uint256 amountOut, address midToken)
    {
        return dexAmountOut(payload, amountIn);
    }

    function dexAmountIn(bytes memory route, uint256 amountOut)
        public
        returns (uint256 amountIn, address midToken)
    {
        (IBalancerVault.BatchSwapStep[] memory swapParams, address[] memory tokens) = abi.decode(route, (IBalancerVault.BatchSwapStep[], address[]));
        uint256 amountOutSpecified = 0;
        for (uint i; i < swapParams.length; ++i) {
            if (swapParams[i].assetOutIndex == swapParams.length-1) {
                amountOutSpecified = amountOutSpecified.add(swapParams[i].amount);
            }
        }
        if (amountOutSpecified > amountOut) {
            swapParams[0].amount = swapParams[0].amount.sub(amountOutSpecified -amountOut);
        } else if (amountOutSpecified < amountOut) {
            swapParams[0].amount += amountOut - amountOutSpecified;
        }
        if (amountOut != 0) {
            IBalancerVault.FundManagement memory funds = IBalancerVault.FundManagement({
                sender: address(this),
                fromInternalBalance: false,
                recipient: address(uint160(address(this))),
                toInternalBalance: false
            });
            int256[] memory deltas = VAULT.queryBatchSwap(IBalancerVault.SwapKind.GIVEN_OUT, swapParams, tokens, funds);
            amountIn = uint256(deltas[0]);
        }
    }

    function dexAmountInFormatted(bytes memory payload, uint256 amountOut)
        public
        returns (uint256 amountIn, address midToken)
    {
        return dexAmountIn(payload, amountOut);
    }

    function setSwapApprovals(
        address[] memory tokens
    ) public {
        for (uint i; i<tokens.length;++i) {
            IERC20(tokens[i]).safeApprove(address(VAULT), 0);
            IERC20(tokens[i]).safeApprove(address(VAULT), uint256(-1));
        }
    }

    function revokeApprovals(
        address[] memory tokens
    ) public {
        for (uint i; i<tokens.length;++i) {
            IERC20(tokens[i]).safeApprove(address(VAULT), 0);
        }
    }

    function _swap(
        address sourceTokenAddress,
        address destTokenAddress,
        address receiverAddress,
        uint256 minSourceTokenAmount,
        uint256 maxSourceTokenAmount,
        uint256 requiredDestTokenAmount,
        bytes memory payload
    )
        internal
        returns (uint256 sourceTokenAmountUsed, uint256 destTokenAmountReceived)
    {
        if (requiredDestTokenAmount == 0) {
            (IBalancerVault.BatchSwapStep[] memory swapParams, address[] memory tokens, int256[] memory limits) = abi.decode(payload, (IBalancerVault.BatchSwapStep[], address[], int256[]));
            require(tokens[0] == sourceTokenAddress && tokens[tokens.length-1] == destTokenAddress, "invalid tokens");
            limits[0] = int256(minSourceTokenAmount);
            maxSourceTokenAmount = 0;
            for (uint i; i < swapParams.length; ++i) {
                if (swapParams[i].assetInIndex != 0) {
                    require(swapParams[i].amount == 0, "invalid amount");
                } else {
                    maxSourceTokenAmount = maxSourceTokenAmount.add(swapParams[i].amount);
                }
            }
            if (maxSourceTokenAmount > minSourceTokenAmount) {
                swapParams[0].amount = swapParams[0].amount.sub(maxSourceTokenAmount-minSourceTokenAmount);
            } else if (maxSourceTokenAmount < minSourceTokenAmount) {
                swapParams[0].amount += minSourceTokenAmount - maxSourceTokenAmount;
            }
            IBalancerVault.FundManagement memory funds = IBalancerVault.FundManagement({
                sender: address(this),
                fromInternalBalance: false,
                recipient: address(uint160(receiverAddress)),
                toInternalBalance: false
            });

            limits = VAULT.batchSwap(
                IBalancerVault.SwapKind.GIVEN_IN,
                swapParams,
                tokens,
                funds,
                limits,
                block.timestamp);
            destTokenAmountReceived = uint256(-1*limits[limits.length-1]);
            require(uint256(limits[0]) == minSourceTokenAmount, "invalid inputs");
            sourceTokenAmountUsed = uint256(limits[0]);
        } else {

            (IBalancerVault.BatchSwapStep[] memory swapParams, address[] memory tokens, int256[] memory limits) = abi.decode(payload, (IBalancerVault.BatchSwapStep[], address[], int256[]));
            require(tokens[0] == sourceTokenAddress && tokens[tokens.length-1] == destTokenAddress, "invalid tokens");
            if (limits[0] > int256(maxSourceTokenAmount) || limits[0] == 0) {
                limits[0] = int256(maxSourceTokenAmount);
            }
            minSourceTokenAmount = 0;
            for (uint i; i < swapParams.length; ++i) {
                if (swapParams[i].assetOutIndex != tokens.length-1) {
                    require(swapParams[i].amount == 0, "invalid amount");
                } else {
                    minSourceTokenAmount = minSourceTokenAmount.add(swapParams[i].amount);
                }
            }
            if (requiredDestTokenAmount < minSourceTokenAmount) {
                swapParams[0].amount = swapParams[0].amount.sub(minSourceTokenAmount-requiredDestTokenAmount);
            } else if (requiredDestTokenAmount > minSourceTokenAmount) {
                swapParams[0].amount += requiredDestTokenAmount - minSourceTokenAmount;
            }
            IBalancerVault.FundManagement memory funds = IBalancerVault.FundManagement({
                sender: address(this),
                fromInternalBalance: false,
                recipient: address(uint160(receiverAddress)),
                toInternalBalance: false
            });

            limits = VAULT.batchSwap(
                IBalancerVault.SwapKind.GIVEN_OUT,
                swapParams,
                tokens,
                funds,
                limits,
                block.timestamp);
            destTokenAmountReceived = uint256(-limits[limits.length-1]);
            require(destTokenAmountReceived == requiredDestTokenAmount, "invalid inputs");
            sourceTokenAmountUsed = uint256(limits[0]);
        }
    }
}