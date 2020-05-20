/**
 * Copyright 2017-2020, bZeroX, LLC. All Rights Reserved.
 * Licensed under the Apache License, Version 2.0.
 */

pragma solidity 0.5.17;
pragma experimental ABIEncoderV2;

import "../core/State.sol";
import "../events/ProtocolSettingsEvents.sol";
import "../interfaces/IERC20.sol";


contract ProtocolSettings is State, ProtocolSettingsEvents {

    constructor() public {}

    function()
        external
    {
        revert("fallback not allowed");
    }

    function initialize(
        address target)
        external
        onlyOwner
    {
        logicTargets[this.setCoreParams.selector] = target;
        logicTargets[this.setProtocolManagers.selector] = target;
        logicTargets[this.setLoanPoolToUnderlying.selector] = target;
        logicTargets[this.setSupportedTokens.selector] = target;
        logicTargets[this.getloanPoolsList.selector] = target;
    }

    function setCoreParams(
        address _protocolTokenAddress,
        address _priceFeeds,
        address _swapsImpl,
        uint256 _protocolFeePercent) // 10 * 10**18;
        external
        onlyOwner
    {
        protocolTokenAddress = _protocolTokenAddress;
        priceFeeds = _priceFeeds;
        swapsImpl = _swapsImpl;

        require(_protocolFeePercent <= 10**20);
        protocolFeePercent = _protocolFeePercent;

        emit SetCoreParams(
            msg.sender,
            _protocolTokenAddress,
            _priceFeeds,
            _swapsImpl,
            _protocolFeePercent
        );
    }

    function setProtocolManagers(
        address[] calldata addrs,
        bool[] calldata toggles)
        external
        onlyOwner
    {
        require(addrs.length == toggles.length, "count mismatch");

        for (uint256 i = 0; i < addrs.length; i++) {
            protocolManagers[addrs[i]] = toggles[i];

            emit SetProtocolManager(
                msg.sender,
                addrs[i],
                toggles[i]
            );
        }
    }

    function setLoanPoolToUnderlying(
        address[] calldata pools,
        address[] calldata assets)
        external
        onlyOwner
    {
        require(pools.length == assets.length, "count mismatch");

        for (uint256 i = 0; i < pools.length; i++) {
            require(pools[i] != assets[i], "pool == asset");
            require(pools[i] != address(0), "pool == 0");
            require(assets[i] != address(0) || loanPoolToUnderlying[pools[i]] != address(0), "pool not exists");
            if (assets[i] == address(0)) {
                underlyingToLoanPool[loanPoolToUnderlying[pools[i]]] = address(0);
                loanPoolToUnderlying[pools[i]] = address(0);
                loanPoolsSet.removeAddress(pools[i]);
            } else {
                loanPoolToUnderlying[pools[i]] = assets[i];
                underlyingToLoanPool[assets[i]] = pools[i];
                loanPoolsSet.addAddress(pools[i]);
            }

            emit SetLoanPoolToUnderlying(
                msg.sender,
                pools[i],
                assets[i]
            );
        }
    }

    function setSupportedTokens(
        address[] calldata addrs,
        bool[] calldata toggles)
        external
        onlyOwner
    {
        require(addrs.length == toggles.length, "count mismatch");

        for (uint256 i = 0; i < addrs.length; i++) {
            supportedTokens[addrs[i]] = toggles[i];

            emit SetSupportedTokens(
                msg.sender,
                addrs[i],
                toggles[i]
            );
        }
    }

    function getloanPoolsList(
        uint256 start,
        uint256 count)
        external
        view
        returns(bytes32[] memory)
    {
        return loanPoolsSet.enumerate(start, count);
    }
}