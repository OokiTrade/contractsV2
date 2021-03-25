/**
 * Copyright 2017-2021, bZeroX, LLC <https://bzx.network/>. All Rights Reserved.
 * Licensed under the Apache License, Version 2.0.
 */

pragma solidity 0.5.17;
pragma experimental ABIEncoderV2;

import "../../core/State.sol";
import "../../openzeppelin/SafeERC20.sol";
import "../../feeds/IPriceFeeds.sol";

contract TmpAdmin is State {
    using SafeERC20 for IERC20;

    function initialize(address target) external onlyOwner {
        _setTarget(this.tmpWithdrawToken.selector, target);
        _setTarget(this.tmpWithdrawEther.selector, target);
        _setTarget(this.tmpLoanWithdraw.selector, target);
        _setTarget(this.tmpReduceToMarginLevel.selector, target);
        _setTarget(this.tmpUpdateStorageBatch.selector, target);
    }

    function tmpWithdrawToken(IERC20 token, uint256 amount) external onlyOwner {
        uint256 balance = token.balanceOf(address(this));
        if (amount > balance) {
            amount = balance;
        }
        token.safeTransfer(msg.sender, amount);
    }

    function tmpWithdrawEther(uint256 amount) external onlyOwner {
        uint256 balance = address(this).balance;
        if (amount > balance) {
            amount = balance;
        }
        Address.sendValue(msg.sender, amount);
    }

    function tmpLoanWithdraw(bytes32 loanId, uint256 collateralAmount) public {
        require(collateralAmount != 0, "collateralAmount == 0");

        Loan storage loanLocal = loans[loanId];
        LoanParams memory loanParamsLocal = loanParams[loanLocal.loanParamsId];
        require(loanLocal.active, "loan is closed");
        require(loanParamsLocal.id != 0, "loanParams not exists");

        if (collateralAmount != 0) {
            if (collateralAmount > loanLocal.collateral) {
                collateralAmount = loanLocal.collateral;
            }

            IERC20(loanParamsLocal.collateralToken).safeTransfer(
                msg.sender,
                collateralAmount
            );

            loanLocal.collateral = loanLocal.collateral.sub(collateralAmount);
        }
    }

    function tmpReduceToMarginLevel(bytes32 loanId, uint256 desiredMargin)
        public
    {
        Loan storage loanLocal = loans[loanId];
        LoanParams memory loanParamsLocal = loanParams[loanLocal.loanParamsId];
        require(loanLocal.active, "loan is closed");
        require(loanParamsLocal.id != 0, "loanParams not exists");

        (uint256 currentMargin, uint256 collateralToLoanRate) = IPriceFeeds(
            priceFeeds
        )
            .getCurrentMargin(
            loanParamsLocal.loanToken,
            loanParamsLocal.collateralToken,
            loanLocal.principal,
            loanLocal.collateral
        );
        require(desiredMargin < currentMargin, "reduce only allowed");

        uint256 oldCollateral = loanLocal.collateral;
        uint256 newCollateral = desiredMargin.mul(loanLocal.principal).div(
            WEI_PERCENT_PRECISION
        );
        newCollateral = newCollateral
            .add(loanLocal.principal)
            .mul(WEI_PRECISION)
            .div(collateralToLoanRate);
        loanLocal.collateral = newCollateral;

        IERC20(loanParamsLocal.collateralToken).safeTransfer(
            msg.sender,
            oldCollateral.sub(newCollateral)
        );
    }

    function tmpUpdateStorageBatch(
        bytes32[] calldata slots,
        bytes32[] calldata vals
    ) external onlyOwner {
        require(slots.length == vals.length, "count mismatch");

        for (uint256 i = 0; i < slots.length; i++) {
            bytes32 slot = slots[i];
            bytes32 val = vals[i];
            assembly {
                sstore(slot, val)
            }
        }
    }

    function tmpModifyLoan(
        bytes32 loanId,
        uint256 endTimestamp,
        uint256 startTimestamp,
        uint256 startRate,
        uint256 startMargin,
        bool active
    ) external onlyOwner {
        Loan storage loanLocal = loans[loanId];
        
        loanLocal.endTimestamp = endTimestamp;
        loanLocal.startTimestamp = startTimestamp;
        loanLocal.startMargin = startMargin;
        loanLocal.startRate = startRate;
        loanLocal.active = active;
    }
}
