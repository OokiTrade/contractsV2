/**
 * Copyright 2017-2020, bZeroX, LLC. All Rights Reserved.
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
        require(!globalPricingPaused, "pricing is paused");

        if (sourceToken == destToken) {
            rate = 10**18;
            precision = 10**18;
        } else {
            if (sourceToken == protocolTokenAddress) {
                // hack for testnet; only returns price in ETH
                rate = protocolTokenEthPrice;
            } else if (destToken == protocolTokenAddress) {
                // hack for testnet; only returns price in ETH
                rate = SafeMath.div(10**36, protocolTokenEthPrice);
            } else {
                if (rates[sourceToken][destToken] != 0) {
                    rate = rates[sourceToken][destToken];
                } else {
                    uint256 sourceToEther = rates[sourceToken][address(wethToken)] != 0 ?
                        rates[sourceToken][address(wethToken)] :
                        10**18;
                    uint256 etherToDest = rates[address(wethToken)][destToken] != 0 ?
                        rates[address(wethToken)][destToken] :
                        10**18;

                    rate = sourceToEther.mul(etherToDest).div(10**18);
                }
            }
            precision = _getDecimalPrecision(sourceToken, destToken);
        }
    }


    function setRates(
        address sourceToken,
        address destToken,
        uint256 rate)
        public
        onlyOwner
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