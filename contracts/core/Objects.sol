/**
 * Copyright 2017-2020, bZeroX, LLC. All Rights Reserved.
 * Licensed under the Apache License, Version 2.0.
 */

pragma solidity 0.5.17;

import "./objects/LoanStruct.sol";
import "./objects/LoanParamsStruct.sol";
import "./objects/OrderStruct.sol";
import "./objects/LenderInterestStruct.sol";
import "./objects/LoanInterestStruct.sol";


contract Objects is
    LoanStruct,
    LoanParamsStruct,
    OrderStruct,
    LenderInterestStruct,
    LoanInterestStruct
{}