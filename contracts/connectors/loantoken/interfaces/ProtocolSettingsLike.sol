/**
 * Copyright 2017-2020, bZeroX, LLC. All Rights Reserved.
 * Licensed under the Apache License, Version 2.0.
 */

pragma solidity 0.5.17;
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
