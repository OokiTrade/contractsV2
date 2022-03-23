/**
 * Copyright 2017-2021, bZxDao. All Rights Reserved.
 * Licensed under the Apache License, Version 2.0.
 */


pragma solidity ^0.5.0;

// import "prb-math/contracts/PRBMathUD60x18.sol";
// import "@openzeppelin-4.3.2/math/SafeMath";
import "../utils/InterestOracle.sol";
import "../utils/TickMath.sol";
import "../utils/TickMath.sol";
import "../interfaces/ICurvedInterestRate.sol";

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
        poolInterestRateObservations.initialize(uint32(block.timestamp - 3600));
        // poolLastIdx = 1;
    }


    function setRateHelper(ICurvedInterestRate _rateHelper) public {
        rateHelper = _rateHelper;
    }

    function writeIR(uint256 _lastIR) public {
        lastIR = _lastIR;
    }

    function borrow(uint256 newUtilization) public returns (uint256 interestRate) {

        (poolLastIdx, ) = poolInterestRateObservations.write(
                                                            poolLastIdx,
                                                            uint32(block.timestamp),
                                                            TickMath.getTickAtSqrtRatio(uint160(lastIR)),
                                                            uint8(-1),
                                                            uint8(-1)
                                                        );

        
        uint32[] memory secondsAgo = new uint32[](2);
        secondsAgo[0] = 0;
        secondsAgo[1] = 3600;

        uint256 benchmarkRate = TickMath.getSqrtRatioAtTick(poolInterestRateObservations.arithmeticMean(
                                                                uint32(block.timestamp),
                                                                secondsAgo,
                                                                TickMath.getTickAtSqrtRatio(uint160(lastIR)),
                                                                poolLastIdx,
                                                                uint8(-1)
                                                            ));

        interestRate = rateHelper.calculateIR(newUtilization, benchmarkRate);
        if (interestRate < 1e10) {
            interestRate = 1e10;
        }
        lastIR = interestRate;
    }

}
