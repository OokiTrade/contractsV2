/**
 * Copyright 2017-2022, OokiDao. All Rights Reserved.
 * Licensed under the Apache License, Version 2.0.
 */

pragma solidity 0.5.17;

import "../../core/State.sol";
import "../../interfaces/ICurveSwaps.sol";
import "@openzeppelin-2.5.0/token/ERC20/SafeERC20.sol";
import "../ISwapsImpl.sol";


contract SwapsImplCurve_ETH is State, ISwapsImpl {
    using SafeERC20 for IERC20;

    // mainnet
    //address public constant uniswapRouter = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;   // uniswap
    ICurveProvider public constant curveAddressProvider =
        ICurveProvider(0x0000000022D53366457F9d5E68Ec105046FC4383); // curve registry
    address public constant dai = 0x6B175474E89094C44Da98b954EedeAC495271d0F;
    address public constant usdc = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
    address public constant usdt = 0xdAC17F958D2ee523a2206206994597C13D831ec7;

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
            "invalid tokens"
        );

        IERC20 sourceToken = IERC20(sourceTokenAddress);
        address _thisAddress = address(this);
		
        (sourceTokenAmountUsed, destTokenAmountReceived) = _swapWithCurve(
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

    function dexAmountOut(
        bytes memory payload,
        uint256 amountIn
    ) public returns (uint256 amountOut, address midToken) {
		(address pool, address sourceTokenAddress, address destTokenAddress) = abi.decode(payload,(address,address,address));
        if (sourceTokenAddress == destTokenAddress) {
            amountOut = amountIn;
        } else if (amountIn != 0) {
            amountOut = ICurveSwaps(curveAddressProvider.get_address(2)).get_exchange_amount(pool, sourceTokenAddress, destTokenAddress, amountIn);
        }
    }

    function dexAmountOutFormatted(
        bytes memory payload,
        uint256 amountIn)
        public
        returns (uint256 amountOut, address midToken)
    {
	    return dexAmountOut(payload, amountIn);
	}

    function dexAmountIn(
        bytes memory payload,
        uint256 amountOut
    ) public returns (uint256 amountIn, address midToken) {
		(address pool, address sourceTokenAddress, address destTokenAddress) = abi.decode(payload,(address,address,address));
        if (sourceTokenAddress == destTokenAddress) {
            amountIn = amountOut;
        } else if (amountOut != 0) {
            amountIn = ICurveSwaps(curveAddressProvider.get_address(2)).get_input_amount(pool, sourceTokenAddress, destTokenAddress, amountOut);
        }
    }

    function dexAmountInFormatted(
        bytes memory payload,
        uint256 amountOut)
        public
        returns (uint256 amountIn, address midToken)
    {
        return dexAmountIn(payload, amountOut);
	}

    function setSwapApprovals(address[] memory tokens) public {
        address curveRoute = curveAddressProvider.get_address(2);
        for (uint256 i = 0; i < tokens.length; i++) {
            IERC20(tokens[i]).safeApprove(curveRoute, 0);
            IERC20(tokens[i]).safeApprove(curveRoute, uint256(-1));
        }
    }

    function _swapWithCurve(
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
        (address pool, , , uint256 minAmount) = abi.decode(payload,(address,address,address, uint256));
        if (requiredDestTokenAmount != 0) {
            sourceTokenAmountUsed = maxSourceTokenAmount;
            if (sourceTokenAmountUsed == 0) {
                return (0, 0);
            }
            if(sourceTokenAmountUsed > minAmount) {
                sourceTokenAmountUsed = minAmount;
            }
            destTokenAmountReceived = ICurveSwaps(curveAddressProvider.get_address(2)).exchange(
                pool,
                sourceTokenAddress,
                destTokenAddress,
                sourceTokenAmountUsed,
                requiredDestTokenAmount,
                receiverAddress
            );
            if(destTokenAmountReceived > requiredDestTokenAmount){
                sourceTokenAmountUsed -= ICurveSwaps(curveAddressProvider.get_address(2)).exchange(
                    pool,
                    destTokenAddress,
                    sourceTokenAddress,
                    destTokenAmountReceived-requiredDestTokenAmount,
                    1,
                    receiverAddress
                );
                destTokenAmountReceived = requiredDestTokenAmount;
            }
        } else {
            sourceTokenAmountUsed = minSourceTokenAmount;
            destTokenAmountReceived = ICurveSwaps(curveAddressProvider.get_address(2)).exchange(
                pool,
                sourceTokenAddress,
                destTokenAddress,
                sourceTokenAmountUsed,
                minAmount,
                receiverAddress
            );
        }
    }
}
