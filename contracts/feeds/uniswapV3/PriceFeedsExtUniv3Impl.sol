/**
 * Copyright 2017-2021, bZeroX, LLC. All Rights Reserved.
 * Licensed under the Apache License, Version 2.0.
 */
/// SPDX-License-Identifier: Apache License, Version 2.0.

pragma solidity >=0.5.0 <0.8.0;

import "../IPriceFeedsExt.sol";
import '@uniswap/v3-periphery/contracts/libraries/OracleLibrary.sol';
import "@openzeppelin-3.4.0/token/ERC20/ERC20.sol";
contract PriceFeedsExtUniv3Impl is IPriceFeedsExt {
  uint32 public period;
  uint128 public baseAmount;
  address public pool;
  address public token0;
  address public token1;
  constructor(address _pool, uint32 _period, address _tokenA, address _tokenB) {
      period = _period;
	  address token0Address = _tokenA < _tokenB ? _tokenA : _tokenB;
      baseAmount = uint128(10**(ERC20(token0Address).decimals())); //set to 10**token0Decimals
      pool = _pool;
	  (token0, token1) = (_tokenA, _tokenB);
      
  }

  function latestAnswer() public view override returns (int256){
    int24 timeWeightedAverageTick = OracleLibrary.consult(pool, period);
    uint256 quoteAmount = OracleLibrary.getQuoteAtTick(timeWeightedAverageTick, baseAmount, token0, token1);
    return int256(quoteAmount);
  }
}
