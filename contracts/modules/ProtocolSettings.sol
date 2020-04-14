/**
 * Copyright 2017-2020, bZeroX, LLC. All Rights Reserved.
 * Licensed under the Apache License, Version 2.0.
 */

pragma solidity 0.5.17;
pragma experimental ABIEncoderV2;

import "../core/State.sol";


contract ProtocolSettings is State {

    event CoreParamsSet(
        address protocolTokenAddress,
        address feedsController,
        address tradesController
    );

    event LoanParamsAdded(
        bytes32 indexed id,
        address owner,
        address indexed loanToken,
        address indexed collateralToken,
        uint256 initialMargin,
        uint256 maintenanceMargin,
        uint256 maxLoanDuration
    );
    event LoanParamsIdAdded(
        bytes32 indexed id,
        address indexed owner
    );

    event LoanParamsDisabled(
        bytes32 indexed id,
        address owner,
        address indexed loanToken,
        address indexed collateralToken,
        uint256 initialMargin,
        uint256 maintenanceMargin,
        uint256 maxLoanDuration
    );
    event LoanParamsIdDisabled(
        bytes32 indexed id,
        address indexed owner
    );

    event ProtocolManagerSet(
        address indexed delegator,
        address indexed delegated,
        bool isActive
    );

    constructor() public {}

    function()
        external
    {
        revert("fallback not allowed");
    }

    // setCoreParams(address,address,address)
    function setCoreParams(
        address _protocolTokenAddress,
        address _feedsController,
        address _tradesController)
        external
        onlyOwner
    {
        protocolTokenAddress = _protocolTokenAddress;
        feedsController = _feedsController;
        tradesController = _tradesController;

        emit CoreParamsSet(
            _protocolTokenAddress,
            _feedsController,
            _tradesController
        );
    }

    // setProtocolManagers(address[],bool[])
    function setProtocolManagers(
        address[] calldata addrs,
        bool[] calldata toggles)
        external
        onlyOwner
    {
        require(addrs.length == toggles.length, "count mismatch");

        for (uint256 i=0; i < addrs.length; i++) {
            protocolManagers[addrs[i]] = toggles[i];

            emit ProtocolManagerSet(
                msg.sender,
                addrs[i],
                toggles[i]
            );
        }
    }
}