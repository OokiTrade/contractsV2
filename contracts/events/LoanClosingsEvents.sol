/**
 * Copyright 2017-2020, bZeroX, LLC. All Rights Reserved.
 * Licensed under the Apache License, Version 2.0.
 */

pragma solidity 0.5.17;


contract LoanClosingsEvents {
    event CloseWithDeposit(
        bytes32 indexed loanId,
        address indexed borrower,
        address indexed lender,
        address closer,
        address loanToken,
        address collateralToken,
        uint256 repayAmount,
        uint256 collateralWithdrawAmount,
        uint256 collateralToLoanRate,
        uint256 currentMargin
    );

    event CloseWithSwap(
        address indexed trader,
        address indexed baseToken,
        address indexed quoteToken,
        address lender,
        address closer,
        bytes32 loanId,
        uint256 positionCloseSize,
        uint256 loanCloseAmount,
        uint256 exitPrice, // one unit of baseToken, denominated in quoteToken
        uint256 currentLeverage
    );

    event Liquidate(
        bytes32 indexed loanId,
        address indexed liquidator,
        address indexed borrower,
        address lender,
        address loanToken,
        address collateralToken,
        uint256 repayAmount,
        uint256 collateralWithdrawAmount,
        uint256 collateralToLoanRate,
        uint256 currentMargin
    );

}
