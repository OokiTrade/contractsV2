/**
 * Copyright 2017-2020, bZeroX, LLC. All Rights Reserved.
 * Licensed under the Apache License, Version 2.0.
 */

pragma solidity 0.5.17;


contract LoanSettingsEvents {
    event LoanParamsSetup(
        bytes32 indexed id,
        address owner,
        address indexed loanToken,
        address indexed collateralToken,
        uint256 minInitialMargin,
        uint256 maintenanceMargin,
        uint256 maxLoanTerm
    );
    event LoanParamsIdSetup(
        bytes32 indexed id,
        address indexed owner
    );

    event LoanParamsDisabled(
        bytes32 indexed id,
        address owner,
        address indexed loanToken,
        address indexed collateralToken,
        uint256 minInitialMargin,
        uint256 maintenanceMargin,
        uint256 maxLoanTerm
    );
    event LoanParamsIdDisabled(
        bytes32 indexed id,
        address indexed owner
    );

    event LoanOrderSetup(
        bytes32 indexed loanParamsId,
        address indexed owner,
        bool indexed isLender,
        uint256 lockedAmount,
        uint256 interestRate,
        uint256 expirationTimestamp
    );

    event LoanOrderChangeAmount(
        bytes32 indexed loanParamsId,
        address indexed owner,
        bool indexed isLender,
        uint256 oldBalance,
        uint256 newBalance
    );

    event LoanOrderChangeExpiration(
        bytes32 indexed loanParamsId,
        address indexed owner,
        bool indexed isLender,
        uint256 oldTimestamp,
        uint256 newTimestamp
    );
}