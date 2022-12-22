/**
 * Copyright 2017-2022, OokiDao. All Rights Reserved.
 * Licensed under the Apache License, Version 2.0.
 */

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

import '../core/Constants.sol';
import '@openzeppelin-4.7.0/token/ERC20/utils/SafeERC20.sol';

abstract contract VaultController is Constants {
  using SafeERC20 for IERC20;

  event VaultDeposit(
    address indexed asset,
    address indexed from,
    uint256 amount
  );
  event VaultWithdraw(
    address indexed asset,
    address indexed to,
    uint256 amount
  );

  function vaultEtherDeposit(address from, uint256 value) internal {
    IWeth _wethToken = wethToken;
    _wethToken.deposit{ value: value }();

    emit VaultDeposit(address(_wethToken), from, value);
  }

  function vaultEtherWithdraw(address to, uint256 value) internal {
    if (value != 0) {
      IWeth _wethToken = wethToken;
      uint256 balance = address(this).balance;
      if (value > balance) {
        _wethToken.withdraw(value - balance);
      }
      Address.sendValue(payable(address(uint160(to))), value);

      emit VaultWithdraw(address(_wethToken), to, value);
    }
  }

  function vaultDeposit(address token, address from, uint256 value) internal {
    if (value != 0) {
      IERC20(token).safeTransferFrom(from, address(this), value);

      emit VaultDeposit(token, from, value);
    }
  }

  function vaultWithdraw(address token, address to, uint256 value) internal {
    if (value != 0) {
      IERC20(token).safeTransfer(to, value);

      emit VaultWithdraw(token, to, value);
    }
  }

  function vaultTransfer(
    address token,
    address from,
    address to,
    uint256 value
  ) internal {
    if (value != 0) {
      if (from == address(this)) {
        IERC20(token).safeTransfer(to, value);
      } else {
        IERC20(token).safeTransferFrom(from, to, value);
      }
    }
  }

  function vaultApprove(address token, address to, uint256 value) internal {
    if (value != 0 && IERC20(token).allowance(address(this), to) != 0) {
      IERC20(token).safeApprove(to, 0);
    }
    IERC20(token).safeApprove(to, value);
  }
}
