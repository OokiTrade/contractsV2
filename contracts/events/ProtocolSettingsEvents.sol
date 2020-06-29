/**
 * Copyright 2017-2020, bZeroX, LLC. All Rights Reserved.
 * Licensed under the Apache License, Version 2.0.
 */

pragma solidity 0.5.17;


contract ProtocolSettingsEvents {
    event SetPriceFeedContract(
        address indexed sender,
        address oldValue,
        address newValue
    );

    event SetSwapsImplContract(
        address indexed sender,
        address oldValue,
        address newValue
    );

    event SetLoanPool(
        address indexed sender,
        address indexed loanPool,
        address indexed underlying
    );

    event SetSupportedTokens(
        address indexed sender,
        address indexed token,
        bool isActive
    );

    event SetLendingFeePercent(
        address indexed sender,
        uint256 oldValue,
        uint256 newValue
    );

    event SetTradingFeePercent(
        address indexed sender,
        uint256 oldValue,
        uint256 newValue
    );

    event SetBorrowingFeePercent(
        address indexed sender,
        uint256 oldValue,
        uint256 newValue
    );

    event SetAffiliateFeePercent(
        address indexed sender,
        uint256 oldValue,
        uint256 newValue
    );

    event SetLiquidationIncentivePercent(
        address indexed sender,
        uint256 oldValue,
        uint256 newValue
    );

    event SetMaxSwapSize(
        address indexed sender,
        uint256 oldValue,
        uint256 newValue
    );

    event SetFeesController(
        address indexed sender,
        address indexed oldController,
        address indexed newController
    );

    event WithdrawLendingFees(
        address indexed sender,
        address indexed token,
        address indexed receiver,
        uint256 amount
    );

    event WithdrawTradingFees(
        address indexed sender,
        address indexed token,
        address indexed receiver,
        uint256 amount
    );

    event WithdrawBorrowingFees(
        address indexed sender,
        address indexed token,
        address indexed receiver,
        uint256 amount
    );
}