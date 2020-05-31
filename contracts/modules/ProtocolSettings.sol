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
        _setTarget(this.setCoreParams.selector, target);
        _setTarget(this.setLoanPool.selector, target);
        _setTarget(this.setSupportedTokens.selector, target);
        _setTarget(this.setGuaranteedInitialMargin.selector, target);
        _setTarget(this.setGuaranteedMaintenanceMargin.selector, target);
        _setTarget(this.setMaxDisagreement.selector, target);
        _setTarget(this.setSourceBufferPercent.selector, target);
        _setTarget(this.setMaxSwapSize.selector, target);
        _setTarget(this.getloanPoolsList.selector, target);
        _setTarget(this.isLoanPool.selector, target);
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

    function setLoanPool(
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

            emit SetLoanPool(
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

    function setGuaranteedInitialMargin(
        uint256 newAmount)
        external
        onlyOwner
    {
        guaranteedInitialMargin = newAmount;
    }

    function setGuaranteedMaintenanceMargin(
        uint256 newAmount)
        external
        onlyOwner
    {
        guaranteedMaintenanceMargin = newAmount;
    }

    function setMaxDisagreement(
        uint256 newAmount)
        external
        onlyOwner
    {
        maxDisagreement = newAmount;
    }

    function setSourceBufferPercent(
        uint256 newAmount)
        external
        onlyOwner
    {
        sourceBufferPercent = newAmount;
    }

    function setMaxSwapSize(
        uint256 newAmount)
        external
        onlyOwner
    {
        maxSwapSize = newAmount;
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

    function isLoanPool(
        address loanPool)
        external
        view
        returns (bool)
    {
        return loanPoolToUnderlying[loanPool] != address(0);
    }
}