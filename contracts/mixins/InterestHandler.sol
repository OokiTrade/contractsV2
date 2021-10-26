/**
 * Copyright 2017-2021, bZxDao. All Rights Reserved.
 * Licensed under the Apache License, Version 2.0.
 */

pragma solidity 0.5.17;

import "../core/State.sol";
import "./FeesHelper.sol";
import "../interfaces/ILoanPool.sol";


contract InterestHandler is State, FeesHelper {
    using SafeERC20 for IERC20;

    function _settleInterest(
        address pool,
        address loanToken,
        bytes32 loanId)
        internal
    {
        uint256 _loanRatePerTokenPaid;
        uint256 _loanPrincipalTotal;
        (
            _ooipx.poolTotalPrincipal[pool],
            _ooipx.poolRatePerTokenStored[pool],
            _loanRatePerTokenPaid,
            _loanPrincipalTotal) = _settleInterest2(
            pool,
            loanToken,
            loanId
        );

        if (loanId != 0) {
            _ooipx.loanRatePerTokenPaid[loanId] = _loanRatePerTokenPaid;
            loans[loanId].principal = _loanPrincipalTotal;
        }

        _ooipx.poolLastUpdateTime[pool] = block.timestamp;
    }

    function _getTotalPrincipal(
        address pool,
        address loanToken)
        internal
        view
        returns (uint256 _poolTotalPrincipal)
    {
        (_poolTotalPrincipal,,,) = _settleInterest2(
            pool,
            loanToken,
            0
        );
    }

    function _getLoanPrincipal(
        address pool,
        address loanToken,
        bytes32 loanId)
        internal
        view
        returns (uint256 _loanPrincipalTotal)
    {
        (,,,_loanPrincipalTotal) = _settleInterest2(
            pool,
            loanToken,
            loanId
        );
    }

    function _settleInterest2(
        address pool,
        address loanToken,
        bytes32 loanId)
        internal
        view
        returns (
            uint256 _poolTotalPrincipal,
            uint256 _poolRatePerTokenStored,
            uint256 _loanRatePerTokenPaid,
            uint256 _loanPrincipalTotal)
    {
        _poolTotalPrincipal = _ooipx.poolTotalPrincipal[pool];
        uint256 _poolVariableRatePerTokenNewAmount = _getRatePerTokenNewAmount(_poolTotalPrincipal, pool);
        if (_poolTotalPrincipal != 0) {
            _poolTotalPrincipal = _getUpdatedPrincipal(
                _poolTotalPrincipal,
                _poolVariableRatePerTokenNewAmount
            );

            _poolRatePerTokenStored = _ooipx.poolRatePerTokenStored[pool]
                .add(_poolVariableRatePerTokenNewAmount);
        }

         if (loanId != 0) {
            _loanPrincipalTotal = loans[loanId].principal;
            if (_loanPrincipalTotal != 0) {
                _loanRatePerTokenPaid = _poolRatePerTokenStored;

                _loanPrincipalTotal = _getUpdatedPrincipal(
                    _loanPrincipalTotal,
                    _poolRatePerTokenStored.sub(_ooipx.loanRatePerTokenPaid[loanId]) // _loanRatePerTokenUnpaid
                );
            }
        }
    }

    function _currentPoolUtil(
        address loanToken,
        address pool,
        uint256 principal)
        internal
        view
        returns (uint256)
    {
        uint256 totalSupply = IERC20(loanToken).balanceOf(pool) // underlying balance
            .add(principal);

        return principal
            .mul(10**20)
            .div(totalSupply); // principal + free_liquidity
    }

    function _getRatePerTokenNewAmount(
        uint256 _poolPrincipalTotal,
        address pool)
        internal
        view
        returns (uint256)
    {
        return block.timestamp
            .sub(_ooipx.poolLastUpdateTime[pool])
            .mul(ILoanPool(pool)._nextBorrowInterestRate(_poolPrincipalTotal, 0)) // rate per year
            .div(31536000); // seconds in a year
    }

    function _getUpdatedPrincipal(
        uint256 _principal,
        uint256 _ratePerTokenNewAmount)
        internal
        view
        returns (uint256)
    {
        return _principal
            .mul(_ratePerTokenNewAmount)
            .div(WEI_PERCENT_PRECISION)
            .add(_principal);
    }
}
