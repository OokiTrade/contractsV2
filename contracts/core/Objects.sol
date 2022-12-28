/**
 * Copyright 2017-2023, OokiDao. All Rights Reserved.
 * Licensed under the Apache License, Version 2.0.
 */

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

import "contracts/core/objects/LoanStruct.sol";
import "contracts/core/objects/LoanParamsStruct.sol";
import "contracts/core/objects/OrderStruct.sol";
import "contracts/core/objects/LenderInterestStruct.sol";
import "contracts/core/objects/LoanInterestStruct.sol";

contract Objects is LoanStruct, LoanParamsStruct, OrderStruct, LenderInterestStruct, LoanInterestStruct {}
