/**
 * Copyright 2017-2022, OokiDao. All Rights Reserved.
 * Licensed under the Apache License, Version 2.0.
 */

pragma solidity ^0.8.0;


contract LoanInterestStruct {
    struct LoanInterest {
        uint256 owedPerDay;         // interest owed per day for loan (DEPRECIATED)
        uint256 depositTotal;       // total escrowed interest for loan (DEPRECIATED)
        uint256 updatedTimestamp;   // last update (DEPRECIATED)
    }
}
