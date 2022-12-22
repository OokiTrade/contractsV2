/**
 * Copyright 2017-2022, OokiDao. All Rights Reserved.
 * Licensed under the Apache License, Version 2.0.
 */

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

contract FeesEvents {
  enum FeeType {
    Lending,
    Trading,
    Borrowing,
    SettleInterest
  }

  event PayLendingFee(address indexed payer, address indexed token, uint256 amount);

  event SettleFeeRewardForInterestExpense(address indexed payer, address indexed token, bytes32 indexed loanId, uint256 amount);

  event PayTradingFee(address indexed payer, address indexed token, bytes32 indexed loanId, uint256 amount);

  event PayBorrowingFee(address indexed payer, address indexed token, bytes32 indexed loanId, uint256 amount);

  // DEPRECATED
  event EarnReward(address indexed receiver, bytes32 indexed loanId, FeeType indexed feeType, address token, uint256 amount);
}
