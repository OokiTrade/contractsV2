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

contract SwapsImplUniswapV2 is State, ISwapsImpl {
  using SafeERC20 for IERC20;

  address public immutable ROUTER;

  address public constant DAI = 0x8f3Cf7ad23Cd3CaDbD9735AFf958023239c6A063;
  address public constant USDT = 0xc2132D05D31c914a87C6611C10748AEb04B58e8F;

  constructor(address router) {
    ROUTER = router;
  }

  function dexSwap(
    address sourceTokenAddress,
    address destTokenAddress,
    address receiverAddress,
    address returnToSenderAddress,
    uint256 minSourceTokenAmount,
    uint256 maxSourceTokenAmount,
    uint256 requiredDestTokenAmount,
    bytes memory
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

  function dexAmountOut(bytes memory payload, uint256 amountIn) public view returns (uint256 amountOut, address midToken) {
    // return findBestPath(this._getAmountOut, this.bigger, payload, amountIn);
  }

  function dexAmountOutFormatted(bytes memory payload, uint256 amountIn) public view returns (uint256 amountOut, address midToken) {
    return dexAmountOut(payload, amountIn);
  }

  function dexAmountIn(bytes memory payload, uint256 amountOut) public view returns (uint256 amountIn, address midToken) {
    (amountIn, midToken) = findBestPath(this._getAmountIn, this.smaller, payload, amountOut);

    if (amountIn == type(uint256).max) {
      amountIn = 0;
    }
  }

  function bigger(uint256 a, uint256 b) external pure returns (bool) {
    return a > b;
  }

  function smaller(uint256 a, uint256 b) external pure returns (bool) {
    return a < b;
  }

  function findBestPath(
    function(uint256, address[] memory) external view returns (uint256) getAmount,
    function(uint256, uint256) external pure returns (bool) comarator,
    bytes memory payload,
    uint256 amountIn
  ) internal view returns (uint256 amountOut, address midToken) {
    (address sourceTokenAddress, address destTokenAddress) = abi.decode(payload, (address, address));
    if (sourceTokenAddress == destTokenAddress) {
      amountOut = amountIn;
    } else if (amountIn != 0) {
      uint256 tmpValue;

      address[] memory path = new address[](2);
      path[0] = sourceTokenAddress;
      path[1] = destTokenAddress;
      amountOut = getAmount(amountIn, path);

      path = new address[](3);
      path[0] = sourceTokenAddress;
      path[2] = destTokenAddress;

      if (sourceTokenAddress != address(WETH) && destTokenAddress != address(WETH)) {
        path[1] = address(WETH);
        tmpValue = getAmount(amountIn, path);
        if (comarator(tmpValue, amountOut)) {
          amountOut = tmpValue;
          midToken = address(WETH);
        }
      }

      if (sourceTokenAddress != DAI && destTokenAddress != DAI) {
        path[1] = DAI;
        tmpValue = getAmount(amountIn, path);
        if (comarator(tmpValue, amountOut)) {
          amountOut = tmpValue;
          midToken = DAI;
        }
      }

      if (sourceTokenAddress != USDC && destTokenAddress != USDC) {
        path[1] = USDC;
        tmpValue = getAmount(amountIn, path);
        if (comarator(tmpValue, amountOut)) {
          amountOut = tmpValue;
          midToken = USDC;
        }
      }

      if (sourceTokenAddress != USDT && destTokenAddress != USDT) {
        path[1] = USDT;
        tmpValue = getAmount(amountIn, path);
        if (comarator(tmpValue, amountOut)) {
          amountOut = tmpValue;
          midToken = USDT;
        }
      }
    }
  }

  function dexAmountInFormatted(bytes memory payload, uint256 amountOut) public view returns (uint256 amountIn, address midToken) {
    return dexAmountIn(payload, amountOut);
  }

  function _getAmountOut(uint256 amountIn, address[] memory path) public view returns (uint256 amountOut) {
    (bool success, bytes memory data) = ROUTER.staticcall(
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
    (bool success, bytes memory data) = ROUTER.staticcall(
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
      IERC20(tokens[i]).safeApprove(ROUTER, 0);
      IERC20(tokens[i]).safeApprove(ROUTER, type(uint256).max);
    }
  }

  function revokeApprovals(address[] memory tokens) public {
    for (uint256 i = 0; i < tokens.length; i++) {
      IERC20(tokens[i]).safeApprove(ROUTER, 0);
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

    uint256[] memory amounts = IUniswapV2Router(ROUTER).swapExactTokensForTokens(
      sourceTokenAmountUsed,
      1, // amountOutMin
      path,
      receiverAddress,
      block.timestamp
    );

    destTokenAmountReceived = amounts[amounts.length - 1];
  }
}
