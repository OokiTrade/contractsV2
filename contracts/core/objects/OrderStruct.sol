/**
 * Copyright 2017-2020, bZeroX, LLC. All Rights Reserved.
 * Licensed under the Apache License, Version 2.0.
 */

pragma solidity 0.5.17;


contract OrderStruct {
    struct Order {
        uint256 lockedAmount;
        uint256 interestRate;
        uint256 minLoanTerm;
        uint256 maxLoanTerm;
        uint256 createdStartTimestamp;
        uint256 expirationStartTimestamp;
    }
}
