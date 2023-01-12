/**
 * Copyright 2017-2023, OokiDao. All Rights Reserved.
 * Licensed under the Apache License, Version 2.0.
 */

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

library LiquidationHelper {
  uint256 internal constant WEI_PRECISION = 10**18;
  uint256 internal constant WEI_PERCENT_PRECISION = 10**20;

  function getLiquidationAmounts(
    uint256 principal,
    uint256 collateral,
    uint256 currentMargin,
    uint256 maintenanceMargin,
    uint256 collateralToLoanRate,
    uint256 incentivePercent
  ) public pure returns (uint256 maxLiquidatable, uint256 maxSeizable) {
    incentivePercent = _getDefaultLiquidationIncentivePercent(incentivePercent);
    if (currentMargin > maintenanceMargin || collateralToLoanRate == 0) {
      return (maxLiquidatable, maxSeizable);
    } else if (currentMargin <= incentivePercent) {
      return (principal, collateral);
    }

    uint256 desiredMargin = maintenanceMargin + 5 ether; // 5 percentage points above maintenance

    // maxLiquidatable = ((1 + desiredMargin)*principal - collateralToLoanRate*collateral) / (desiredMargin - incentivePercent)
    maxLiquidatable = ((desiredMargin + WEI_PERCENT_PRECISION) * principal) / WEI_PERCENT_PRECISION;
    maxLiquidatable -= (collateral * collateralToLoanRate) / WEI_PRECISION;
    maxLiquidatable = ((maxLiquidatable * WEI_PERCENT_PRECISION) / desiredMargin) - incentivePercent;
    if (maxLiquidatable > principal) {
      maxLiquidatable = principal;
    }

    // maxSeizable = maxLiquidatable * (1 + incentivePercent) / collateralToLoanRate
    maxSeizable = maxLiquidatable * (incentivePercent + WEI_PERCENT_PRECISION);
    maxSeizable = maxSeizable / collateralToLoanRate / 100;
    if (maxSeizable > collateral) {
      maxSeizable = collateral;
    }

    return (maxLiquidatable, maxSeizable);
  }

  function _getDefaultLiquidationIncentivePercent(uint256 incentivePercent) internal pure returns (uint256) {
    return (incentivePercent == 0) ? 7e18 : incentivePercent;
  }
}
