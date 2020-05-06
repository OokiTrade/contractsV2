/**
 * Copyright 2017-2020, bZeroX, LLC. All Rights Reserved.
 * Licensed under the Apache License, Version 2.0.
 */

pragma solidity 0.5.17;

import "../PriceFeeds.sol";


contract PriceFeeds_local is PriceFeeds {

    mapping (address => mapping (address => uint256)) public rates;

    //uint256 public slippageMultiplier = 100 ether;

    function queryRate(
        address sourceTokenAddress,
        address destTokenAddress)
        public
        view
        returns (uint256 rate, uint256 precision)
    {
        if (sourceTokenAddress == destTokenAddress) {
            rate = 10**18;
            precision = 10**18;
        } else {
            if (rates[sourceTokenAddress][destTokenAddress] != 0) {
                rate = rates[sourceTokenAddress][destTokenAddress];
            } else {
                uint256 sourceToEther = rates[sourceTokenAddress][address(wethToken)] != 0 ?
                    rates[sourceTokenAddress][address(wethToken)] :
                    10**18;
                uint256 etherToDest = rates[address(wethToken)][destTokenAddress] != 0 ?
                    rates[address(wethToken)][destTokenAddress] :
                    10**18;

                rate = sourceToEther.mul(etherToDest).div(10**18);
            }
            precision = _getDecimalPrecision(sourceTokenAddress, destTokenAddress);
        }
    }


    function setRates(
        address sourceTokenAddress,
        address destTokenAddress,
        uint256 rate)
        public
        onlyOwner
    {
        if (sourceTokenAddress != destTokenAddress) {
            rates[sourceTokenAddress][destTokenAddress] = rate;
            rates[destTokenAddress][sourceTokenAddress] = SafeMath.div(10**36, rate);
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