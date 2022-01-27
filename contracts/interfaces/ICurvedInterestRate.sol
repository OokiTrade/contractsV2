/**
 * Copyright 2017-2020, bZeroX, LLC. All Rights Reserved.
 * Licensed under the Apache License, Version 2.0.
 */
// SPDX-License-Identifier: Apache-2.0
pragma solidity >=0.5.0 <=0.8.4;
pragma experimental ABIEncoderV2;

interface ICurvedInterestRate {
    function getInterestRate(
        uint256 U,
        uint256 a,
        uint256 b
    ) external pure returns (uint256 interestRate);

    function getAB(
        uint256 IR1,
        uint256 IR2,
        uint256 UR1,
        uint256 UR2
    ) external pure returns (uint256 a, uint256 b);
}
