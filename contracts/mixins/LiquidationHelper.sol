/**
 * Copyright 2017-2022, OokiDao. All Rights Reserved.
 * Licensed under the Apache License, Version 2.0.
 */

pragma solidity 0.5.17;

import "@openzeppelin-2.5.0/math/SafeMath.sol";

library LiquidationHelper {
    using SafeMath for uint256;
    uint256 internal constant WEI_PRECISION = 10**18;
    uint256 internal constant WEI_PERCENT_PRECISION = 10**20;

    function _getLiquidationAmounts(
        uint256 principal,
        uint256 collateral,
        uint256 currentMargin,
        uint256 maintenanceMargin,
        uint256 collateralToLoanRate,
        uint256 incentivePercent)
        public
        pure
        returns (uint256 maxLiquidatable, uint256 maxSeizable)
    {
        if (currentMargin > maintenanceMargin || collateralToLoanRate == 0) {
            return (maxLiquidatable, maxSeizable);
        } else if (currentMargin <= incentivePercent) {
            return (principal, collateral);
        }

        uint256 desiredMargin = maintenanceMargin.add(5 ether); // 5 percentage points above maintenance

        // maxLiquidatable = ((1 + desiredMargin)*principal - collateralToLoanRate*collateral) / (desiredMargin - incentivePercent)
        maxLiquidatable = desiredMargin
            .add(WEI_PERCENT_PRECISION)
            .mul(principal)
            .div(WEI_PERCENT_PRECISION);
        maxLiquidatable = maxLiquidatable
            .sub(
                collateral
                    .mul(collateralToLoanRate)
                    .div(WEI_PRECISION)
            );
        maxLiquidatable = maxLiquidatable
            .mul(WEI_PERCENT_PRECISION)
            .div(
                desiredMargin
                    .sub(incentivePercent)
            );
        if (maxLiquidatable > principal) {
            maxLiquidatable = principal;
        }

        // maxSeizable = maxLiquidatable * (1 + incentivePercent) / collateralToLoanRate
        maxSeizable = maxLiquidatable
            .mul(
                incentivePercent
                    .add(WEI_PERCENT_PRECISION)
            );
        maxSeizable = maxSeizable
            .div(collateralToLoanRate)
            .div(100);
        if (maxSeizable > collateral) {
            maxSeizable = collateral;
        }

        return (maxLiquidatable, maxSeizable);
    }
}
