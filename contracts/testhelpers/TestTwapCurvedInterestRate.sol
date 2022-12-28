/**
 * Copyright 2017-2021, bZxDao. All Rights Reserved.
 * Licensed under the Apache License, Version 2.0.
 */

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

// import "prb-math/contracts/PRBMathUD60x18.sol";
// import "@openzeppelin-4.7.0/math/SafeMath";
import '../utils/InterestOracle.sol';
import '../utils/TickMathV1.sol';
import '../interfaces/ICurvedInterestRate.sol';

contract TestTwapCurvedInterestRate {
  // using PRBMathUD60x18 for uint256;
  // using SafeMath for uint256;
  using InterestOracle for InterestOracle.Observation[256];
  event Logger(string name, uint256 value);

  ICurvedInterestRate public rateHelper;
  uint256 public lastIR;

  InterestOracle.Observation[256] public poolInterestRateObservations; //per itoken
  uint8 public poolLastIdx; //per itoken

  function initOracle() public {
    poolInterestRateObservations[0].blockTimestamp = uint32(block.timestamp - 10800);
  }

  function setRateHelper(ICurvedInterestRate _rateHelper) public {
    rateHelper = _rateHelper;
  }

  function writeIR(uint256 _lastIR) public {
    lastIR = _lastIR;
  }

  function borrow(uint256 newUtilization) public returns (uint256 interestRate) {
    poolLastIdx = poolInterestRateObservations.write(poolLastIdx, uint32(block.timestamp), TickMathV1.getTickAtSqrtRatio(uint160(lastIR)), type(uint8).max, 60);

    uint256 benchmarkRate = TickMathV1.getSqrtRatioAtTick(
      poolInterestRateObservations.arithmeticMean(uint32(block.timestamp), [uint32(3 * 3600), 0], poolInterestRateObservations[poolLastIdx].tick, poolLastIdx, type(uint8).max)
    );
    interestRate = rateHelper.calculateIR(newUtilization, benchmarkRate);
    if (interestRate < 1e10) {
      interestRate = 1e10;
    }
    lastIR = interestRate;
  }

  function lastRecordedIR() public view returns (uint256) {
    return TickMathV1.getSqrtRatioAtTick(poolInterestRateObservations[poolLastIdx].tick);
  }
}
