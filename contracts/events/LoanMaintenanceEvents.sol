/**
 * Copyright 2017-2020, bZeroX, LLC. All Rights Reserved.
 * Licensed under the Apache License, Version 2.0.
 */

pragma solidity 0.5.17;


contract LoanMaintenanceEvents {

    // topic0: 0xa8a69faa6a38cc9c2beed79e034e1bd99f7eac877a5cee9f0118a8667b7ed93e
    event DepositCollateral(
        address indexed user,
        address indexed depositToken,
        bytes32 indexed loanId,
        uint256 depositAmount
    );

    // topic0: 0x7b1bab051266a4a36232da9b4341daf225fa42f7202b0e7207b9b502644ff1bb
    event WithdrawCollateral(
        address indexed user,
        address indexed withdrawToken,
        bytes32 indexed loanId,
        uint256 withdrawAmount
    );

    // topic0: 0x1a82d5bf63a278f4fcb396bfc36eb7457ad565605dd62b6f0f80619f811279db
    event ExtendLoanDuration(
        address indexed user,
        address indexed depositToken,
        bytes32 indexed loanId,
        uint256 depositAmount,
        uint256 collateralUsedAmount,
        uint256 newEndTimestamp
    );

    // topic0: 0x2ccf872a9a65a45661ce779b7bc6808ef3a167e50289371df14de6df2f817c7d
    event ReduceLoanDuration(
        address indexed user,
        address indexed withdrawToken,
        bytes32 indexed loanId,
        uint256 withdrawAmount,
        uint256 newEndTimestamp
    );
}
