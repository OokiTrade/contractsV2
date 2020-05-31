/**
 * Copyright 2017-2020, bZeroX, LLC. All Rights Reserved.
 * Licensed under the Apache License, Version 2.0.
 */

pragma solidity 0.5.17;


//import "../openzeppelin/Math.sol";
import "../openzeppelin/SafeMath.sol";
import "../openzeppelin/Ownable.sol";
import "../interfaces/IERC20.sol";
import "../interfaces/ILoanPool.sol";
import "../core/Constants.sol";


interface IPriceFeedsExt {
  function latestAnswer() external view returns (int256);
  /*function latestTimestamp() external view returns (uint256);
  function latestRound() external view returns (uint256);
  function getAnswer(uint256 roundId) external view returns (int256);
  function getTimestamp(uint256 roundId) external view returns (uint256);

  event AnswerUpdated(int256 indexed current, uint256 indexed roundId, uint256 timestamp);
  event NewRound(uint256 indexed roundId, address indexed startedBy);*/
}

contract PriceFeeds is Constants, Ownable {
    using SafeMath for uint256;

    mapping (address => IPriceFeedsExt) public pricesFeeds;     // token => pricefeed

    mapping (address => address) public loanPools;              // loanPool => underlying

    // decimals of supported tokens
    mapping (address => uint256) public decimals;

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
        uint256 sourcePoolRate;
        (sourceToken,,sourcePoolRate) = _underlyingConversion(sourceToken, 0);

        uint256 destPoolRate;
        (destToken,,destPoolRate) = _underlyingConversion(destToken, 0);

        (rate, precision) = _queryRate(
            sourceToken,
            destToken
        );

        if (sourcePoolRate != 0) {
            rate = rate
                .mul(10**18)
                .div(sourcePoolRate);
        }
        if (destPoolRate != 0) {
            rate = rate
                .mul(10**18)
                .div(destPoolRate);
        }
    }

    function _queryRate(
        address sourceToken,
        address destToken)
        internal
        view
        returns (uint256 rate, uint256 precision)
    {
        if (sourceToken != destToken) {
            uint256 sourceRate;
            if (sourceToken != address(wethToken)) {
                IPriceFeedsExt _sourceFeed = pricesFeeds[sourceToken];
                require(address(_sourceFeed) != address(0), "unsupported src feed");
                sourceRate = uint256(_sourceFeed.latestAnswer());
                require(sourceRate != 0 && (sourceRate >> 128) == 0, "price error");
            } else {
                sourceRate = 10**18;
            }

            uint256 destRate;
            if (destToken != address(wethToken)) {
                IPriceFeedsExt _destFeed = pricesFeeds[destToken];
                require(address(_destFeed) != address(0), "unsupported dst feed");
                destRate = uint256(_destFeed.latestAnswer());
                require(destRate != 0 && (destRate >> 128) == 0, "price error");
            } else {
                destRate = 10**18;
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

    function checkPriceDisagreement(
        address sourceToken,
        address destToken,
        uint256 sourceAmount,
        uint256 destAmount,
        uint256 maxSlippage)
        public
        view
    {
        (sourceToken, sourceAmount,) = _underlyingConversion(sourceToken, sourceAmount);
        (destToken, destAmount,) = _underlyingConversion(destToken, destAmount);

        (uint256 rate, uint256 precision) = _queryRate(
            sourceToken,
            destToken
        );

        uint256 actualRate = destAmount
            .mul(precision)
            .div(sourceAmount);

        uint256 spreadValue = actualRate > rate ?
            actualRate - rate :
            rate - actualRate;

        if (spreadValue != 0) {
            spreadValue = spreadValue
                .mul(10**20)
                .div(actualRate);

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
        (tokenAddress, amount,) = _underlyingConversion(tokenAddress, amount);

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
        uint256 collateralPoolRate;
        (collateralToken, collateralAmount, collateralPoolRate) = _underlyingConversion(collateralToken, collateralAmount);

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

        if (maxDrawdown != 0 && collateralPoolRate != 0) {
            maxDrawdown = maxDrawdown
                .mul(10**18)
                .div(collateralPoolRate);
        }
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
        //(loanToken, loanAmount,) = _underlyingConversion(loanToken, loanAmount); <-- no support for loaning iTokens
        (collateralToken, collateralAmount,) = _underlyingConversion(collateralToken, collateralAmount);

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
        /*uint256 loanPoolRate;
        (loanToken,,loanPoolRate) = _underlyingConversion(loanToken, 0);*/

        uint256 collateralPoolRate;
        (collateralToken,,collateralPoolRate) = _underlyingConversion(collateralToken, 0);

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

        /*if (loanPoolRate != 0) {
            collateralToLoanRate = collateralToLoanRate
                .mul(10**18)
                .div(loanPoolRate);
        }*/
        if (collateralPoolRate != 0) {
            collateralToLoanRate = collateralToLoanRate
                .mul(10**18)
                .div(collateralPoolRate);
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

    /*
    * Owner functions
    */

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

    function setLoanPool(
        address[] calldata pools,
        address[] calldata assets)
        external
        onlyOwner
    {
        require(pools.length == assets.length, "count mismatch");

        for (uint256 i = 0; i < pools.length; i++) {
            loanPools[pools[i]] = assets[i];
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

    /*
    * Internal functions
    */

    function _underlyingConversion(
        address asset,
        uint256 assetAmount)
        internal
        view
        returns (address, uint256, uint256)
    {
        uint256 rate;
        address _underlying = loanPools[asset];
        if (_underlying != address(0)) {
            rate = ILoanPool(asset).tokenPrice();
            if (assetAmount != 0) {
                assetAmount = assetAmount
                    .mul(rate)
                    .div(10**18);
            }
            asset = _underlying;
        }
        return (asset, assetAmount, rate);
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
}
