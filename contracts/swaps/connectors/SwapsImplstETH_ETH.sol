/**
 * Copyright 2017-2021, bZeroX, LLC. All Rights Reserved.
 * Licensed under the Apache License, Version 2.0.
 */

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

import "contracts/core/State.sol";
import "contracts/interfaces/curve/ICurve.sol";
import "@openzeppelin-4.8.0/token/ERC20/utils/SafeERC20.sol";
import "interfaces/ISwapsImpl.sol";
import "contracts/interfaces/IwstETH.sol";
import "contracts/interfaces/IstETH.sol";

contract SwapsImplstETH_ETH is State, ISwapsImpl {
  using SafeERC20 for IERC20;
  address public immutable STETH;
  address public immutable WSTETH;
  ICurve public immutable STETHPOOL;

  constructor(
    address steth,
    address wsteth,
    ICurve stethpool
  ) {
    STETH = steth;
    WSTETH = wsteth;
    STETHPOOL = stethpool;
  }

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
    require((sourceTokenAddress == WSTETH || sourceTokenAddress == address(WETH)) && (destTokenAddress == WSTETH || destTokenAddress == address(WETH)), "unsupported tokens");

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
    if (amountIn != 0) {
      (, address srcToken, address destToken) = abi.decode(payload, (uint256, address, address));
      if (srcToken == address(WETH)) {
        if (abi.decode(payload, (uint256)) > 0) {
          amountIn = STETHPOOL.get_dy(0, 1, amountIn);
          amountOut = IwstETH(WSTETH).getWstETHBystETH(amountIn);
        } else {
          amountOut = IwstETH(WSTETH).getWstETHBystETH(amountIn);
        }
      } else {
        amountIn = IwstETH(WSTETH).getStETHByWstETH(amountIn);
        amountOut = STETHPOOL.get_dy(1, 0, amountIn);
      }
    }
  }

  function dexAmountOutFormatted(bytes memory payload, uint256 amountIn) public returns (uint256 amountOut, address midToken) {
    return dexAmountOut(payload, amountIn);
  }

  function dexAmountIn(bytes memory route, uint256 amountOut) public returns (uint256 amountIn, address midToken) {
    revert("unsupported");
  }

  function dexAmountInFormatted(bytes memory payload, uint256 amountOut) public returns (uint256 amountIn, address midToken) {
    revert("unsupported");
  }

  function setSwapApprovals(
    address[] memory /*tokens*/
  ) public {
    IERC20(STETH).safeApprove(WSTETH, 0);
    IERC20(STETH).safeApprove(WSTETH, type(uint256).max);
    IERC20(STETH).safeApprove(address(STETHPOOL), 0);
    IERC20(STETH).safeApprove(address(STETHPOOL), type(uint256).max);
  }

  function revokeApprovals(
    address[] memory /*tokens*/
  ) public {
    IERC20(STETH).safeApprove(WSTETH, 0);
    IERC20(STETH).safeApprove(address(STETHPOOL), 0);
  }

  function _swap(
    address sourceTokenAddress,
    address destTokenAddress,
    address receiverAddress,
    uint256 minSourceTokenAmount,
    uint256, /*maxSourceTokenAmount*/
    uint256 requiredDestTokenAmount,
    bytes memory payload
  ) internal returns (uint256 sourceTokenAmountUsed, uint256 destTokenAmountReceived) {
    require(requiredDestTokenAmount == 0, "required dest token amount unsupported");
    sourceTokenAmountUsed = minSourceTokenAmount;
    if (sourceTokenAddress == address(WETH)) {
      WETH.withdraw(minSourceTokenAmount);
      uint256 wstETHAmount = abi.decode(payload, (uint256));
      if (wstETHAmount > 0) {
        destTokenAmountReceived = STETHPOOL.exchange{value: minSourceTokenAmount}(0, 1, minSourceTokenAmount, abi.decode(payload, (uint256)));
      } else {
        destTokenAmountReceived = IstETH(STETH).submit{value: minSourceTokenAmount}(address(this));
      }
      destTokenAmountReceived = IwstETH(WSTETH).wrap(destTokenAmountReceived);
    } else {
      requiredDestTokenAmount = IwstETH(WSTETH).unwrap(minSourceTokenAmount);
      destTokenAmountReceived = STETHPOOL.exchange(1, 0, requiredDestTokenAmount, abi.decode(payload, (uint256)));
      WETH.deposit{value: destTokenAmountReceived}();
    }
    if (receiverAddress != address(this)) {
      IERC20(destTokenAddress).transfer(receiverAddress, destTokenAmountReceived);
    }
  }
}
