/**
 * Copyright 2017-2020, bZeroX, LLC. All Rights Reserved.
 * Licensed under the Apache License, Version 2.0.
 */

pragma solidity 0.5.17;

import "../core/Constants.sol";
import "../openzeppelin/SafeERC20.sol";


contract VaultController is Constants {
    using SafeERC20 for IERC20;

    function vaultEtherDeposit(
        uint256 value)
        internal
    {
        wethToken.deposit.value(value)();
    }

    function vaultEtherWithdraw(
        address to,
        uint256 value)
        internal
    {
        if (value != 0) {
            uint256 balance = address(this).balance;
            if (value > balance) {
                wethToken.withdraw(value - balance);
            }
            Address.sendValue(to, value);
        }
    }

    function vaultDeposit(
        address token,
        address from,
        uint256 value)
        internal
    {
        if (value != 0) {
            IERC20(token).safeTransferFrom(
                from,
                address(this),
                value
            );
        }
    }

    function vaultWithdraw(
        address token,
        address to,
        uint256 value)
        internal
    {
        if (value != 0) {
            IERC20(token).safeTransfer(
                to,
                value
            );
        }
    }

    function vaultTransfer(
        address token,
        address from,
        address to,
        uint256 value)
        internal
    {
        if (value != 0) {
            IERC20(token).safeTransferFrom(
                from,
                to,
                value
            );
        }
    }

    function vaultApprove(
        address token,
        address to,
        uint256 value)
        internal
    {
        if (value != 0 && IERC20(token).allowance(address(this), to) != 0) {
            IERC20(token).safeApprove(to, 0);
        }
        IERC20(token).safeApprove(to, value);
    }
}
