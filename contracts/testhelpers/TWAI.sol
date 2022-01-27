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

    function getInterestRate(uint256 interestRate) public pure returns(uint256 newInterestRate){
        (uint256 a, uint256 b) = getAB(interestRate);
        
        uint256 e = 2.7e18;

        return (a*e/1e18)**(b*interestRate/1e36);

    }

    function getAB(uint256 interestRate) public pure returns (uint256 a, uint256 b) {
        // here
        uint256 utilRate1 = 0.8e18;
        uint256 utilRate2 = 1e18;
        uint256 intRate1 = 0.2e18;
        uint256 intRate2 = 1.2e18;
        // y = (1000 * (((0.2/1.2) ** (1/1000)) - 1))/(0.8-0.9)
        // x = 0.2/e**(0.8 * y)

        uint256 a;
        a = (1 - (1000 * (((intRate1*1e18/intRate2) ** (1/1000)) )/(utilRate2 - utilRate1)
        return  (1e18, 1e18);
    }
}
