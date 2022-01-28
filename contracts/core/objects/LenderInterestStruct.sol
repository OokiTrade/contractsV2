/**
 * Copyright 2017-2022, OokiDao. All Rights Reserved.
 * Licensed under the Apache License, Version 2.0.
 */

pragma solidity 0.5.17;


contract LenderInterestStruct {
    struct LenderInterest {
        uint256 principalTotal;     // total borrowed amount outstanding of asset (DEPRECIATED)
        uint256 owedPerDay;         // interest owed per day for all loans of asset (DEPRECIATED)
        uint256 owedTotal;          // total interest owed for all loans of asset (DEPRECIATED)
        uint256 paidTotal;          // total interest paid so far for asset (DEPRECIATED)
        uint256 updatedTimestamp;   // last update (DEPRECIATED)
    }
}
