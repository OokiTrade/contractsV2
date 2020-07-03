/**
 * Copyright 2017-2020, bZeroX, LLC. All Rights Reserved.
 * Licensed under the Apache License, Version 2.0.
 */

pragma solidity 0.5.17;

import "../PriceFeeds.sol";
import "../../swaps/ISwapsImpl.sol";

/*
Kovan tokens:
    0xd0A1E359811322d97991E03f863a0C30C2cF029C -> WETH
    0xC4375B7De8af5a38a93548eb8453a498222C4fF2 -> SAI
    0x4F96Fe3b7A6Cf9725f59d353F723c1bDb64CA6Aa -> DAI
*/

contract PriceFeedsTestnets is PriceFeeds {

    enum FeedTypes {
        Kyber,
        Chainlink,
        Custom
    }
    FeedTypes public feedType = FeedTypes.Kyber;

    mapping (address => mapping (address => uint256)) public rates;

    address public constant kyberContract = 0x692f391bCc85cefCe8C237C01e1f636BbD70EA4D; // kovan
    //address public constant kyberContract = 0x818E6FECD516Ecc3849DAf6845e3EC868087B755; // ropsten

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

        if (sourceToken != destToken) {
            if (feedType == FeedTypes.Kyber) {
                if (sourceToken == protocolTokenAddress) {
                    // hack for testnet; only returns price in ETH
                    rate = protocolTokenEthPrice;
                } else if (destToken == protocolTokenAddress) {
                    // hack for testnet; only returns price in ETH
                    rate = SafeMath.div(10**36, protocolTokenEthPrice);
                } else {
                    (bool result, bytes memory data) = kyberContract.staticcall(
                        abi.encodeWithSignature(
                            "getExpectedRate(address,address,uint256)",
                            sourceToken,
                            destToken,
                            10**16
                        )
                    );
                    assembly {
                        switch result
                        case 0 {
                            rate := 0
                        }
                        default {
                            rate := mload(add(data, 32))
                        }
                    }
                }
            } else if (feedType == FeedTypes.Chainlink) {
                return super._queryRate(
                    sourceToken,
                    destToken
                );
            } else {
                rate = rates[sourceToken][destToken];
            }

            precision = _getDecimalPrecision(sourceToken, destToken);
        } else {
            rate = 10**18;
            precision = 10**18;
        }
    }

    function setCustomRate(
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

    function useKyber()
        public
        onlyOwner
    {
        feedType = FeedTypes.Kyber;
    }

    function useChainlink()
        public
        onlyOwner
    {
        feedType = FeedTypes.Chainlink;
    }

    function useCustom()
        public
        onlyOwner
    {
        feedType = FeedTypes.Custom;
    }
}
