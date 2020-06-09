/**
 * Copyright 2017-2020, bZeroX, LLC. All Rights Reserved.
 * Licensed under the Apache License, Version 2.0.
 */

pragma solidity 0.5.17;
pragma experimental ABIEncoderV2;

import "../core/State.sol";
import "../events/ProtocolSettingsEvents.sol";
import "../openzeppelin/SafeERC20.sol";


contract ProtocolSettings is State, ProtocolSettingsEvents {
    using SafeERC20 for IERC20;

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
        _setTarget(this.setLendingFeePercent.selector, target);
        _setTarget(this.setTradingFeePercent.selector, target);
        _setTarget(this.setBorrowingFeePercent.selector, target);
        _setTarget(this.setAffiliateFeePercent.selector, target);
        _setTarget(this.setLiquidationIncentivePercent.selector, target);
        _setTarget(this.setGuaranteedInitialMargin.selector, target);
        _setTarget(this.setGuaranteedMaintenanceMargin.selector, target);
        _setTarget(this.setMaxDisagreement.selector, target);
        _setTarget(this.setSourceBufferPercent.selector, target);
        _setTarget(this.setMaxSwapSize.selector, target);
        _setTarget(this.setFeesAdmin.selector, target);
        _setTarget(this.withdrawLendingFees.selector, target);
        _setTarget(this.withdrawTradingFees.selector, target);
        _setTarget(this.withdrawBorrowingFees.selector, target);
        _setTarget(this.getloanPoolsList.selector, target);
        _setTarget(this.isLoanPool.selector, target);
    }

    function setCoreParams(
        address _protocolTokenAddress,
        address _priceFeeds,
        address _swapsImpl)
        external
        onlyOwner
    {
        protocolTokenAddress = _protocolTokenAddress;
        priceFeeds = _priceFeeds;
        swapsImpl = _swapsImpl;

        emit SetCoreParams(
            msg.sender,
            _protocolTokenAddress,
            _priceFeeds,
            _swapsImpl
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

    function setLendingFeePercent(
        uint256 newValue)
        external
        onlyOwner
    {
        require(newValue <= 10**20, "value too high");
        uint256 oldValue = lendingFeePercent;
        lendingFeePercent = newValue;

        emit SetLendingFeePercent(
            msg.sender,
            oldValue,
            newValue
        );
    }

    function setTradingFeePercent(
        uint256 newValue)
        external
        onlyOwner
    {
        require(newValue <= 10**20, "value too high");
        uint256 oldValue = tradingFeePercent;
        tradingFeePercent = newValue;

        emit SetTradingFeePercent(
            msg.sender,
            oldValue,
            newValue
        );
    }

    function setBorrowingFeePercent(
        uint256 newValue)
        external
        onlyOwner
    {
        require(newValue <= 10**20, "value too high");
        uint256 oldValue = borrowingFeePercent;
        borrowingFeePercent = newValue;

        emit SetBorrowingFeePercent(
            msg.sender,
            oldValue,
            newValue
        );
    }

    function setAffiliateFeePercent(
        uint256 newValue)
        external
        onlyOwner
    {
        require(newValue <= 10**20, "value too high");
        uint256 oldValue = affiliateFeePercent;
        affiliateFeePercent = newValue;

        emit SetAffiliateFeePercent(
            msg.sender,
            oldValue,
            newValue
        );
    }

    function setLiquidationIncentivePercent(
        uint256 newValue)
        external
        onlyOwner
    {
        require(newValue <= 10**20, "value too high");
        uint256 oldValue = liquidationIncentivePercent;
        liquidationIncentivePercent = newValue;

        emit SetLiquidationIncentivePercent(
            msg.sender,
            oldValue,
            newValue
        );
    }

    function setGuaranteedInitialMargin(
        uint256 newValue)
        external
        onlyOwner
    {
        guaranteedInitialMargin = newValue;
    }

    function setGuaranteedMaintenanceMargin(
        uint256 newValue)
        external
        onlyOwner
    {
        guaranteedMaintenanceMargin = newValue;
    }

    function setMaxDisagreement(
        uint256 newValue)
        external
        onlyOwner
    {
        maxDisagreement = newValue;
    }

    function setSourceBufferPercent(
        uint256 newValue)
        external
        onlyOwner
    {
        sourceBufferPercent = newValue;
    }

    function setMaxSwapSize(
        uint256 newValue)
        external
        onlyOwner
    {
        uint256 oldValue = maxSwapSize;
        maxSwapSize = newValue;

        emit SetMaxSwapSize(
            msg.sender,
            oldValue,
            newValue
        );
    }

    function setFeesAdmin(
        address newAdmin)
        external
        onlyOwner
    {
        address oldAdmin = feesAdmin;
        feesAdmin = newAdmin;

        emit SetFeesAdmin(
            msg.sender,
            oldAdmin,
            newAdmin
        );
    }

    function withdrawLendingFees(
        address token,
        address receiver,
        uint256 amount)
        external
    {
        require(msg.sender == feesAdmin, "unauthorized");

        uint256 withdrawAmount = amount;

        uint256 balance = lendingFeeTokensHeld[token];
        if (withdrawAmount > balance) {
            withdrawAmount = balance;
        }
        require(withdrawAmount != 0, "nothing to withdraw");

        lendingFeeTokensHeld[token] = balance
            .sub(withdrawAmount);
        lendingFeeTokensPaid[token] = lendingFeeTokensPaid[token]
            .add(withdrawAmount);

        IERC20(token).safeTransfer(
            receiver,
            withdrawAmount
        );

        emit WithdrawLendingFees(
            msg.sender,
            token,
            receiver,
            withdrawAmount
        );
    }

    function withdrawTradingFees(
        address token,
        address receiver,
        uint256 amount)
        external
    {
        require(msg.sender == feesAdmin, "unauthorized");

        uint256 withdrawAmount = amount;

        uint256 balance = tradingFeeTokensHeld[token];
        if (withdrawAmount > balance) {
            withdrawAmount = balance;
        }
        require(withdrawAmount != 0, "nothing to withdraw");

        tradingFeeTokensHeld[token] = balance
            .sub(withdrawAmount);
        tradingFeeTokensPaid[token] = tradingFeeTokensPaid[token]
            .add(withdrawAmount);

        IERC20(token).safeTransfer(
            receiver,
            withdrawAmount
        );

        emit WithdrawTradingFees(
            msg.sender,
            token,
            receiver,
            withdrawAmount
        );
    }

    function withdrawBorrowingFees(
        address token,
        address receiver,
        uint256 amount)
        external
    {
        require(msg.sender == feesAdmin, "unauthorized");

        uint256 withdrawAmount = amount;

        uint256 balance = borrowingFeeTokensHeld[token];
        if (withdrawAmount > balance) {
            withdrawAmount = balance;
        }
        require(withdrawAmount != 0, "nothing to withdraw");

        borrowingFeeTokensHeld[token] = balance
            .sub(withdrawAmount);
        borrowingFeeTokensPaid[token] = borrowingFeeTokensPaid[token]
            .add(withdrawAmount);

        IERC20(token).safeTransfer(
            receiver,
            withdrawAmount
        );

        emit WithdrawBorrowingFees(
            msg.sender,
            token,
            receiver,
            withdrawAmount
        );
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