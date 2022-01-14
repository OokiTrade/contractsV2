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

    // returns up to date loan interest or 0 if not applicable
    function _settleInterest(
        address pool,
        bytes32 loanId)
        internal
        returns (uint256 _loanInterestTotal)
    {
        uint256 _loanRatePerTokenPaid;
        (
            , // poolPrincipalTotal
            poolInterestTotal[pool],
            poolRatePerTokenStored[pool],
            , // loanPrincipalTotal,
            _loanInterestTotal,
            _loanRatePerTokenPaid) = _settleInterest2(
            pool,
            loanId
        );

        if (loanId != 0) {
            loanInterestTotal[loanId] = _loanInterestTotal;
            loanRatePerTokenPaid[loanId] = _loanRatePerTokenPaid;
        }

        poolLastUpdateTime[pool] = block.timestamp;
    }

    function _getPoolPrincipal(
        address pool)
        internal
        view
        returns (uint256)
    {
        (uint256 _poolPrincipalTotal, uint256 _poolInterestTotal,,,,) = _settleInterest2(
            pool,
            0
        );
        return _poolPrincipalTotal.add(_poolInterestTotal);
    }

    function _getLoanPrincipal(
        address pool,
        bytes32 loanId)
        internal
        view
        returns (uint256)
    {
        (,,,uint256 _loanPrincipalTotal,uint256 _loanInterestTotal,) = _settleInterest2(
            pool,
            loanId
        );
        return _loanPrincipalTotal.add(_loanInterestTotal);
    }

    function _settleInterest2(
        address pool,
        bytes32 loanId)
        internal
        view
        returns (
            uint256 _poolPrincipalTotal,
            uint256 _poolInterestTotal,
            uint256 _poolRatePerTokenStored,
            uint256 _loanPrincipalTotal,
            uint256 _loanInterestTotal,
            uint256 _loanRatePerTokenPaid
        )
    {
        _poolPrincipalTotal = poolPrincipalTotal[pool];
        uint256 _poolVariableRatePerTokenNewAmount = _getRatePerTokenNewAmount(_poolPrincipalTotal, pool);

        _poolInterestTotal = _poolPrincipalTotal
            .mul(_poolVariableRatePerTokenNewAmount)
            .div(WEI_PERCENT_PRECISION * WEI_PERCENT_PRECISION)
            .add(poolInterestTotal[pool]);

        _poolRatePerTokenStored = poolRatePerTokenStored[pool]
            .add(_poolVariableRatePerTokenNewAmount);

         if (loanId != 0 && (_loanPrincipalTotal = loans[loanId].principal) != 0) {
            _loanInterestTotal = _loanPrincipalTotal
                .mul(_poolRatePerTokenStored.sub(loanRatePerTokenPaid[loanId])) // _loanRatePerTokenUnpaid
                .div(WEI_PERCENT_PRECISION * WEI_PERCENT_PRECISION)
                .add(loanInterestTotal[loanId]);

            _loanRatePerTokenPaid = _poolRatePerTokenStored;
        }
    }

    function _getRatePerTokenNewAmount(
        uint256 _poolPrincipalTotal,
        address pool)
        internal
        view
        returns (uint256)
    {
        return block.timestamp
            .sub(poolLastUpdateTime[pool])
            .mul(ILoanPool(pool)._nextBorrowInterestRate(_poolPrincipalTotal, 0)) // rate per year
            .mul(WEI_PERCENT_PRECISION)
            .div(31536000); // seconds in a year
    }
}
