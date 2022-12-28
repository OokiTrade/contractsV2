/**
 * Copyright 2017-2023, OokiDao. All Rights Reserved.
 * Licensed under the Apache License, Version 2.0.
 */

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

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
  event LoanParamsIdSetup(bytes32 indexed id, address indexed owner);

  event LoanParamsDisabled(
    bytes32 indexed id,
    address owner,
    address indexed loanToken,
    address indexed collateralToken,
    uint256 minInitialMargin,
    uint256 maintenanceMargin,
    uint256 maxLoanTerm
  );
  event LoanParamsIdDisabled(bytes32 indexed id, address indexed owner);
}
