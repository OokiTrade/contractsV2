/**
 * Copyright 2017-2023, OokiDao. All Rights Reserved.
 * Licensed under the Apache-2.0
 */

pragma solidity >=0.5.17 <0.9.0;
pragma abicoder v2;

import "@openzeppelin-4.9.3/access/IAccessControl.sol";

// SPDX-License-Identifier: Apache-2.0

interface IGuardian is IAccessControl {

    function GUARDIAN_ROLE() external view returns(bytes32);
    function TIMELOCK_ROLE() external view returns(bytes32);

}