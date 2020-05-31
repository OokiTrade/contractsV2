/**
 * Copyright 2017-2020, bZeroX, LLC. All Rights Reserved.
 * Licensed under the Apache License, Version 2.0.
 */

pragma solidity 0.5.17;


interface IPriceFeeds {
    function queryRate(
        address sourceTokenAddress,
        address destTokenAddress)
        external
        view
        returns (uint256 rate, uint256 precision);

    function checkPriceDisagreement(
        address sourceTokenAddress,
        address destTokenAddress,
        uint256 sourceTokenAmount,
        uint256 destTokenAmount,
        uint256 maxSlippage)
        external
        view;

    function amountInEth(
        address tokenAddress,
        uint256 amount)
        external
        view
        returns (uint256 ethAmount);

    function getMaxDrawdown(
        address loanToken,
        address collateralToken,
        uint256 loanAmount,
        uint256 collateralAmount,
        uint256 maintenanceMargin)
        external
        view
        returns (uint256);

    /*unction getPositionOffset(
        address loanToken,
        address collateralToken,
        uint256 loanAmount,
        uint256 collateralAmount,
        uint256 minInitialMargin)
        external
        view
        returns (bool isPositive, uint256 loanOffsetAmount, uint256 collateralOffsetAmount);*/

    function getCurrentMarginAndCollateralSize(
        address loanToken,
        address collateralToken,
        uint256 loanAmount,
        uint256 collateralAmount)
        external
        view
        returns (uint256 currentMargin, uint256 collateralInEthAmount);

    function getCurrentMargin(
        address loanToken,
        address collateralToken,
        uint256 loanAmount,
        uint256 collateralAmount)
        external
        view
        returns (uint256 currentMargin, uint256 collateralToLoanRate);

    function shouldLiquidate(
        address loanToken,
        address collateralToken,
        uint256 loanAmount,
        uint256 collateralAmount,
        uint256 maintenanceMargin)
        external
        view
        returns (bool);
}
