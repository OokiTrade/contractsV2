/**
 * Copyright 2017-2021, bZxDao. All Rights Reserved.
 * Licensed under the Apache License, Version 2.0.
 */

pragma solidity 0.5.17;
import "@openzeppelin-2.5.0/math/SafeMath.sol";

contract TWAI {
    using SafeMath for uint256;

    // uint256 public twai;
    // uint256 public lastTimestamp;
    uint256 public lastIR;

    function initTWAI(uint256 interestRate) public {
        lastIR = interestRate;
    }

    function writeIR(uint256 _lastIR) public {
        lastIR = _lastIR;
    }

    function getInterestRate(uint256 utilizationRate, uint256 interestRate) public pure returns(uint256 newInterestRate){
        (uint256 a, uint256 b) = getAB(interestRate);
        
        uint256 highestInterestRateAt100Percent = 1.2e18;
        uint256 targetUtilizationRate = 0.8e18;

        return (1000 * (((interestRate/highestInterestRateAt100Percent) ** uint256(1/1000)) - 1))/(targetUtilizationRate-1e18);
        //  (1000 * (((0.2/1.2) ** (1/1000)) - 1))/(0.8-0.9)

    }

    function getAB(uint256 interestRate) public pure returns (uint256 a, uint256 b) {
        return  (1e18, 1e18);
    }
}
