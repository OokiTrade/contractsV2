/**
 * Copyright 2017-2020, bZeroX, LLC. All Rights Reserved.
 * Licensed under the Apache License, Version 2.0.
 */

pragma solidity 0.5.17;


contract ProtocolSettingsEvents {
    event SetCoreParams(
        address indexed sender,
        address protocolTokenAddress,
        address priceFeeds,
        address swapsImpl,
        uint256 protocolFeePercent
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
}