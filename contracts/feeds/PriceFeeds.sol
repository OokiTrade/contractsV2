/**
 * Copyright 2017-2020, bZeroX, LLC. All Rights Reserved.
 * Licensed under the Apache License, Version 2.0.
 */

pragma solidity 0.5.17;


//import "../openzeppelin/Math.sol";
import "../openzeppelin/SafeMath.sol";
import "../openzeppelin/Ownable.sol";
import "../interfaces/IERC20.sol";
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

    mapping (address => IPriceFeedsExt) public pricesFeeds; // token_address => pricefeed_address

    // decimals of supported tokens
    mapping (address => uint256) public decimals;

    uint256 public maxTradeSize = 1500 ether;

    constructor()
        public
    {
        // set decimals for ether
        decimals[address(0)] = 18;
        decimals[address(0x00eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee)] = 18;
        decimals[address(wethToken)] = 18;
    }

    function queryRate(
        address sourceTokenAddress,
        address destTokenAddress)
        public
        view
        returns (uint256 rate, uint256 precision)
    {
        if (sourceTokenAddress != destTokenAddress) {
            if (destTokenAddress == address(0x00eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee)) {
                destTokenAddress = address(wethToken);
            } else if (sourceTokenAddress == address(0x00eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee)) {
                sourceTokenAddress = address(wethToken);
            }

            uint256 sourceRate;
            if (sourceTokenAddress != address(wethToken)) {
                IPriceFeedsExt _sourceFeed = pricesFeeds[sourceTokenAddress];
                require(address(_sourceFeed) != address(0), "unsupported src feed");
                sourceRate = uint256(_sourceFeed.latestAnswer());
                require(sourceRate != 0 && (sourceRate >> 128) == 0, "price error");
            } else {
                sourceRate = 10**18;
            }

            uint256 destRate;
            if (destTokenAddress != address(wethToken)) {
                IPriceFeedsExt _destFeed = pricesFeeds[destTokenAddress];
                require(address(_destFeed) != address(0), "unsupported dst feed");
                destRate = uint256(_destFeed.latestAnswer());
                require(destRate != 0 && (destRate >> 128) == 0, "price error");
            } else {
                destRate = 10**18;
            }

            rate = sourceRate
                .mul(10**18)
                .div(destRate);

            precision = _getDecimalPrecision(sourceTokenAddress, destTokenAddress);
        } else {
            rate = 10**18;
            precision = 10**18;
        }
    }

    function checkPriceDisagreement(
        address sourceTokenAddress,
        address destTokenAddress,
        uint256 sourceTokenAmount,
        uint256 destTokenAmount,
        uint256 maxSlippage)
        public
        view
    {
        (uint256 rate, uint256 precision) = queryRate(
            sourceTokenAddress,
            destTokenAddress
        );

        uint256 actualRate = destTokenAmount
            .mul(precision)
            .div(sourceTokenAmount);

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

    function checkMaxTradeSize(
        address tokenAddress,
        uint256 amount)
        public
        view
    {
        require(amountInEth(tokenAddress, amount) <= maxTradeSize, "trade too large");
    }

    function setDecimalsBatch(
        IERC20[] memory tokens)
        public
    {
        for (uint256 i = 0; i < tokens.length; i++) {
            decimals[address(tokens[i])] = tokens[i].decimals();
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
        returns (uint256)
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

        return collateralAmount > combined ?
            collateralAmount - combined :
            0;
    }

    /*function getPositionOffset(
        address loanToken,
        address collateralToken,
        uint256 loanAmount,
        uint256 collateralAmount,
        uint256 minInitialMargin)
        public
        view
        returns (bool isPositive, uint256 loanOffsetAmount, uint256 collateralOffsetAmount)
    {
        uint256 collateralToLoanAmount;
        uint256 collateralToLoanRatePrecise;
        if (collateralToken == loanToken) {
            collateralToLoanAmount = collateralAmount;
            collateralToLoanRatePrecise = 10**18;
        } else {
            uint256 precision;
            (collateralToLoanRatePrecise, precision) = queryRate(
                collateralToken,
                loanToken
            );
            collateralToLoanRatePrecise = collateralToLoanRatePrecise.mul(10**18).div(precision);
            collateralToLoanAmount = collateralAmount.mul(collateralToLoanRatePrecise).div(10**18);
        }

        uint256 initialCombinedCollateral = loanAmount.add(loanAmount.mul(minInitialMargin).div(10**20));

        isPositive = false;
        if (collateralToLoanAmount > initialCombinedCollateral) {
            loanOffsetAmount = collateralToLoanAmount.sub(initialCombinedCollateral);
            isPositive = true;
        } else if (collateralToLoanAmount < initialCombinedCollateral) {
            loanOffsetAmount = initialCombinedCollateral.sub(collateralToLoanAmount);
        }

        if (collateralToLoanRatePrecise != 0) {
            collateralOffsetAmount = loanOffsetAmount.mul(10**18).div(collateralToLoanRatePrecise);
        }
    }*/

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

    /*
    * Owner functions
    */

    function setPriceFeedsBatch(
        address[] memory tokens,
        IPriceFeedsExt[] memory feeds)
        public
        onlyOwner
    {
        require(tokens.length == feeds.length, "count mismatch");

        for (uint256 i = 0; i < tokens.length; i++) {
            pricesFeeds[tokens[i]] = feeds[i];
        }
    }

    function setMaxTradeSize(
        uint256 newAmount)
        public
        onlyOwner
    {
        maxTradeSize = newAmount;
    }

    /*
    * Internal functions
    */

    function _getDecimalPrecision(
        address sourceTokenAddress,
        address destTokenAddress)
        internal
        view
        returns(uint256)
    {
        if (sourceTokenAddress == destTokenAddress) {
            return 10**18;
        } else {
            uint256 sourceTokenDecimals = decimals[sourceTokenAddress];
            if (sourceTokenDecimals == 0)
                sourceTokenDecimals = IERC20(sourceTokenAddress).decimals();

            uint256 destTokenDecimals = decimals[destTokenAddress];
            if (destTokenDecimals == 0)
                destTokenDecimals = IERC20(destTokenAddress).decimals();

            if (destTokenDecimals >= sourceTokenDecimals)
                return 10**(SafeMath.sub(18, destTokenDecimals-sourceTokenDecimals));
            else
                return 10**(SafeMath.add(18, sourceTokenDecimals-destTokenDecimals));
        }
    }
}
