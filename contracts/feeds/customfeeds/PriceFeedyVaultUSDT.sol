/**
 * Copyright 2017-2023, OokiDao. All Rights Reserved.
 * Licensed under the Apache License, Version 2.0.
 */

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

import "../../../interfaces/IPriceFeeds.sol";
import "../../interfaces/IyVault.sol";

contract PriceFeedyVaultUSDT {
  IPriceFeeds internal constant _PRICEFEED = IPriceFeeds(0x5AbC9e082Bf6e4F930Bbc79742DA3f6259c4aD1d);
  IyVault public constant VAULT = IyVault(0x3B27F92C0e212C671EA351827EDF93DB27cc0c65);
  address internal constant _USDT = 0xdAC17F958D2ee523a2206206994597C13D831ec7;
  address internal constant _ETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;

  function latestAnswer() external view returns (int256) {
    return int256(_PRICEFEED.queryReturn(_USDT, _ETH, VAULT.pricePerShare()));
  }
}
