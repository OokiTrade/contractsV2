/**
 * Copyright 2017-2021, bZxDao. All Rights Reserved.
 * Licensed under the Apache License, Version 2.0.
 */

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

import '../core/State.sol';
import '../interfaces/ILoanPool.sol';
import '../utils/MathUtil.sol';
import '../events/InterestRateEvents.sol';
import '../utils/InterestOracle.sol';
import '../utils/TickMathV1.sol';

abstract contract InterestHandler is State, InterestRateEvents {
  using MathUtil for uint256;
  using InterestOracle for InterestOracle.Observation[256];

  // returns up to date loan interest or 0 if not applicable
  function _settleInterest(
    address pool,
    bytes32 loanId
  ) internal returns (uint256 _loanInterestTotal) {
    poolLastIdx[pool] = poolInterestRateObservations[pool].write(
      poolLastIdx[pool],
      uint32(block.timestamp),
      TickMathV1.getTickAtSqrtRatio(uint160(poolLastInterestRate[pool])),
      type(uint8).max,
      timeDelta
    );
    uint256[7] memory interestVals = _settleInterest2(pool, loanId, false);
    poolInterestTotal[pool] = interestVals[1];
    poolRatePerTokenStored[pool] = interestVals[2];

    if (interestVals[3] != 0) {
      poolLastInterestRate[pool] = interestVals[3];
      emit PoolInterestRateVals(
        pool,
        interestVals[0],
        interestVals[1],
        interestVals[2],
        interestVals[3]
      );
    }

    if (loanId != 0) {
      _loanInterestTotal = interestVals[5];
      loanInterestTotal[loanId] = _loanInterestTotal;
      loanRatePerTokenPaid[loanId] = interestVals[6];
      emit LoanInterestRateVals(
        loanId,
        interestVals[4],
        interestVals[5],
        interestVals[6]
      );
    }

    poolLastUpdateTime[pool] = block.timestamp;
  }

  function _getPoolPrincipal(address pool) internal view returns (uint256) {
    uint256[7] memory interestVals = _settleInterest2(pool, 0, true);

    return
      interestVals[0] + interestVals[1]; // _poolPrincipalTotal // _poolInterestTotal
  }

  function _getLoanPrincipal(
    address pool,
    bytes32 loanId
  ) internal view returns (uint256) {
    uint256[7] memory interestVals = _settleInterest2(pool, loanId, false);

    return
      interestVals[4] + interestVals[5]; // _loanPrincipalTotal // _loanInterestTotal
  }

  function _settleInterest2(
    address pool,
    bytes32 loanId,
    bool includeLendingFee
  ) internal view returns (uint256[7] memory interestVals) {
    /*
            uint256[7] ->
            0: _poolPrincipalTotal,
            1: _poolInterestTotal,
            2: _poolRatePerTokenStored,
            3: _poolNextInterestRate,
            4: _loanPrincipalTotal,
            5: _loanInterestTotal,
            6: _loanRatePerTokenPaid
        */

    interestVals[0] =
      poolPrincipalTotal[pool] +
      lenderInterest[pool][loanPoolToUnderlying[pool]].principalTotal; // backwards compatibility
    interestVals[1] = poolInterestTotal[pool];

    uint256 lendingFee = interestVals[1] *
      (lendingFeePercent).divCeil(WEI_PERCENT_PRECISION);

    uint256 _poolVariableRatePerTokenNewAmount;
    (
      _poolVariableRatePerTokenNewAmount,
      interestVals[3]
    ) = _getRatePerTokenNewAmount(
      pool,
      interestVals[0] + (interestVals[1] - lendingFee)
    );

    interestVals[1] =
      (interestVals[0] * _poolVariableRatePerTokenNewAmount) /
      (WEI_PERCENT_PRECISION * WEI_PERCENT_PRECISION) +
      interestVals[1];

    if (includeLendingFee) {
      interestVals[1] -= lendingFee;
    }

    interestVals[2] =
      poolRatePerTokenStored[pool] +
      _poolVariableRatePerTokenNewAmount;

    if (loanId != 0 && (interestVals[4] = loans[loanId].principal) != 0) {
      interestVals[5] =
        (interestVals[4] * (interestVals[2] - (loanRatePerTokenPaid[loanId]))) / // _loanRatePerTokenUnpaid
        (WEI_PERCENT_PRECISION * WEI_PERCENT_PRECISION) +
        (loanInterestTotal[loanId]);

      interestVals[6] = interestVals[2];
    }
  }

  function _getRatePerTokenNewAmount(
    address pool,
    uint256 poolTotal
  )
    internal
    view
    returns (uint256 ratePerTokenNewAmount, uint256 nextInterestRate)
  {
    uint256 timeSinceUpdate = block.timestamp - poolLastUpdateTime[pool];
    uint256 benchmarkRate = TickMathV1.getSqrtRatioAtTick(
      poolInterestRateObservations[pool].arithmeticMean(
        uint32(block.timestamp),
        [uint32(timeSinceUpdate + twaiLength), uint32(timeSinceUpdate)],
        poolInterestRateObservations[pool][poolLastIdx[pool]].tick,
        poolLastIdx[pool],
        type(uint8).max
      )
    );
    if (
      timeSinceUpdate != 0 &&
      (nextInterestRate = ILoanPool(pool)._nextBorrowInterestRate(
        poolTotal,
        0,
        benchmarkRate
      )) !=
      0
    ) {
      ratePerTokenNewAmount =
        (timeSinceUpdate * (nextInterestRate) * (WEI_PERCENT_PRECISION)) / // rate per year
        (31536000); // seconds in a year
    }
  }
}
