/**
 * Copyright 2017-2020, bZeroX, LLC. All Rights Reserved.
 * Licensed under the Apache License, Version 2.0.
 */

pragma solidity 0.5.17;
pragma experimental ABIEncoderV2;

import "../../core/State.sol";
import "../../events/ProtocolSettingsEvents.sol";
import "../../openzeppelin/SafeERC20.sol";
import "../../mixins/ProtocolTokenUser.sol";
import "../../interfaces/IVestingToken.sol";


contract ProtocolSettings is State, ProtocolTokenUser, ProtocolSettingsEvents {

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
        _setTarget(this.withdrawFees.selector, target);
        _setTarget(this.withdrawProtocolToken.selector, target);
        _setTarget(this.depositProtocolToken.selector, target);
        _setTarget(this.queryFees.selector, target);
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

            address pool = loanPoolToUnderlying[pools[i]];
            if (assets[i] == address(0)) {
                // removal action
                require(pool != address(0), "pool not exists");
            } else {
                // add action
                require(pool == address(0), "pool exists");
            }

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
        require(newValue <= WEI_PERCENT_PRECISION, "value too high");
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
        require(newValue <= WEI_PERCENT_PRECISION, "value too high");
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
        require(newValue <= WEI_PERCENT_PRECISION, "value too high");
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
        require(newValue <= WEI_PERCENT_PRECISION, "value too high");
        uint256 oldValue = affiliateFeePercent;
        affiliateFeePercent = newValue;

        emit SetAffiliateFeePercent(
            msg.sender,
            oldValue,
            newValue
        );
    }

    function setLiquidationIncentivePercent(
        address[] calldata loanTokens,
        address[] calldata collateralTokens,
        uint256[] calldata amounts)
        external
        onlyOwner
    {
        require(loanTokens.length == collateralTokens.length && loanTokens.length == amounts.length, "count mismatch");

        for (uint256 i = 0; i < loanTokens.length; i++) {
            require(amounts[i] <= WEI_PERCENT_PRECISION, "value too high");

            uint256 oldValue = liquidationIncentivePercent[loanTokens[i]][collateralTokens[i]];
            liquidationIncentivePercent[loanTokens[i]][collateralTokens[i]] = amounts[i];

            emit SetLiquidationIncentivePercent(
                msg.sender,
                loanTokens[i],
                collateralTokens[i],
                oldValue,
                amounts[i]
            );
        }
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

    function withdrawFees(
        address[] calldata tokens,
        address receiver,
        FeeType feeType)
        external
        returns (uint256[] memory amounts)
    {
        require(msg.sender == feesController, "unauthorized");

        amounts = new uint256[](tokens.length);
        uint256 balance;
        address token;
        for (uint256 i = 0; i < tokens.length; i++) {
            token = tokens[i];

            if (feeType == FeeType.All || feeType == FeeType.Lending) {
                balance = lendingFeeTokensHeld[token];
                if (balance != 0) {
                    amounts[i] = balance;  // will not overflow
                    lendingFeeTokensHeld[token] = 0;
                    lendingFeeTokensPaid[token] = lendingFeeTokensPaid[token]
                        .add(balance);
                    emit WithdrawLendingFees(
                        msg.sender,
                        token,
                        receiver,
                        balance
                    );
                }
            }
            if (feeType == FeeType.All || feeType == FeeType.Trading) {
                balance = tradingFeeTokensHeld[token];
                if (balance != 0) {
                    amounts[i] += balance;  // will not overflow
                    tradingFeeTokensHeld[token] = 0;
                    tradingFeeTokensPaid[token] = tradingFeeTokensPaid[token]
                        .add(balance);
                    emit WithdrawTradingFees(
                        msg.sender,
                        token,
                        receiver,
                        balance
                    );
                }
            }
            if (feeType == FeeType.All || feeType == FeeType.Borrowing) {
                balance = borrowingFeeTokensHeld[token];
                if (balance != 0) {
                    amounts[i] += balance;  // will not overflow
                    borrowingFeeTokensHeld[token] = 0;
                    borrowingFeeTokensPaid[token] = borrowingFeeTokensPaid[token]
                        .add(balance);
                    emit WithdrawBorrowingFees(
                        msg.sender,
                        token,
                        receiver,
                        balance
                    );
                }
            }

            if (amounts[i] != 0) {
                IERC20(token).safeTransfer(
                    receiver,
                    amounts[i]
                );
            }
        }
    }

    function withdrawProtocolToken(
        address receiver,
        uint256 amount)
        external
        onlyOwner
        returns (address rewardToken, uint256 withdrawAmount)
    {
        (rewardToken, withdrawAmount) = _withdrawProtocolToken(
            receiver,
            amount
        );

        uint256 totalEmission = IVestingToken(vbzrxTokenAddress).claimedBalanceOf(address(this));

        uint256 totalWithdrawn;
        // keccak256("BZRX_TotalWithdrawn")
        bytes32 slot = 0xf0cbcfb4979ecfbbd8f7e7430357fc20e06376d29a69ad87c4f21360f6846545;
        assembly {
            totalWithdrawn := sload(slot)
        }

        if (totalEmission > totalWithdrawn) {
            IERC20(bzrxTokenAddress).safeTransfer(
                receiver,
                totalEmission - totalWithdrawn
            );
            assembly {
                sstore(slot, totalEmission)
            }
        }
    }

    function depositProtocolToken(
        uint256 amount)
        external
        onlyOwner
    {
        protocolTokenHeld = protocolTokenHeld
            .add(amount);

        IERC20(vbzrxTokenAddress).safeTransferFrom(
            msg.sender,
            address(this),
            amount
        );
    }

    // NOTE: this doesn't sanitize inputs -> inaccurate values may be returned if there are duplicates tokens input
    function queryFees(
        address[] calldata tokens,
        FeeType feeType)
        external
        view
        returns (uint256[] memory amountsHeld, uint256[] memory amountsPaid)
    {
        amountsHeld = new uint256[](tokens.length);
        amountsPaid = new uint256[](tokens.length);
        address token;
        for (uint256 i = 0; i < tokens.length; i++) {
            token = tokens[i];
            
            if (feeType == FeeType.Lending) {
                amountsHeld[i] = lendingFeeTokensHeld[token];
                amountsPaid[i] = lendingFeeTokensPaid[token];
            } else if (feeType == FeeType.Trading) {
                amountsHeld[i] = tradingFeeTokensHeld[token];
                amountsPaid[i] = tradingFeeTokensPaid[token];
            } else if (feeType == FeeType.Borrowing) {
                amountsHeld[i] = borrowingFeeTokensHeld[token];
                amountsPaid[i] = borrowingFeeTokensPaid[token];
            } else {
                amountsHeld[i] = lendingFeeTokensHeld[token] + tradingFeeTokensHeld[token] + borrowingFeeTokensHeld[token]; // will not overflow
                amountsPaid[i] = lendingFeeTokensPaid[token] + tradingFeeTokensPaid[token] + borrowingFeeTokensPaid[token]; // will not overflow
            }
        }
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
