/**
 * Copyright 2017-2022, OokiDao. All Rights Reserved.
 * Licensed under the Apache License, Version 2.0.
 */

pragma solidity 0.5.17;


interface IPriceFeedsExt {
  function latestAnswer() external view returns (int256);
}
