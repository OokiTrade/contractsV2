/**
 * Copyright 2017-2020, bZeroX, LLC. All Rights Reserved.
 * Licensed under the Apache License, Version 2.0.
 */

pragma solidity 0.5.17;
pragma experimental ABIEncoderV2;

import "../core/State.sol";

import "../../interfaces/IERC20.sol";

contract ProtocolSettings is State {

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

    constructor() public {}

    function()
        external
    {
        revert("fallback not allowed");
    }

    // setCoreParams(address,address,address,uint256)
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

        emit CoreParamsSet(
            _protocolTokenAddress,
            _priceFeeds,
            _swapsImpl,
            _protocolFeePercent
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

    // setLoanPools(address[],address[])
    function setLoanPools(
        address[] calldata pools,
        address[] calldata assets)
        external
        onlyOwner
    {
        require(pools.length == assets.length, "count mismatch");

        for (uint256 i=0; i < pools.length; i++) {
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
        }
    }

    // setDecimalsBatch(address[])
    /*
        // set decimals for ether
        decimals[address(0)] = 18;
        decimals[address(0x00eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee)] = 18;
        decimals[address(wethToken)] = 18;
    */
    /*function setDecimalsBatch(
        IERC20[] memory tokens)
        public
    {
        for (uint256 i=0; i < tokens.length; i++) {
            decimals[address(tokens[i])] = tokens[i].decimals();
        }
    }*/

    // getloanPoolsList(uint256,uint256)
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