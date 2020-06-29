/**
 * Copyright 2017-2020, bZeroX, LLC. All Rights Reserved.
 * Licensed under the Apache License, Version 2.0.
 */

pragma solidity 0.5.17;
pragma experimental ABIEncoderV2;

import "../core/State.sol";
import "../events/ProtocolSettingsEvents.sol";
import "../openzeppelin/SafeERC20.sol";
import "../mixins/ProtocolTokenUser.sol";


contract ProtocolSettings is State, ProtocolTokenUser, ProtocolSettingsEvents {
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
        _setTarget(this.setPriceFeedContract.selector, target);
        _setTarget(this.setSwapsImplContract.selector, target);
        _setTarget(this.setLoanPool.selector, target);
        _setTarget(this.setSupportedTokens.selector, target);
        _setTarget(this.setLendingFeePercent.selector, target);
        _setTarget(this.setTradingFeePercent.selector, target);
        _setTarget(this.setBorrowingFeePercent.selector, target);
        _setTarget(this.setAffiliateFeePercent.selector, target);
        _setTarget(this.setLiquidationIncentivePercent.selector, target);
        _setTarget(this.setMaxDisagreement.selector, target);
        _setTarget(this.setSourceBufferPercent.selector, target);
        _setTarget(this.setMaxSwapSize.selector, target);
        _setTarget(this.setFeesController.selector, target);
        _setTarget(this.withdrawLendingFees.selector, target);
        _setTarget(this.withdrawTradingFees.selector, target);
        _setTarget(this.withdrawBorrowingFees.selector, target);
        _setTarget(this.withdrawProtocolToken.selector, target);
        _setTarget(this.depositProtocolToken.selector, target);
        _setTarget(this.getLoanPoolsList.selector, target);
        _setTarget(this.isLoanPool.selector, target);
    }

    function setPriceFeedContract(
        address newContract)
        external
        onlyOwner
    {
        address oldContract = priceFeeds;
        priceFeeds = newContract;

        emit SetPriceFeedContract(
            msg.sender,
            oldContract,
            newContract
        );
    }

    function setSwapsImplContract(
        address newContract)
        external
        onlyOwner
    {
        address oldContract = swapsImpl;
        swapsImpl = newContract;

        emit SetSwapsImplContract(
            msg.sender,
            oldContract,
            newContract
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

    function setFeesController(
        address newController)
        external
        onlyOwner
    {
        address oldController = feesController;
        feesController = newController;

        emit SetFeesController(
            msg.sender,
            oldController,
            newController
        );
    }

    function withdrawLendingFees(
        address token,
        address receiver,
        uint256 amount)
        external
        returns (bool)
    {
        require(msg.sender == feesController, "unauthorized");

        uint256 withdrawAmount = amount;

        uint256 balance = lendingFeeTokensHeld[token];
        if (withdrawAmount > balance) {
            withdrawAmount = balance;
        }
        if (withdrawAmount == 0) {
            return false;
        }

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

        return true;
    }

    function withdrawTradingFees(
        address token,
        address receiver,
        uint256 amount)
        external
        returns (bool)
    {
        require(msg.sender == feesController, "unauthorized");

        uint256 withdrawAmount = amount;

        uint256 balance = tradingFeeTokensHeld[token];
        if (withdrawAmount > balance) {
            withdrawAmount = balance;
        }
        if (withdrawAmount == 0) {
            return false;
        }

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

        return true;
    }

    function withdrawBorrowingFees(
        address token,
        address receiver,
        uint256 amount)
        external
        returns (bool)
    {
        require(msg.sender == feesController, "unauthorized");

        uint256 withdrawAmount = amount;

        uint256 balance = borrowingFeeTokensHeld[token];
        if (withdrawAmount > balance) {
            withdrawAmount = balance;
        }
        if (withdrawAmount == 0) {
            return false;
        }

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

        return true;
    }

    function withdrawProtocolToken(
        address receiver,
        uint256 amount)
        external
        onlyOwner
        returns (address, bool)
    {
        return _withdrawProtocolToken(
            receiver,
            amount
        );
    }

   function depositProtocolToken(
        uint256 amount)
        external
        onlyOwner
    {
        protocolTokenHeld = protocolTokenHeld
            .add(amount);

        IERC20(protocolTokenAddress).safeTransferFrom(
            msg.sender,
            address(this),
            amount
        );
    }

    function getLoanPoolsList(
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
