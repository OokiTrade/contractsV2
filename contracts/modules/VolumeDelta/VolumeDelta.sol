/**
 * Copyright 2017-2022, OokiDao. All Rights Reserved.
 * Licensed under the Apache License, Version 2.0.
 */

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

import '../../core/State.sol';
import '../../utils/VolumeTracker.sol';
import '../../utils/TickMathV1.sol';

contract VolumeDelta is State {
  using VolumeTracker for VolumeTracker.Observation[65535];

  constructor(
    IWeth wethtoken,
    address usdc,
    address bzrx,
    address vbzrx,
    address ooki
  ) Constants(wethtoken, usdc, bzrx, vbzrx, ooki) {}

  function initialize(address target) external onlyOwner {
    _setTarget(this.retrieveTradedVolume.selector, target);
    _setTarget(this.adjustCardinality.selector, target);
  }

  /*restricted by the last timestamp of the observations. 
    If periodEnd extends past the last time period an error will be thrown. 
    for example, this means if the earliest trade recorded < 30 days ago OR > user cardinality of trades occurred in last 30 days it will fail.
    Cardinality is initially set at 256 which means up to 256 days of data can be stored as each index slot is dedicated for a rolling day. 
    the time periods are not synchronised
    */
  function retrieveTradedVolume(
    address user,
    uint32 periodStart,
    uint32 periodEnd
  ) public view returns (uint256) {
    require(volumeTradedCardinality[user] > 0, 'unused');
    if (periodStart >= block.timestamp) return 0;
    if (periodStart >= periodEnd) return 0;
    uint32 ts = uint32(block.timestamp);
    if (block.timestamp < periodEnd) periodEnd = ts;
    return
      volumeTradedObservations[user].volumeDelta(
        ts,
        [ts - periodStart, ts - periodEnd],
        volumeLastIdx[user],
        volumeTradedCardinality[user]
      );
  }

  //sets new cardinality. WARNING: CAN ONLY BE INCREASED. as it is increased, gas costs for binary searches increase. Use with caution
  function adjustCardinality(uint16 cardinality) public {
    require(cardinality > volumeTradedCardinality[msg.sender], 'too low');
    volumeTradedCardinality[msg.sender] = cardinality;
  }
}
