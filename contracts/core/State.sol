/**
 * Copyright 2017-2022, OokiDao. All Rights Reserved.
 * Licensed under the Apache License, Version 2.0.
 */

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

import './Constants.sol';
import './Objects.sol';
import '../mixins/EnumerableBytes32Set.sol';
import '@openzeppelin-4.7.0/security/ReentrancyGuard.sol';
import '../utils/InterestOracle.sol';
import '../utils/VolumeTracker.sol';
import '@openzeppelin-4.7.0/access/Ownable.sol';

abstract contract State is Constants, Objects, ReentrancyGuard, Ownable {
  using EnumerableBytes32Set for EnumerableBytes32Set.Bytes32Set;
  address public priceFeeds; // handles asset reference price lookups
  address public swapsImpl; // handles asset swaps using dex liquidity

  mapping(bytes4 => address) public logicTargets; // implementations of protocol functions

  mapping(bytes32 => Loan) public loans; // loanId => Loan
  mapping(bytes32 => LoanParams) public loanParams; // loanParamsId => LoanParams loanParamsId = keccak(loanToken, collateralToken,isTorque)

  mapping(address => mapping(bytes32 => Order)) public lenderOrders; // lender => orderParamsId => Order
  mapping(address => mapping(bytes32 => Order)) public borrowerOrders; // borrower => orderParamsId => Order

  mapping(bytes32 => mapping(address => bool)) public delegatedManagers; // loanId => delegated => approved

  // Interest
  mapping(address => mapping(address => LenderInterest)) public lenderInterest; // lender => loanToken => LenderInterest object (depreciated)
  mapping(bytes32 => LoanInterest) public loanInterest; // loanId => LoanInterest object (depreciated)

  // Internals
  EnumerableBytes32Set.Bytes32Set internal logicTargetsSet; // implementations set
  EnumerableBytes32Set.Bytes32Set internal activeLoansSet; // active loans set

  mapping(address => EnumerableBytes32Set.Bytes32Set) internal lenderLoanSets; // lender loans set
  mapping(address => EnumerableBytes32Set.Bytes32Set) internal borrowerLoanSets; // borrow loans set
  mapping(address => EnumerableBytes32Set.Bytes32Set) internal userLoanParamSets; // user loan params set (deprecated)

  address public feesController; // address controlling fee withdrawals

  uint256 public lendingFeePercent = 10 ether; // 10% fee                                 // fee taken from lender interest payments
  mapping(address => uint256) public lendingFeeTokensHeld; // total interest fees received and not withdrawn per asset
  mapping(address => uint256) public lendingFeeTokensPaid; // total interest fees withdraw per asset (lifetime fees = lendingFeeTokensHeld + lendingFeeTokensPaid)

  uint256 public tradingFeePercent = 0.15 ether; // 0.15% fee                             // fee paid for each trade
  mapping(address => uint256) public tradingFeeTokensHeld; // total trading fees received and not withdrawn per asset
  mapping(address => uint256) public tradingFeeTokensPaid; // total trading fees withdraw per asset (lifetime fees = tradingFeeTokensHeld + tradingFeeTokensPaid)

  uint256 public borrowingFeePercent = 0.09 ether; // 0.09% fee                           // origination fee paid for each loan
  mapping(address => uint256) public borrowingFeeTokensHeld; // total borrowing fees received and not withdrawn per asset
  mapping(address => uint256) public borrowingFeeTokensPaid; // total borrowing fees withdraw per asset (lifetime fees = borrowingFeeTokensHeld + borrowingFeeTokensPaid)

  uint256 public protocolTokenHeld; // current protocol token deposit balance
  uint256 public protocolTokenPaid; // lifetime total payout of protocol token

  uint256 public affiliateFeePercent = 30 ether; // 30% fee share                         // fee share for affiliate program

  mapping(address => mapping(address => uint256)) public liquidationIncentivePercent; // percent discount on collateral for liquidators per loanToken and collateralToken, LiquidationHelper.getLiquidationAmounts will use default liquidation incentive of 7e18

  mapping(address => address) public loanPoolToUnderlying; // loanPool => underlying
  mapping(address => address) public underlyingToLoanPool; // underlying => loanPool
  EnumerableBytes32Set.Bytes32Set internal loanPoolsSet; // loan pools set

  mapping(address => bool) public supportedTokens; // supported tokens for swaps

  uint256 public maxDisagreement = 5 ether; // % disagreement between swap rate and reference rate

  uint256 public sourceBufferPercent = 5 ether; // used to estimate kyber swap source amount

  uint256 public maxSwapSize = 1500 ether; // maximum supported swap size in ETH

  /**** new interest model start */
  mapping(address => uint256) public poolLastUpdateTime; // per itoken
  mapping(address => uint256) public poolPrincipalTotal; // per itoken
  mapping(address => uint256) public poolInterestTotal; // per itoken
  mapping(address => uint256) public poolRatePerTokenStored; // per itoken

  mapping(bytes32 => uint256) public loanInterestTotal; // per loan
  mapping(bytes32 => uint256) public loanRatePerTokenPaid; // per loan

  mapping(address => uint256) internal poolLastInterestRate; // per itoken
  mapping(address => InterestOracle.Observation[256]) internal poolInterestRateObservations; // per itoken
  mapping(address => uint8) internal poolLastIdx; // per itoken
  uint32 public timeDelta;
  uint32 public twaiLength;
  /**** new interest model end */

  mapping(address => VolumeTracker.Observation[65535]) internal volumeTradedObservations; //recorded Observations for every trade per user
  mapping(address => uint16) internal volumeLastIdx; //last index in the observation array. bounded by cardinality
  mapping(address => uint16) internal volumeTradedCardinality; //upper bound for recording data into array. Can be increased, not decreased, and increases cost for binary searches when increased. increase with caution

  /* PL */
  address public factory;

  function _setTarget(bytes4 sig, address target) internal {
    logicTargets[sig] = target;

    if (target != address(0)) {
      logicTargetsSet.addBytes32(bytes32(sig));
    } else {
      logicTargetsSet.removeBytes32(bytes32(sig));
    }
  }
}
