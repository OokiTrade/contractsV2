/**
 * Copyright 2017-2021, bZeroX, LLC. All Rights Reserved.
 * Licensed under the Apache License, Version 2.0.
 */
/// SPDX-License-Identifier: Apache License, Version 2.0.

pragma solidity >=0.5.0 <0.8.0;

import "../IPriceFeedsExt.sol";
import '@uniswap/v3-periphery/contracts/libraries/OracleLibrary.sol';

contract PriceFeedsExtUniv3Impl is IPriceFeedsExt {
  uint32 public period;
  address public pool;
  address public tokenA;
  address public tokenB;

  constructor(address _pool, uint32 _period, address _tokenA, address _tokenB) {
      pool = _pool;
      period = _period;
      tokenA = _tokenA;
      tokenB = _tokenB;
  }
  event Logger(string name, uint256 amount);
  function latestAnswer() external view override returns (int256){

    int24 timeWeightedAverageTick = OracleLibrary.consult(pool, period);
    uint256 quoteAmount = OracleLibrary.getQuoteAtTick(timeWeightedAverageTick, 1e6, tokenB, tokenA);
    return int256(quoteAmount);
  }

  // function latestAnswer2() external view returns (uint256){

  //   int24 timeWeightedAverageTick = OracleLibrary.consult(pool, period);
  //   uint256 quoteAmount = OracleLibrary.getQuoteAtTick(timeWeightedAverageTick, 1, tokenB, tokenA);
  //   return quoteAmount;
  // }

  // function latestAnswer3() external view returns (uint256){

  //   int24 timeWeightedAverageTick = OracleLibrary.consult(pool, period);
  //   uint256 quoteAmount = OracleLibrary.getQuoteAtTick(timeWeightedAverageTick, 1e6, tokenA, tokenB);
  //   return quoteAmount;
  // }

  // function debug(uint32 _period) public view returns(int24){
  //   return OracleLibrary.consult(pool, _period);
  // }

  // function debug2(int24 tick) public view returns(uint256){
  //   return OracleLibrary.getQuoteAtTick(tick, 1e18, tokenA, tokenB);
  // }

  
  // function debug3(int24 tick, uint128 precision) public view returns(uint256){
  //   return OracleLibrary.getQuoteAtTick(tick, precision, tokenB, tokenA);
  // }

  // function shift(uint256 val) public view returns(int256){
  //   return int256(val * 1e14);
  // }
}
