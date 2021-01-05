/**
 * Copyright 2017-2021, bZeroX, LLC. All Rights Reserved.
 * Licensed under the Apache License, Version 2.0.
 */

pragma solidity 0.5.17;

import "../../../openzeppelin/SafeMath.sol";


contract LogicMock {
    using SafeMath for uint256;

    uint256 public constant WEI_PERCENT_PRECISION = 10**20;

    uint256 public baseRate;
    uint256 public rateMultiplier;
    uint256 public lowUtilBaseRate;
    uint256 public lowUtilRateMultiplier;

    uint256 public targetLevel;
    uint256 public kinkLevel;
    uint256 public maxScaleRate;

    function tmpSetDemandCurve(
        uint256 _baseRate,
        uint256 _rateMultiplier,
        uint256 _lowUtilBaseRate,
        uint256 _lowUtilRateMultiplier,
        uint256 _targetLevel,
        uint256 _kinkLevel,
        uint256 _maxScaleRate)
        public
    {
        require(_rateMultiplier.add(_baseRate) <= WEI_PERCENT_PRECISION, "curve params too high");
        require(_lowUtilRateMultiplier.add(_lowUtilBaseRate) <= WEI_PERCENT_PRECISION, "curve params too high");

        require(_targetLevel <= WEI_PERCENT_PRECISION && _kinkLevel <= WEI_PERCENT_PRECISION, "levels too high");

        baseRate = _baseRate;
        rateMultiplier = _rateMultiplier;
        lowUtilBaseRate = _lowUtilBaseRate;
        lowUtilRateMultiplier = _lowUtilRateMultiplier;

        targetLevel = _targetLevel; // 80 ether
        kinkLevel = _kinkLevel; // 90 ether
        maxScaleRate = _maxScaleRate; // 100 ether
    }

    function tmpNBI(
        uint256 utilRate)
        public
        view
        returns (uint256 nextRate)
    {
        uint256 thisMinRate;
        uint256 thisMaxRate;
        uint256 thisBaseRate = baseRate;
        uint256 thisRateMultiplier = rateMultiplier;
        uint256 thisTargetLevel = targetLevel;
        uint256 thisKinkLevel = kinkLevel;
        uint256 thisMaxScaleRate = maxScaleRate;

        if (utilRate < thisTargetLevel) {
            // target targetLevel utilization when utilization is under targetLevel
            utilRate = thisTargetLevel;
        }

        if (utilRate > thisKinkLevel) {
            // scale rate proportionally up to 100%
            uint256 thisMaxRange = WEI_PERCENT_PRECISION - thisKinkLevel; // will not overflow

            utilRate -= thisKinkLevel;
            if (utilRate > thisMaxRange)
                utilRate = thisMaxRange;

            thisMaxRate = thisRateMultiplier
                .add(thisBaseRate)
                .mul(thisKinkLevel)
                .div(WEI_PERCENT_PRECISION);

            nextRate = utilRate
                .mul(SafeMath.sub(thisMaxScaleRate, thisMaxRate))
                .div(thisMaxRange)
                .add(thisMaxRate);
        } else {
            nextRate = utilRate
                .mul(thisRateMultiplier)
                .div(WEI_PERCENT_PRECISION)
                .add(thisBaseRate);

            thisMinRate = thisBaseRate;
            thisMaxRate = thisRateMultiplier
                .add(thisBaseRate);

            if (nextRate < thisMinRate)
                nextRate = thisMinRate;
            else if (nextRate > thisMaxRate)
                nextRate = thisMaxRate;
        }
    }
}
