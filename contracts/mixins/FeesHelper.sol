/**
 * Copyright 2017-2023, OokiDao. All Rights Reserved.
 * Licensed under the Apache License, Version 2.0.
 */

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

import "contracts/core/State.sol";
import "@openzeppelin-4.8.0/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin-4.8.0/token/ERC20/extensions/IERC20Metadata.sol";
import "interfaces/IPriceFeeds.sol";
import "contracts/mixins/VaultController.sol";
import "contracts/events/FeesEvents.sol";
import "contracts/utils/MathUtil.sol";

abstract contract FeesHelper is State, VaultController, FeesEvents {
  using SafeERC20 for IERC20;
  using MathUtil for uint256;

  function _adjustForHeldBalance(uint256 feeAmount, address user) internal view returns (uint256) {
    uint256 balance = IERC20Metadata(OOKI).balanceOf(user);
    if (balance > 1e25) {
      return (feeAmount * 4).divCeil(5);
    } else if (balance > 1e24) {
      return (feeAmount * 85).divCeil(100);
    } else if (balance > 1e23) {
      return (feeAmount * 9).divCeil(10);
    } else {
      return feeAmount;
    }
  }

  // calculate trading fee
  function _getTradingFee(uint256 feeTokenAmount) internal view returns (uint256) {
    return (feeTokenAmount * tradingFeePercent).divCeil(WEI_PERCENT_PRECISION);
  }

  // calculate trading fee
  function _getTradingFeeWithOOKI(address sourceToken, uint256 feeTokenAmount) internal view returns (uint256) {
    return IPriceFeeds(priceFeeds).queryReturn(sourceToken, OOKI, (feeTokenAmount * tradingFeePercent).divCeil(WEI_PERCENT_PRECISION));
  }

  // calculate loan origination fee
  function _getBorrowingFee(uint256 feeTokenAmount) internal view returns (uint256) {
    return (feeTokenAmount * borrowingFeePercent).divCeil(WEI_PERCENT_PRECISION);
  }

  // calculate loan origination fee
  function _getBorrowingFeeWithOOKI(address sourceToken, uint256 feeTokenAmount) internal view returns (uint256) {
    return IPriceFeeds(priceFeeds).queryReturn(sourceToken, OOKI, (feeTokenAmount * borrowingFeePercent).divCeil(WEI_PERCENT_PRECISION));
  }

  // calculate lender (interest) fee
  function _getLendingFee(uint256 feeTokenAmount) internal view returns (uint256) {
    return (feeTokenAmount * lendingFeePercent).divCeil(WEI_PERCENT_PRECISION);
  }

  // settle trading fee
  function _payTradingFee(
    address user,
    bytes32 loanId,
    address feeToken,
    uint256 tradingFee
  ) internal {
    if (tradingFee != 0) {
      tradingFeeTokensHeld[feeToken] = tradingFeeTokensHeld[feeToken] + tradingFee;

      emit PayTradingFee(user, feeToken, loanId, tradingFee);
    }
  }

  // settle loan origination fee
  function _payBorrowingFee(
    address user,
    bytes32 loanId,
    address feeToken,
    uint256 borrowingFee
  ) internal {
    if (borrowingFee != 0) {
      borrowingFeeTokensHeld[feeToken] = borrowingFeeTokensHeld[feeToken] + borrowingFee;

      emit PayBorrowingFee(user, feeToken, loanId, borrowingFee);
    }
  }

  // settle lender (interest) fee
  function _payLendingFee(
    address lender,
    address feeToken,
    uint256 lendingFee
  ) internal {
    if (lendingFee != 0) {
      lendingFeeTokensHeld[feeToken] = lendingFeeTokensHeld[feeToken] + lendingFee;

      vaultTransfer(feeToken, lender, address(this), lendingFee);

      emit PayLendingFee(lender, feeToken, lendingFee);
    }
  }
}
