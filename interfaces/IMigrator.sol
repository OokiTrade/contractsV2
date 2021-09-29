
/**
 * Copyright 2017-2020, bZeroX, LLC. All Rights Reserved.
 * Licensed under the Apache License, Version 2.0.
 */
// SPDX-License-Identifier: Apache License, Version 2.0.
pragma solidity >=0.5.0 <=0.8.4;
pragma experimental ABIEncoderV2;

interface IMigrator {
    function migrate() external;
}
