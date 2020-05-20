/**
 * Copyright 2017-2020, bZeroX, LLC. All Rights Reserved.
 * Licensed under the Apache License, Version 2.0.
 */

pragma solidity 0.5.17;


contract LoanInterestStruct {
    struct LoanInterest {
        uint256 owedPerDay;         // interestOwedPerDay
        uint256 depositTotal;       // interestDepositTotal
        uint256 updatedTimestamp;   // updatedTimestamp
    }
}
