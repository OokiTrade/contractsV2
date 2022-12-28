/**
 * Copyright 2017-2021, bZeroX, LLC. All Rights Reserved.
 * Licensed under the Apache License, Version 2.0.
 */

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;
import "../../core/State.sol";
import "@openzeppelin-4.8.0/token/ERC20/utils/SafeERC20.sol";
import "../ISwapsImpl.sol";
import "../../interfaces/IUniswapV3SwapRouter.sol";
import "../../interfaces/IUniswapQuoter.sol";

contract SwapsImplUniswapV3_ETH is State, ISwapsImpl {
  using SafeERC20 for IERC20;
  IUniswapV3SwapRouter public constant uniswapSwapRouter = IUniswapV3SwapRouter(0xE592427A0AEce92De3Edee1F18E0157C05861564); //mainnet
  IUniswapQuoter public constant uniswapQuoteContract = IUniswapQuoter(0xb27308f9F90D607463bb33eA1BeBb41C27CE5AB6); //mainnet

  constructor(
    IWeth wethtoken,
    address usdc,
    address bzrx,
    address vbzrx,
    address ooki
  ) Constants(wethtoken, usdc, bzrx, vbzrx, ooki) {}

  function dexSwap(
    address sourceTokenAddress,
    address destTokenAddress,
    address receiverAddress,
    address returnToSenderAddress,
    uint256 minSourceTokenAmount,
    uint256 maxSourceTokenAmount,
    uint256 requiredDestTokenAmount,
    bytes memory payload
  ) public returns (uint256 destTokenAmountReceived, uint256 sourceTokenAmountUsed) {
    require(sourceTokenAddress != destTokenAddress, "source == dest");
    require(supportedTokens[sourceTokenAddress] && supportedTokens[destTokenAddress], "invalid tokens");

    IERC20 sourceToken = IERC20(sourceTokenAddress);
    address _thisAddress = address(this);
    (sourceTokenAmountUsed, destTokenAmountReceived) = _swapWithUni(
      sourceTokenAddress,
      destTokenAddress,
      receiverAddress,
      minSourceTokenAmount,
      maxSourceTokenAmount,
      requiredDestTokenAmount,
      payload
    );

    if (returnToSenderAddress != _thisAddress && sourceTokenAmountUsed < maxSourceTokenAmount) {
      // send unused source token back
      sourceToken.safeTransfer(returnToSenderAddress, maxSourceTokenAmount - sourceTokenAmountUsed);
    }
  }

  function dexExpectedRate(
    address sourceTokenAddress,
    address destTokenAddress,
    uint256 sourceTokenAmount
  ) public view returns (uint256 expectedRate) {
    revert("unsupported");
  }

  function dexAmountOut(bytes memory route, uint256 amountIn) public returns (uint256 amountOut, address midToken) {
    if (amountIn != 0) {
      amountOut = _getAmountOut(amountIn, route);
    }
  }

  function dexAmountOutFormatted(bytes memory payload, uint256 amountIn) public returns (uint256 amountOut, address midToken) {
    IUniswapV3SwapRouter.ExactInputParams[] memory exactParams = abi.decode(payload, (IUniswapV3SwapRouter.ExactInputParams[]));
    uint256 totalAmounts = 0;
    for (uint256 uniqueInputParam = 0; uniqueInputParam < exactParams.length; uniqueInputParam++) {
      totalAmounts += exactParams[uniqueInputParam].amountIn;
    }
    if (totalAmounts < amountIn) {
      exactParams[0].amountIn += amountIn - totalAmounts; //adds displacement to first swap set
    } else {
      return dexAmountOut(exactParams[0].path, amountIn); //this else intentionally ignores the other swap impls. It is specifically designed to avoid edge cases
    }
    uint256 tempAmountOut;
    for (uint256 i = 0; i < exactParams.length; i++) {
      (tempAmountOut, ) = dexAmountOut(exactParams[i].path, exactParams[i].amountIn);
      amountOut += tempAmountOut;
    }
  }

  function dexAmountIn(bytes memory route, uint256 amountOut) public returns (uint256 amountIn, address midToken) {
    if (amountOut != 0) {
      amountIn = _getAmountIn(amountOut, route);
    }
  }

  function dexAmountInFormatted(bytes memory payload, uint256 amountOut) public returns (uint256 amountIn, address midToken) {
    IUniswapV3SwapRouter.ExactOutputParams[] memory exactParams = abi.decode(payload, (IUniswapV3SwapRouter.ExactOutputParams[]));
    uint256 totalAmounts = 0;
    for (uint256 uniqueOutputParam = 0; uniqueOutputParam < exactParams.length; uniqueOutputParam++) {
      totalAmounts += exactParams[uniqueOutputParam].amountOut;
    }
    if (totalAmounts < amountOut) {
      exactParams[0].amountOut += amountOut - totalAmounts; //adds displacement to first swap set
    } else {
      return dexAmountIn(exactParams[0].path, amountOut); //this else intentionally ignores the other swap impls. It is specifically designed to avoid edge cases
    }
    uint256 tempAmountIn;
    for (uint256 i = 0; i < exactParams.length; i++) {
      (tempAmountIn, ) = dexAmountIn(exactParams[i].path, exactParams[i].amountOut);
      amountOut + tempAmountIn;
    }
  }

  function _getAmountOut(uint256 amountIn, bytes memory path) public returns (uint256) {
    return uniswapQuoteContract.quoteExactInput(path, amountIn);
  }

  function _getAmountIn(uint256 amountOut, bytes memory path) public returns (uint256) {
    return uniswapQuoteContract.quoteExactOutput(path, amountOut);
  }

  function setSwapApprovals(address[] memory tokens) public {
    for (uint256 i = 0; i < tokens.length; i++) {
      IERC20(tokens[i]).safeApprove(address(uniswapSwapRouter), 0);
      IERC20(tokens[i]).safeApprove(address(uniswapSwapRouter), type(uint256).max);
    }
  }

  function revokeApprovals(address[] memory tokens) public {
    for (uint256 i = 0; i < tokens.length; i++) {
      IERC20(tokens[i]).safeApprove(address(uniswapSwapRouter), 0);
    }
  }

  function _swapWithUni(
    address sourceTokenAddress,
    address destTokenAddress,
    address receiverAddress,
    uint256 minSourceTokenAmount,
    uint256 maxSourceTokenAmount,
    uint256 requiredDestTokenAmount,
    bytes memory payload
  ) internal returns (uint256 sourceTokenAmountUsed, uint256 destTokenAmountReceived) {
    if (requiredDestTokenAmount != 0) {
      IUniswapV3SwapRouter.ExactOutputParams[] memory exactParams = abi.decode(payload, (IUniswapV3SwapRouter.ExactOutputParams[]));
      bytes[] memory encodedTXs = new bytes[](exactParams.length);
      uint256 totalAmountsOut = 0;
      uint256 totalAmountsInMax = 0;
      for (uint256 uniqueOutputParam = 0; uniqueOutputParam < exactParams.length; uniqueOutputParam++) {
        exactParams[uniqueOutputParam].recipient = receiverAddress; //sets receiver to this protocol
        require(
          _toAddress(exactParams[uniqueOutputParam].path, 0) == destTokenAddress &&
            _toAddress(exactParams[uniqueOutputParam].path, exactParams[uniqueOutputParam].path.length - 20) == sourceTokenAddress,
          "improper route"
        );
        totalAmountsOut += exactParams[uniqueOutputParam].amountOut;
        totalAmountsInMax += exactParams[uniqueOutputParam].amountInMaximum;
        encodedTXs[uniqueOutputParam] = abi.encodeWithSelector(uniswapSwapRouter.exactOutput.selector, exactParams[uniqueOutputParam]);
      }
      require(totalAmountsInMax <= maxSourceTokenAmount, "Amount In Max too high");
      if (totalAmountsOut < requiredDestTokenAmount) {
        //does not need safe math as it cannot overflow
        uint256 displace = _numberAdjustment(totalAmountsOut, requiredDestTokenAmount);
        exactParams[0].amountOut += displace; //adds displacement to first swap set
        totalAmountsOut = requiredDestTokenAmount;
        encodedTXs[0] = abi.encodeWithSelector(uniswapSwapRouter.exactOutput.selector, exactParams[0]);
      }
      if (totalAmountsOut > requiredDestTokenAmount) {
        //does not need safe math as it cannot underflow
        uint256 displace = _numberAdjustment(totalAmountsOut, requiredDestTokenAmount);
        exactParams[0].amountOut -= displace; //adds displacement to first swap set
        totalAmountsOut = requiredDestTokenAmount;
        encodedTXs[0] = abi.encodeWithSelector(uniswapSwapRouter.exactOutput.selector, exactParams[0]);
      }
      uint256 balanceBefore = IERC20(sourceTokenAddress).balanceOf(address(this));
      uniswapSwapRouter.multicall(encodedTXs);
      sourceTokenAmountUsed = balanceBefore - IERC20(sourceTokenAddress).balanceOf(address(this));
      destTokenAmountReceived = requiredDestTokenAmount;
    } else {
      IUniswapV3SwapRouter.ExactInputParams[] memory exactParams = abi.decode(payload, (IUniswapV3SwapRouter.ExactInputParams[]));
      bytes[] memory encodedTXs = new bytes[](exactParams.length);
      for (uint256 uniqueInputParam = 0; uniqueInputParam < exactParams.length; uniqueInputParam++) {
        exactParams[uniqueInputParam].recipient = receiverAddress; //sets receiver to this protocol
        require(
          _toAddress(exactParams[uniqueInputParam].path, 0) == sourceTokenAddress &&
            _toAddress(exactParams[uniqueInputParam].path, exactParams[uniqueInputParam].path.length - 20) == destTokenAddress,
          "improper route"
        );
        sourceTokenAmountUsed += exactParams[uniqueInputParam].amountIn;
        encodedTXs[uniqueInputParam] = abi.encodeWithSelector(uniswapSwapRouter.exactInput.selector, exactParams[uniqueInputParam]);
      }
      if (sourceTokenAmountUsed < minSourceTokenAmount) {
        //does not need safe math as it cannot overflow
        uint256 displace = _numberAdjustment(sourceTokenAmountUsed, minSourceTokenAmount);
        exactParams[0].amountIn += displace;
        sourceTokenAmountUsed = minSourceTokenAmount;
        encodedTXs[0] = abi.encodeWithSelector(uniswapSwapRouter.exactInput.selector, exactParams[0]);
      }
      if (sourceTokenAmountUsed > minSourceTokenAmount) {
        uint256 displace = _numberAdjustment(sourceTokenAmountUsed, minSourceTokenAmount);
        exactParams[0].amountIn -= displace;
        sourceTokenAmountUsed = minSourceTokenAmount; //does not need safe math as it cannot underflow
        encodedTXs[0] = abi.encodeWithSelector(uniswapSwapRouter.exactInput.selector, exactParams[0]);
      }
      uint256 balanceBefore = IERC20(destTokenAddress).balanceOf(receiverAddress);
      uniswapSwapRouter.multicall(encodedTXs);
      destTokenAmountReceived = IERC20(destTokenAddress).balanceOf(receiverAddress) - balanceBefore;
    }
  }

  function _toAddress(bytes memory _bytes, uint256 _start) internal pure returns (address) {
    require(_start + 20 >= _start, "toAddress_overflow");
    require(_bytes.length >= _start + 20, "toAddress_outOfBounds");
    address tempAddress;

    assembly {
      tempAddress := div(mload(add(add(_bytes, 0x20), _start)), 0x1000000000000000000000000)
    }

    return tempAddress;
  }

  function _numberAdjustment(uint256 current, uint256 target) internal pure returns (uint256) {
    if (current > target) {
      return (current - target); //cannot overflow or underflow
    } else {
      return target - current;
    }
  }
}
