/**
 * Copyright 2017-2022, OokiDao. All Rights Reserved.
 * Licensed under the Apache License, Version 2.0.
 */

pragma solidity 0.5.17;

import "../PriceFeeds.sol";


contract PriceFeedsLocal is PriceFeeds {

    mapping (address => mapping (address => uint256)) public rates;

    //uint256 public slippageMultiplier = 100 ether;

    function _getFastGasPrice()
        internal
        view
        returns (uint256 gasPrice)
    {
        return 10 * 10**9;
    }

    function _queryRate(
        address sourceToken,
        address destToken)
        internal
        view
        returns (uint256 rate, uint256 precision)
    {
        if (sourceToken == destToken) {
            rate = WEI_PRECISION;
            precision = WEI_PRECISION;
        } else {
            if (rates[sourceToken][destToken] != 0) {
                rate = rates[sourceToken][destToken];
            } else {
                uint256 sourceToEther = rates[sourceToken][address(wethToken)] != 0 ?
                    rates[sourceToken][address(wethToken)] :
                    WEI_PRECISION;
                uint256 etherToDest = rates[address(wethToken)][destToken] != 0 ?
                    rates[address(wethToken)][destToken] :
                    WEI_PRECISION;

                rate = sourceToEther.mul(etherToDest).div(WEI_PRECISION);
            }
            precision = _getDecimalPrecision(sourceToken, destToken);
        }
    }


    function setRates(
        address sourceToken,
        address destToken,
        uint256 rate)
        public
    {
        if (sourceToken != destToken) {
            rates[sourceToken][destToken] = rate;
            rates[destToken][sourceToken] = SafeMath.div(10**36, rate);
        }
    }

    /*function setSlippageMultiplier(
        uint256 _slippageMultiplier)
        public
        onlyOwner
    {
        require (slippageMultiplier != _slippageMultiplier && _slippageMultiplier <= 100 ether);
        slippageMultiplier = _slippageMultiplier;
    }*/
}