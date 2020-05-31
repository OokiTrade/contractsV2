/**
 * Copyright 2017-2020, bZeroX, LLC. All Rights Reserved.
 * Licensed under the Apache License, Version 2.0.
 */

pragma solidity 0.5.17;


contract LoanStruct {
    struct Loan {
        bytes32 id;
        bytes32 loanParamsId;
        bytes32 pendingTradesId;
        bool active;
        uint256 principal;
        uint256 collateral;
        uint256 startTimestamp;
        uint256 endTimestamp;
        uint256 startMargin;
        uint256 startRate; // collateralToLoanRate
        address borrower;
        address lender;
    }
}
