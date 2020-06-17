/**
 * Copyright 2017-2020, bZeroX, LLC. All Rights Reserved.
 * Licensed under the Apache License, Version 2.0.
 */

pragma solidity 0.5.17;


contract LoanClosingsEvents {

    // topic0: 0x6349c1a02ec126f7f4fc6e6837e1859006e90e9901635c442d29271e77b96fb6
    event CloseWithDeposit(
        address indexed user,
        address indexed lender,
        bytes32 indexed loanId,
        address closer,
        address loanToken,
        address collateralToken,
        uint256 repayAmount,
        uint256 collateralWithdrawAmount,
        uint256 collateralToLoanRate,
        uint256 currentMargin
    );

    // topic0: 0xea42d6c94db037479b045a6b4933be0ba4a5a6d54837e99abdcaa3a0a422689d
    event CloseWithSwap(
        address indexed user,
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

    // topic0: 0x46fa03303782eb2f686515f6c0100f9a62dabe587b0d3f5a4fc0c822d6e532d3
    event Liquidate(
        address indexed user,
        address indexed liquidator,
        bytes32 indexed loanId,
        address lender,
        address loanToken,
        address collateralToken,
        uint256 repayAmount,
        uint256 collateralWithdrawAmount,
        uint256 collateralToLoanRate,
        uint256 currentMargin
    );

}
