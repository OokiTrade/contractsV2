/**
 * Copyright 2017-2020, bZeroX, LLC. All Rights Reserved.
 * Licensed under the Apache License, Version 2.0.
 */

pragma solidity 0.5.17;


contract LenderInterestStruct {
    struct LenderInterest {
        uint256 principalTotal;     // total borrowed amount outstanding
        uint256 owedPerDay;         // interestOwedPerDay
        uint256 owedTotal;          // interest owed for all loans (assuming they go to full term)
        uint256 paidTotal;          // interestPaid so far
        uint256 updatedTimestamp;   // interestPaidDate
    }
}
