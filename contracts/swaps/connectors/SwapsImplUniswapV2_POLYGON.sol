/**
 * Copyright 2017-2023, OokiDao. All Rights Reserved.
 * Licensed under the Apache License, Version 2.0.
 */

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

import "contracts/core/State.sol";
import "contracts/interfaces/uniswap/IUniswapV2Router.sol";
import "@openzeppelin-4.8.0/token/ERC20/utils/SafeERC20.sol";
import "interfaces/ISwapsImpl.sol";

contract SwapsImplUniswapV2_POLYGON is State, ISwapsImpl {
  using SafeERC20 for IERC20;

  address public constant uniswapRouter = 0x1b02dA8Cb0d097eB8D57A175b88c7D8b47997506; // Sushiswap
  //address public constant uniswapRouter = 0xa5E0829CaCEd8fFDD4De3c43696c57F7D7A678ff; // QuickSwap

  address public constant eth = 0x7ceB23fD6bC0adD59E62ac25578270cFf1b9f619;
  address public constant dai = 0x8f3Cf7ad23Cd3CaDbD9735AFf958023239c6A063;
  // address public constant USDC = 0x2791Bca1f2de4661ED88A30C99A7a9449Aa84174;
  address public constant usdt = 0xc2132D05D31c914a87C6611C10748AEb04B58e8F;

  constructor(
    IWeth wethtoken,
    address USDC,
    address ooki
  ) Constants(wethtoken, USDC, ooki) {}

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
      requiredDestTokenAmount
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

  function dexAmountOut(bytes memory payload, uint256 amountIn) public returns (uint256 amountOut, address midToken) {
    (address sourceTokenAddress, address destTokenAddress) = abi.decode(payload, (address, address));
    if (sourceTokenAddress == destTokenAddress) {
      amountOut = amountIn;
    } else if (amountIn != 0) {
      uint256 tmpValue;

      address[] memory path = new address[](2);
      path[0] = sourceTokenAddress;
      path[1] = destTokenAddress;
      amountOut = _getAmountOut(amountIn, path);

      path = new address[](3);
      path[0] = sourceTokenAddress;
      path[2] = destTokenAddress;

      if (sourceTokenAddress != address(wethToken) && destTokenAddress != address(wethToken)) {
        path[1] = address(wethToken);
        tmpValue = _getAmountOut(amountIn, path);
        if (tmpValue > amountOut) {
          amountOut = tmpValue;
          midToken = address(wethToken);
        }
      }

      if (sourceTokenAddress != eth && destTokenAddress != eth) {
        path[1] = eth;
        tmpValue = _getAmountOut(amountIn, path);
        if (tmpValue > amountOut) {
          amountOut = tmpValue;
          midToken = eth;
        }
      }

      if (sourceTokenAddress != dai && destTokenAddress != dai) {
        path[1] = dai;
        tmpValue = _getAmountOut(amountIn, path);
        if (tmpValue > amountOut) {
          amountOut = tmpValue;
          midToken = dai;
        }
      }

      if (sourceTokenAddress != USDC && destTokenAddress != USDC) {
        path[1] = USDC;
        tmpValue = _getAmountOut(amountIn, path);
        if (tmpValue > amountOut) {
          amountOut = tmpValue;
          midToken = USDC;
        }
      }

      if (sourceTokenAddress != usdt && destTokenAddress != usdt) {
        path[1] = usdt;
        tmpValue = _getAmountOut(amountIn, path);
        if (tmpValue > amountOut) {
          amountOut = tmpValue;
          midToken = usdt;
        }
      }
    }
  }

  function dexAmountOutFormatted(bytes memory payload, uint256 amountIn) public returns (uint256 amountOut, address midToken) {
    return dexAmountOut(payload, amountIn);
  }

  function dexAmountIn(bytes memory payload, uint256 amountOut) public returns (uint256 amountIn, address midToken) {
    (address sourceTokenAddress, address destTokenAddress) = abi.decode(payload, (address, address));
    if (sourceTokenAddress == destTokenAddress) {
      amountIn = amountOut;
    } else if (amountOut != 0) {
      uint256 tmpValue;

      address[] memory path = new address[](2);
      path[0] = sourceTokenAddress;
      path[1] = destTokenAddress;
      amountIn = _getAmountIn(amountOut, path);

      path = new address[](3);
      path[0] = sourceTokenAddress;
      path[2] = destTokenAddress;

      if (sourceTokenAddress != address(wethToken) && destTokenAddress != address(wethToken)) {
        path[1] = address(wethToken);
        tmpValue = _getAmountIn(amountOut, path);
        if (tmpValue < amountIn) {
          amountIn = tmpValue;
          midToken = address(wethToken);
        }
      }

      if (sourceTokenAddress != eth && destTokenAddress != eth) {
        path[1] = eth;
        tmpValue = _getAmountIn(amountOut, path);
        if (tmpValue < amountIn) {
          amountIn = tmpValue;
          midToken = eth;
        }
      }

      if (sourceTokenAddress != dai && destTokenAddress != dai) {
        path[1] = dai;
        tmpValue = _getAmountIn(amountOut, path);
        if (tmpValue < amountIn) {
          amountIn = tmpValue;
          midToken = dai;
        }
      }

      if (sourceTokenAddress != USDC && destTokenAddress != USDC) {
        path[1] = USDC;
        tmpValue = _getAmountIn(amountOut, path);
        if (tmpValue < amountIn) {
          amountIn = tmpValue;
          midToken = USDC;
        }
      }

      if (sourceTokenAddress != usdt && destTokenAddress != usdt) {
        path[1] = usdt;
        tmpValue = _getAmountIn(amountOut, path);
        if (tmpValue < amountIn) {
          amountIn = tmpValue;
          midToken = usdt;
        }
      }

      if (amountIn == type(uint256).max) {
        amountIn = 0;
      }
    }
  }

  function dexAmountInFormatted(bytes memory payload, uint256 amountOut) public returns (uint256 amountIn, address midToken) {
    return dexAmountIn(payload, amountOut);
  }

  function _getAmountOut(uint256 amountIn, address[] memory path) public view returns (uint256 amountOut) {
    (bool success, bytes memory data) = uniswapRouter.staticcall(
      abi.encodeWithSelector(
        0xd06ca61f, // keccak("getAmountsOut(uint256,address[])")
        amountIn,
        path
      )
    );
    if (success) {
      uint256 len = data.length;
      assembly {
        amountOut := mload(add(data, len)) // last amount value array
      }
    }
  }

  function _getAmountIn(uint256 amountOut, address[] memory path) public view returns (uint256 amountIn) {
    (bool success, bytes memory data) = uniswapRouter.staticcall(
      abi.encodeWithSelector(
        0x1f00ca74, // keccak("getAmountsIn(uint256,address[])")
        amountOut,
        path
      )
    );
    if (success) {
      uint256 len = data.length;
      assembly {
        amountIn := mload(add(data, 96)) // first amount value in array
      }
    }
    if (amountIn == 0) {
      amountIn = type(uint256).max;
    }
  }

  function setSwapApprovals(address[] memory tokens) public {
    for (uint256 i = 0; i < tokens.length; i++) {
      IERC20(tokens[i]).safeApprove(uniswapRouter, 0);
      IERC20(tokens[i]).safeApprove(uniswapRouter, type(uint256).max);
    }
  }

  function revokeApprovals(address[] memory tokens) public {
    for (uint256 i = 0; i < tokens.length; i++) {
      IERC20(tokens[i]).safeApprove(uniswapRouter, 0);
    }
  }

  function _swapWithUni(
    address sourceTokenAddress,
    address destTokenAddress,
    address receiverAddress,
    uint256 minSourceTokenAmount,
    uint256 maxSourceTokenAmount,
    uint256 requiredDestTokenAmount
  ) internal returns (uint256 sourceTokenAmountUsed, uint256 destTokenAmountReceived) {
    address midToken;
    if (requiredDestTokenAmount != 0) {
      (sourceTokenAmountUsed, midToken) = dexAmountIn(abi.encode(sourceTokenAddress, destTokenAddress), requiredDestTokenAmount);
      if (sourceTokenAmountUsed == 0) {
        return (0, 0);
      }
      require(sourceTokenAmountUsed <= maxSourceTokenAmount, "source amount too high");
    } else {
      sourceTokenAmountUsed = minSourceTokenAmount;
      (destTokenAmountReceived, midToken) = dexAmountOut(abi.encode(sourceTokenAddress, destTokenAddress), sourceTokenAmountUsed);
      if (destTokenAmountReceived == 0) {
        return (0, 0);
      }
    }

    address[] memory path;
    if (midToken != address(0)) {
      path = new address[](3);
      path[0] = sourceTokenAddress;
      path[1] = midToken;
      path[2] = destTokenAddress;
    } else {
      path = new address[](2);
      path[0] = sourceTokenAddress;
      path[1] = destTokenAddress;
    }

    uint256[] memory amounts = IUniswapV2Router(uniswapRouter).swapExactTokensForTokens(
      sourceTokenAmountUsed,
      1, // amountOutMin
      path,
      receiverAddress,
      block.timestamp
    );

    destTokenAmountReceived = amounts[amounts.length - 1];
  }
}
