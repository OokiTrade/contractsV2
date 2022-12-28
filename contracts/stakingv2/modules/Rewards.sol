/**
 * Copyright 2017-2023, OokiDao. All Rights Reserved.
 * Licensed under the Apache License, Version 2.0.
 */

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

import "./Common.sol";

contract Rewards is Common {
  function initialize(address target) external onlyOwner {
    _setTarget(this.addRewards.selector, target);
    _setTarget(this.getVariableWeights.selector, target);
    _setTarget(this.totalSupplyStored.selector, target);
  }

  // note: anyone can contribute rewards to the contract
  function addRewards(uint256 newOOKI, uint256 newStableCoin) external pausable {
    if (newOOKI != 0 || newStableCoin != 0) {
      _addRewards(newOOKI, newStableCoin);
      if (newOOKI != 0) {
        IERC20(OOKI).transferFrom(msg.sender, address(this), newOOKI);
      }
      if (newStableCoin != 0) {
        curve3Crv.transferFrom(msg.sender, address(this), newStableCoin);
      }
    }
  }

  function _addRewards(uint256 newOOKI, uint256 newStableCoin) internal {
    (vBZRXWeightStored, iOOKIWeightStored, LPTokenWeightStored) = getVariableWeights();

    uint256 totalTokens = totalSupplyStored();
    require(totalTokens != 0, "nothing staked");

    ookiPerTokenStored = (newOOKI * 1e36) / totalTokens + ookiPerTokenStored;

    stableCoinPerTokenStored = (newStableCoin * 1e36) / totalTokens + stableCoinPerTokenStored;

    lastRewardsAddTime = block.timestamp;

    emit AddRewards(msg.sender, newOOKI, newStableCoin);
  }

  function getVariableWeights()
    public
    view
    returns (
      uint256 vBZRXWeight,
      uint256 iOOKIWeight,
      uint256 LPTokenWeight
    )
  {
    uint256 totalVested = vestedBalanceForAmount(_startingVBZRXBalance, 0, block.timestamp);

    vBZRXWeight = ((_startingVBZRXBalance - totalVested) * 1e18) / _startingVBZRXBalance; // overflow not possible

    iOOKIWeight = _calcIOOKIWeight();

    uint256 lpTokenSupply = _totalSupplyPerToken[OOKI_ETH_LP];
    if (lpTokenSupply != 0) {
      // staked LP tokens are assumed to represent the total unstaked supply (circulated supply - staked OOKI)
      uint256 normalizedLPTokenSupply = IERC20(OOKI).totalSupply() - _totalSupplyPerToken[OOKI];

      LPTokenWeight = (normalizedLPTokenSupply * 1e18) / lpTokenSupply;
    }
  }

  function totalSupplyStored() public view returns (uint256 supply) {
    supply = (_totalSupplyPerToken[vBZRX] * vBZRXWeightStored) / 1e17; // OOKI is 10x OOKI

    supply = _totalSupplyPerToken[OOKI] + supply;

    supply = (_totalSupplyPerToken[iOOKI] * iOOKIWeightStored) / 1e50 + supply;

    supply = (_totalSupplyPerToken[OOKI_ETH_LP] * LPTokenWeightStored) / 1e18 + supply;
  }
}
