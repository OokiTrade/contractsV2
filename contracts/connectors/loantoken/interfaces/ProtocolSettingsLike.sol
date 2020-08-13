/**
 * Copyright 2017-2020, bZeroX, LLC. All Rights Reserved.
 * Licensed under the Apache License, Version 2.0.
 */

// SPDX-License-Identifier: GNU 
pragma solidity 0.6.12;

pragma experimental ABIEncoderV2;

import "../../../core/objects/LoanParamsStruct.sol";


interface ProtocolSettingsLike {
    function setupLoanParams(
        LoanParamsStruct.LoanParams[] calldata loanParamsList)
        external
        returns (bytes32[] memory loanParamsIdList);

    function disableLoanParams(
        bytes32[] calldata loanParamsIdList)
        external;
}
