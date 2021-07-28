/**
 * Copyright 2017-2021, bZeroX, LLC. All Rights Reserved.
 * Licensed under the Apache License, Version 2.0.
 */

// SPDX-License-Identifier: APACHE 2.0

pragma solidity >=0.6.0 <0.8.0;


interface IPriceFeedsExt {
  function latestAnswer() external view returns (int256);
}
