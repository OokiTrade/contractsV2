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

    function checkMaxTradeSize(
        address tokenAddress,
        uint256 amount)
        external
        view;

    function getPositionOffset(
        address loanTokenAddress,
        address collateralTokenAddress,
        uint256 loanTokenAmount,
        uint256 collateralTokenAmount,
        uint256 initialMarginAmount)
        external
        view
        returns (bool isPositive, uint256 loanOffsetAmount, uint256 collateralOffsetAmount);

    function getCurrentMarginAndCollateralSize(
        address loanTokenAddress,
        address collateralTokenAddress,
        uint256 loanTokenAmount,
        uint256 collateralTokenAmount)
        external
        view
        returns (uint256 currentMargin, uint256 collateralInEthAmount);

    function getCurrentMargin(
        address loanTokenAddress,
        address collateralTokenAddress,
        uint256 loanTokenAmount,
        uint256 collateralTokenAmount)
        external
        view
        returns (uint256 currentMargin, uint256 collateralToLoanRate);

    function shouldLiquidate(
        address loanTokenAddress,
        address collateralTokenAddress,
        uint256 loanTokenAmount,
        uint256 collateralTokenAmount,
        uint256 maintenanceMarginAmount)
        external
        view
        returns (bool);
}
