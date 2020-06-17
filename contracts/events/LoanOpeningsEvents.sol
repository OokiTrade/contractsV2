/**
 * Copyright 2017-2020, bZeroX, LLC. All Rights Reserved.
 * Licensed under the Apache License, Version 2.0.
 */

pragma solidity 0.5.17;


contract LoanOpeningsEvents {

    // topic0: 0x7bd8cbb7ba34b33004f3deda0fd36c92fc0360acbd97843360037b467a538f90
    event Borrow(
        address indexed user,
        address indexed lender,
        bytes32 indexed loanId,
        address loanToken,
        address collateralToken,
        uint256 newPrincipal,
        uint256 newCollateral,
        uint256 interestRate,
        uint256 interestDuration,
        uint256 collateralToLoanRate,
        uint256 currentMargin
    );

    // topic0: 0xafa6452c53d4537ba2992dec6b9cad9a2fe82db672005ea589963f9f0b3de052
    event Trade(
        address indexed user,
        address indexed baseToken,
        address indexed quoteToken,
        address lender,
        bytes32 loanId,
        uint256 positionSize,
        uint256 borrowedAmount,
        uint256 interestRate,
        uint256 settlementDate,
        uint256 entryPrice, // one unit of baseToken, denominated in quoteToken
        uint256 entryLeverage,
        uint256 currentLeverage
    );

    // topic0: 0x0eef4f90457a741c97d76fcf13fa231fefdcc7649bdb3cb49157c37111c98433
    event DelegatedManagerSet(
        bytes32 indexed loanId,
        address indexed delegator,
        address indexed delegated,
        bool isActive
    );
}