/**
 * Copyright 2017-2020, bZeroX, LLC. All Rights Reserved.
 * Licensed under the Apache License, Version 2.0.
 */

pragma solidity 0.5.17;

import "../openzeppelin/SafeMath.sol";
import "../openzeppelin/Ownable.sol";
import "../interfaces/IERC20.sol";
import "../core/Constants.sol";


interface IPriceFeedsExt {
  function latestAnswer() external view returns (int256);
}

contract PriceFeeds is Constants, Ownable {
    using SafeMath for uint256;

    event GlobalPricingPaused(
        address indexed sender,
        bool indexed isPaused
    );

    mapping (address => IPriceFeedsExt) public pricesFeeds;     // token => pricefeed
    mapping (address => uint256) public decimals;               // decimals of supported tokens

    uint256 public protocolTokenEthPrice = 0.0002 ether;

    bool public globalPricingPaused = false;

    constructor()
        public
    {
        // set decimals for ether
        decimals[address(0)] = 18;
        decimals[address(wethToken)] = 18;
    }

    function queryRate(
        address sourceToken,
        address destToken)
        public
        view
        returns (uint256 rate, uint256 precision)
    {
        return _queryRate(
            sourceToken,
            destToken
        );
    }

    function queryPrecision(
        address sourceToken,
        address destToken)
        public
        view
        returns (uint256)
    {
        return sourceToken != destToken ?
            _getDecimalPrecision(sourceToken, destToken) :
            10**18;
    }

    //// NOTE: This function returns 0 during a pause, rather than a revert. Ensure calling contracts handle correctly. ///
    function queryReturn(
        address sourceToken,
        address destToken,
        uint256 sourceAmount)
        public
        view
        returns (uint256 destAmount)
    {
        (uint256 rate, uint256 precision) = _queryRate(
            sourceToken,
            destToken
        );

        destAmount = sourceAmount
            .mul(rate)
            .div(precision);
    }

    function checkPriceDisagreement(
        address sourceToken,
        address destToken,
        uint256 sourceAmount,
        uint256 destAmount,
        uint256 maxSlippage)
        public
        view
        returns (uint256 sourceToDestSwapRate)
    {
        (uint256 rate, uint256 precision) = _queryRate(
            sourceToken,
            destToken
        );

        sourceToDestSwapRate = destAmount
            .mul(precision)
            .div(sourceAmount);

        uint256 spreadValue = sourceToDestSwapRate > rate ?
            sourceToDestSwapRate - rate :
            rate - sourceToDestSwapRate;

        if (spreadValue != 0) {
            spreadValue = spreadValue
                .mul(10**20)
                .div(sourceToDestSwapRate);

            require(
                spreadValue <= maxSlippage,
                "price disagreement"
            );
        }
    }

    function amountInEth(
        address tokenAddress,
        uint256 amount)
        public
        view
        returns (uint256 ethAmount)
    {
        if (tokenAddress == address(wethToken)) {
            ethAmount = amount;
        } else {
            (uint toEthRate, uint256 toEthPrecision) = queryRate(
                tokenAddress,
                address(wethToken)
            );
            ethAmount = amount
                .mul(toEthRate)
                .div(toEthPrecision);
        }
    }

    function getMaxDrawdown(
        address loanToken,
        address collateralToken,
        uint256 loanAmount,
        uint256 collateralAmount,
        uint256 margin)
        public
        view
        returns (uint256 maxDrawdown)
    {
        uint256 loanToCollateralAmount;
        if (collateralToken == loanToken) {
            loanToCollateralAmount = loanAmount;
        } else {
            (uint256 rate, uint256 precision) = queryRate(
                loanToken,
                collateralToken
            );
            loanToCollateralAmount = loanAmount
                .mul(rate)
                .div(precision);
        }

        uint256 combined = loanToCollateralAmount
            .add(
                loanToCollateralAmount
                    .mul(margin)
                    .div(10**20)
                );

        maxDrawdown = collateralAmount > combined ?
            collateralAmount - combined :
            0;
    }

    function getCurrentMarginAndCollateralSize(
        address loanToken,
        address collateralToken,
        uint256 loanAmount,
        uint256 collateralAmount)
        public
        view
        returns (uint256 currentMargin, uint256 collateralInEthAmount)
    {
        (currentMargin,) = getCurrentMargin(
            loanToken,
            collateralToken,
            loanAmount,
            collateralAmount
        );

        collateralInEthAmount = amountInEth(
            collateralToken,
            collateralAmount
        );
    }

    function getCurrentMargin(
        address loanToken,
        address collateralToken,
        uint256 loanAmount,
        uint256 collateralAmount)
        public
        view
        returns (uint256 currentMargin, uint256 collateralToLoanRate)
    {
        uint256 collateralToLoanAmount;
        if (collateralToken == loanToken) {
            collateralToLoanAmount = collateralAmount;
            collateralToLoanRate = 10**18;
        } else {
            uint256 collateralToLoanPrecision;
            (collateralToLoanRate, collateralToLoanPrecision) = queryRate(
                collateralToken,
                loanToken
            );

            collateralToLoanRate = collateralToLoanRate
                .mul(10**18)
                .div(collateralToLoanPrecision);

            collateralToLoanAmount = collateralAmount
                .mul(collateralToLoanRate)
                .div(10**18);
        }

        if (loanAmount != 0 && collateralToLoanAmount >= loanAmount) {
            return (
                collateralToLoanAmount
                    .sub(loanAmount)
                    .mul(10**20)
                    .div(loanAmount),
                collateralToLoanRate
            );
        } else {
            return (
                0,
                collateralToLoanRate
            );
        }
    }

    function shouldLiquidate(
        address loanToken,
        address collateralToken,
        uint256 loanAmount,
        uint256 collateralAmount,
        uint256 maintenanceMargin)
        public
        view
        returns (bool)
    {
        (uint256 currentMargin,) = getCurrentMargin(
            loanToken,
            collateralToken,
            loanAmount,
            collateralAmount
        );

        return currentMargin <= maintenanceMargin;
    }

    function getFastGasPrice(
        address payToken)
        external
        view
        returns (uint256)
    {
        uint256 gasPrice = _getFastGasPrice();
        if (payToken != address(wethToken) && payToken != address(0)) {
            (uint256 rate, uint256 precision) = _queryRate(
                payToken,
                address(wethToken)
            );
            gasPrice = gasPrice
                .mul(rate)
                .div(precision);
        }
        return gasPrice;
    }


    /*
    * Owner functions
    */

    function setProtocolTokenEthPrice(
        uint256 newPrice)
        external
        onlyOwner
    {
        require(newPrice != 0, "invalid price");
        protocolTokenEthPrice = newPrice;
    }

    function setPriceFeed(
        address[] calldata tokens,
        IPriceFeedsExt[] calldata feeds)
        external
        onlyOwner
    {
        require(tokens.length == feeds.length, "count mismatch");

        for (uint256 i = 0; i < tokens.length; i++) {
            pricesFeeds[tokens[i]] = feeds[i];
        }
    }

    function setDecimals(
        IERC20[] calldata tokens)
        external
        onlyOwner
    {
        for (uint256 i = 0; i < tokens.length; i++) {
            decimals[address(tokens[i])] = tokens[i].decimals();
        }
    }

    function setGlobalPricingPaused(
        bool isPaused)
        external
        onlyOwner
    {
        if (globalPricingPaused != isPaused) {
            globalPricingPaused = isPaused;

            emit GlobalPricingPaused(
                msg.sender,
                isPaused
            );
        }
    }

    /*
    * Internal functions
    */

    function _queryRate(
        address sourceToken,
        address destToken)
        internal
        view
        returns (uint256 rate, uint256 precision)
    {
        require(!globalPricingPaused, "pricing is paused");

        if (sourceToken != destToken) {
            uint256 sourceRate;
            if (sourceToken != address(wethToken) && sourceToken != protocolTokenAddress) {
                IPriceFeedsExt _sourceFeed = pricesFeeds[sourceToken];
                require(address(_sourceFeed) != address(0), "unsupported src feed");
                sourceRate = uint256(_sourceFeed.latestAnswer());
                require(sourceRate != 0 && (sourceRate >> 128) == 0, "price error");
            } else {
                sourceRate = sourceToken == protocolTokenAddress ?
                    protocolTokenEthPrice :
                    10**18;
            }

            uint256 destRate;
            if (destToken != address(wethToken) && destToken != protocolTokenAddress) {
                IPriceFeedsExt _destFeed = pricesFeeds[destToken];
                require(address(_destFeed) != address(0), "unsupported dst feed");
                destRate = uint256(_destFeed.latestAnswer());
                require(destRate != 0 && (destRate >> 128) == 0, "price error");
            } else {
                destRate = destToken == protocolTokenAddress ?
                    protocolTokenEthPrice :
                    10**18;
            }

            rate = sourceRate
                .mul(10**18)
                .div(destRate);

            precision = _getDecimalPrecision(sourceToken, destToken);
        } else {
            rate = 10**18;
            precision = 10**18;
        }
    }

    function _getDecimalPrecision(
        address sourceToken,
        address destToken)
        internal
        view
        returns(uint256)
    {
        if (sourceToken == destToken) {
            return 10**18;
        } else {
            uint256 sourceTokenDecimals = decimals[sourceToken];
            if (sourceTokenDecimals == 0)
                sourceTokenDecimals = IERC20(sourceToken).decimals();

            uint256 destTokenDecimals = decimals[destToken];
            if (destTokenDecimals == 0)
                destTokenDecimals = IERC20(destToken).decimals();

            if (destTokenDecimals >= sourceTokenDecimals)
                return 10**(SafeMath.sub(18, destTokenDecimals-sourceTokenDecimals));
            else
                return 10**(SafeMath.add(18, sourceTokenDecimals-destTokenDecimals));
        }
    }

    function _getFastGasPrice()
        internal
        view
        returns (uint256 gasPrice)
    {
        gasPrice = uint256(pricesFeeds[address(1)].latestAnswer())
            .mul(10**9);
        require(gasPrice != 0 && (gasPrice >> 128) == 0, "gas price error");
    }
}
