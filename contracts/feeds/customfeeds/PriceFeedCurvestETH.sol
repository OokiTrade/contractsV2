/**
 * Copyright 2017-2023, OokiDao. All Rights Reserved.
 * Licensed under the Apache License, Version 2.0.
 */

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

import "../../interfaces/curve/ICurvePool.sol";
import "contracts/feeds/IPriceFeedsExt.sol";

contract PriceFeedCurvestETH {
  ICurvePool public constant POOL = ICurvePool(0xDC24316b9AE028F1497c275EB9192a3Ea0f67022);
  IPriceFeedsExt public constant STETHPRICEFEED = IPriceFeedsExt(0xCfE54B5cD566aB89272946F602D76Ea879CAb4a8);
  IPriceFeedsExt public constant ETHPRICEFEED = IPriceFeedsExt(0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419);

  function latestAnswer() external view returns (int256) {
    return (int256(POOL.get_virtual_price()) * STETHPRICEFEED.latestAnswer()) / ETHPRICEFEED.latestAnswer();
  }
}
