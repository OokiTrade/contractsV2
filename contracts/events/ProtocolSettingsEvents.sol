/**
 * Copyright 2017-2020, bZeroX, LLC. All Rights Reserved.
 * Licensed under the Apache License, Version 2.0.
 */

pragma solidity 0.5.17;


contract ProtocolSettingsEvents {
    event CoreParamsSet(
        address protocolTokenAddress,
        address priceFeeds,
        address swapsImpl,
        uint256 protocolFeePercent
    );

    event ProtocolManagerSet(
        address indexed delegator,
        address indexed delegated,
        bool isActive
    );
}