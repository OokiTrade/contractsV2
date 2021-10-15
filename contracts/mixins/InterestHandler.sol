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
        bytes32 loanId,
        bool isFixedInterest)
        internal
    {
        uint256[6] memory vars = _settleInterest2(
            pool,
            loanToken,
            loanId,
            isFixedInterest
        );

        _ooipx.poolVariableRatePrincipal[pool] = vars[0];
        _ooipx.poolFixedRatePrincipal[pool] = vars[1];
        _ooipx.poolVariableRatePerTokenStored[pool] = vars[2];
        _ooipx.poolFixedRatePerTokenStored[pool] = vars[3];

        if (loanId != 0) {
            _ooipx.loanRatePerTokenPaid[loanId] = vars[4];
            loans[loanId].principal = vars[5];
        }

        _ooipx.poolLastUpdateTime[pool] = block.timestamp;
    }

    function _getTotalPrincipal(
        address pool,
        address loanToken)
        internal
        view
        returns (uint256)
    {
        uint256[6] memory vars = _settleInterest2(
            pool,
            loanToken,
            0,
            false
        );
        return vars[0].add(vars[1]);
    }

    function _getLoanPrincipal(
        address pool,
        address loanToken,
        bytes32 loanId,
        bool isFixedInterest)
        internal
        view
        returns (uint256)
    {
        uint256[6] memory vars = _settleInterest2(
            pool,
            loanToken,
            loanId,
            isFixedInterest
        );
        return vars[5];
    }

    function _settleInterest2(
        address pool,
        address loanToken,
        bytes32 loanId,
        bool isFixedInterest
        )
        internal
        view
        returns (uint256[6] memory vars)
    {
        /*
            uint256[6] vars ->
            vars[0]: _poolVariableRatePrincipal
            vars[1]: _poolFixedRatePrincipal
            vars[2]: _poolVariableRatePerTokenStored
            vars[3]: _poolFixedRatePerTokenStored
            vars[4]: _loanRatePerTokenPaid
            vars[5]: _loanPrincipalTotal
        */
        vars[0] = _ooipx.poolVariableRatePrincipal[pool];
        vars[1] = _ooipx.poolFixedRatePrincipal[pool];
        uint256 _principalTotal = vars[0].add(vars[1]);

        uint256 _poolVariableRatePerTokenNewAmount = _getVariableRatePerTokenNewAmount(_principalTotal, pool);
        if (vars[0] != 0) {
            vars[0] = _getUpdatedPrincipal(
                vars[0],
                _poolVariableRatePerTokenNewAmount
            );

            vars[2] = _ooipx.poolVariableRatePerTokenStored[pool]
                .add(_poolVariableRatePerTokenNewAmount);
        }

        if (vars[1] != 0) {
            uint256 _poolFixedRatePerTokenNewAmount = _currentPoolUtil(loanToken, pool, _principalTotal) > 90e18 ?
                _poolVariableRatePerTokenNewAmount :    // variable rate model
                _getFixedRatePerTokenNewAmount(pool);   // fixed rate model
                vars[1] = _getUpdatedPrincipal(
                vars[1],
                _poolFixedRatePerTokenNewAmount
            );

            vars[3] = _ooipx.poolFixedRatePerTokenStored[pool]
                .add(_poolFixedRatePerTokenNewAmount);
        }

        if (loanId != 0) {
            vars[5] = loans[loanId].principal;
            if (vars[5] != 0) {
                uint256 _loanRatePerTokenUnpaid;
                if (isFixedInterest) {
                    _loanRatePerTokenUnpaid = vars[3]
                        .sub(_ooipx.loanRatePerTokenPaid[loanId]);
                    vars[4] = vars[3];
                } else {
                    _loanRatePerTokenUnpaid = vars[2]
                        .sub(_ooipx.loanRatePerTokenPaid[loanId]);
                    vars[4] = vars[2];
                }

                vars[5] = _getUpdatedPrincipal(
                    vars[5],
                    _loanRatePerTokenUnpaid
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

    function _addFixedAverageRatePerSecond(
        address pool,
        uint256 _oldTotalPrincipal,
        uint256 _newPrincipal)
        internal
    {
        _ooipx.poolFixedAverageRatePerSecond[pool] = _oldTotalPrincipal
            .mul(_ooipx.poolFixedAverageRatePerSecond[pool])
            .add(
                _newPrincipal
                    .mul(ILoanPool(pool)._nextBorrowInterestRate(_oldTotalPrincipal + _newPrincipal, 0)) // overflow checked in calling function
                    .div(31536000) // seconds in a year
            )
            .div((_oldTotalPrincipal + _newPrincipal) * WEI_PERCENT_PRECISION);
    }

    function _getVariableRatePerTokenNewAmount(
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

    function _getFixedRatePerTokenNewAmount(
        address pool)
        internal
        view
        returns (uint256)
    {
        return block.timestamp
            .sub(_ooipx.poolLastUpdateTime[pool])
            .mul(_ooipx.poolFixedAverageRatePerSecond[pool]); // rate per second
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
