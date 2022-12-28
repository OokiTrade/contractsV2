/**
 * Copyright 2017-2023, OokiDao. All Rights Reserved.
 * Licensed under the Apache License, Version 2.0.
 */

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

import '../../../interfaces/IUniv3Twap.sol';
import './IFeedFactory.sol';
import '@openzeppelin-4.7.0/token/ERC20/extensions/IERC20Metadata.sol';

contract FactoryFeed {
  address public immutable TWAP;

  address public immutable feedFactory;
  address public immutable base;
  address public immutable quote;
  address public immutable pool;
  uint128 public immutable baseAmount;
  uint256 public immutable offset;

  constructor(address baseToken, address quoteToken, address poolAddress, address twapSource, uint256 decimalOffset) {
    TWAP = twapSource;
    feedFactory = msg.sender;
    base = baseToken;
    quote = quoteToken;
    pool = poolAddress;
    offset = decimalOffset;
    require(IERC20Metadata(base).decimals() <= 18, 'too high of decimals');
    baseAmount = uint128(10 ** IERC20Metadata(base).decimals());
  }

  function _getTWAPSpecs() internal view returns (IUniv3Twap.V3Specs memory specs) {
    specs = IFeedFactory(feedFactory).specs();
    specs.token0 = base;
    specs.token1 = quote;
    specs.pool = pool;
    specs.baseAmount = baseAmount;
  }

  function latestAnswer() external view returns (int256) {
    return int256(IUniv3Twap(TWAP).twapValue(_getTWAPSpecs()) * offset);
  }
}
