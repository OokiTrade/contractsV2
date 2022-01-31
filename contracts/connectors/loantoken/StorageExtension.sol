/**
 * Copyright 2017-2022, OokiDao. All Rights Reserved.
 * Licensed under the Apache License, Version 2.0.
 */

pragma solidity 0.5.17;

import "../../interfaces/ICurvedInterestRate.sol";


contract StorageExtension {

    address internal target_;
    uint256 public flashBorrowFeePercent; // set to 0.03%

    // uint256 public IR2;
    // uint256 public UR1;
    // uint256 public UR2;
    ICurvedInterestRate rateHelper;
}