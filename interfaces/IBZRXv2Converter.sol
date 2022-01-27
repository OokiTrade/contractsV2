/**
 * Copyright 2017-2022, OokiDao. All Rights Reserved.
 * Licensed under the Apache-2.0
 */
// SPDX-License-Identifier: Apache-2.0
pragma solidity >=0.5.0 <=0.8.4;
pragma experimental ABIEncoderV2;

interface IBZRXv2Converter {
    function convert(address receiver, uint256 _tokenAmount) external;
}
