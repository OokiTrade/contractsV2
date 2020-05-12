/**
 * Copyright 2017-2020, bZeroX, LLC. All Rights Reserved.
 * Licensed under the Apache License, Version 2.0.
 */

pragma solidity 0.5.17;


contract LoanOpeningsEvents {
    event Borrow(
        bytes32 indexed loanId,
        address indexed borrower,
        address indexed loanToken,
        address collateralToken,
        uint256 newPrincipal,
        uint256 newCollateral,
        uint256 interestRate,
        uint256 interestDuration,
        uint256 collateralToLoanRate,
        uint256 currentMargin
    );

    event Trade(
        address indexed trader,
        address indexed baseToken,
        address indexed quoteToken,
        bytes32 loanId,
        uint256 positionSize,
        uint256 borrowedAmount,
        uint256 interestRate,
        uint256 settlementDate,
        uint256 entryPrice, // one unit of baseToken, denominated in quoteToken
        uint256 entryLeverage,
        uint256 currentLeverage
    );

    event DelegatedManagerSet(
        bytes32 indexed loanId,
        address indexed delegator,
        address indexed delegated,
        bool isActive
    );
}