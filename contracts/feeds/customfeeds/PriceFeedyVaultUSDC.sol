/**
 * Copyright 2017-2023, OokiDao. All Rights Reserved.
 * Licensed under the Apache License, Version 2.0.
 */

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

import "interfaces/IPriceFeeds.sol";
import "contracts/interfaces/IyVault.sol";

contract PriceFeedyVaultUSDC {
  IPriceFeeds internal constant _PRICEFEED = IPriceFeeds(0x5AbC9e082Bf6e4F930Bbc79742DA3f6259c4aD1d);
  IyVault public constant VAULT = IyVault(0xa354F35829Ae975e850e23e9615b11Da1B3dC4DE);
  address internal constant _USDC = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
  address internal constant _ETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;

  function latestAnswer() external view returns (int256) {
    return int256(_PRICEFEED.queryReturn(_USDC, _ETH, VAULT.pricePerShare()));
  }
}
