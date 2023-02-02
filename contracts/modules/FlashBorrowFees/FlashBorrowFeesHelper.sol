/**
 * Copyright 2017-2023, bZxDao. All Rights Reserved.
 * Licensed under the Apache License, Version 2.0.
 */

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

import "contracts/core/State.sol";
import "contracts/mixins/VaultController.sol";

contract FlashBorrowFeesHelper is State, VaultController {
  event PayFlashBorrowFee(address indexed payer, address indexed token, uint256 amount);

  function initialize(address target) external onlyOwner {
    _setTarget(this.payFlashBorrowFees.selector, target);
  }

  function payFlashBorrowFees(
    address user,
    uint256 borrowAmount,
    uint256 flashBorrowFeePercent
  ) external {
    address feeToken = loanPoolToUnderlying[msg.sender];

    // only callable by loan pools
    require(feeToken != address(0), "not authorized");

    uint256 feeTokenAmount = (borrowAmount * flashBorrowFeePercent) / WEI_PERCENT_PRECISION;

    vaultDeposit(feeToken, msg.sender, feeTokenAmount);

    if (feeTokenAmount != 0) {
      borrowingFeeTokensHeld[feeToken] = borrowingFeeTokensHeld[feeToken] + feeTokenAmount;
    }

    emit PayFlashBorrowFee(user, feeToken, feeTokenAmount);
  }
}
