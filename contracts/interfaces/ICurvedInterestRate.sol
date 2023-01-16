/**
 * Copyright 2017-2022, OokiDao. All Rights Reserved.
 * Licensed under the Apache License, Version 2.0.
 */

// SPDX-License-Identifier: Apache-2.0

pragma solidity >=0.5.0 <0.9.0;

interface ICurvedInterestRate {
    function getInterestRate(
        uint256 _U,
        uint256 _a,
        uint256 _b,
        uint256 _UR_MAX,
        uint256 _IR_ABSOLUTE_MIN
    ) external pure returns (uint256 interestRate);

    // function getAB(uint256 _IR1, address _OWNER) external pure returns (uint256 a, uint256 b);

    function getAB(
        uint256 _IR1,
        uint256 _IR2,
        uint256 _UR1,
        uint256 _UR2,
        uint256 _IR_MIN,
        uint256 _IR_MAX
    ) external pure returns (uint256 a, uint256 b);

    function calculateIR(uint256 _U, uint256 _IR1) external view returns (uint256 interestRate);
}
