/**
 * Copyright 2017-2022, OokiDao. All Rights Reserved.
 * Licensed under the Apache License, Version 2.0.
 */

pragma solidity ^0.8.0;

import "../../core/State.sol";
import "../../events/LoanMaintenanceEvents.sol";
import "../../governance/PausableGuardian_0_8.sol";
import "../../mixins/InterestHandler.sol";
import "../../utils/InterestOracle.sol";
import "../../utils/TickMathV1.sol";

contract LoanMaintenance_2 is State, LoanMaintenanceEvents, PausableGuardian_0_8, InterestHandler {
    using EnumerableBytes32Set for EnumerableBytes32Set.Bytes32Set;
    using InterestOracle for InterestOracle.Observation[256];
    function initialize(
        address target)
        external
        onlyOwner
    {
        _setTarget(this.transferLoan.selector, target);
        _setTarget(this.settleInterest.selector, target);
        _setTarget(this.getInterestModelValues.selector, target);
        _setTarget(this.getTWAI.selector, target);
    }

    function getInterestModelValues(
        address pool,
        bytes32 loanId)
        external
        view
        returns (
            uint256 _poolLastUpdateTime,
            uint256 _poolPrincipalTotal,
            uint256 _poolInterestTotal,
            uint256 _poolRatePerTokenStored,
            uint256 _poolLastInterestRate,
            uint256 _loanPrincipalTotal,
            uint256 _loanInterestTotal,
            uint256 _loanRatePerTokenPaid)
    {
        _poolLastUpdateTime = poolLastUpdateTime[pool];
        _poolPrincipalTotal = poolPrincipalTotal[pool];
        _poolInterestTotal = poolInterestTotal[pool];
        _poolRatePerTokenStored = poolRatePerTokenStored[pool];
        _poolLastInterestRate = poolLastInterestRate[pool];

        _loanPrincipalTotal = loans[loanId].principal;
        _loanInterestTotal = loanInterestTotal[loanId];
        _loanRatePerTokenPaid = loanRatePerTokenPaid[loanId];
    }

    function transferLoan(
        bytes32 loanId,
        address newOwner)
        external
        nonReentrant
        pausable
    {
        Loan storage loanLocal = loans[loanId];
        address currentOwner = loanLocal.borrower;
        require(loanLocal.active, "loan is closed");
        require(currentOwner != newOwner, "no owner change");
        require(
            msg.sender == currentOwner ||
            delegatedManagers[loanId][msg.sender],
            "unauthorized"
        );

        require(borrowerLoanSets[currentOwner].removeBytes32(loanId), "error in transfer");
        borrowerLoanSets[newOwner].addBytes32(loanId);
        loanLocal.borrower = newOwner;

        emit TransferLoan(
            currentOwner,
            newOwner,
            loanId
        );
    }

    function settleInterest(
        bytes32 loanId)
        external
        pausable
    {
        // only callable by loan pools
        require(loanPoolToUnderlying[msg.sender] != address(0), "not authorized");

        _settleInterest(
            msg.sender, // loan pool
            loanId
        );
    }

    function getTWAI(
        address pool)
        external
        view
        returns (uint256)
    {
        uint32 timeSinceUpdate = uint32(block.timestamp - poolLastUpdateTime[pool]);
        return TickMathV1.getSqrtRatioAtTick(poolInterestRateObservations[pool].arithmeticMean(
            uint32(block.timestamp),
            [timeSinceUpdate+twaiLength, timeSinceUpdate],
            timeSinceUpdate >= 60 ?
                TickMathV1.getTickAtSqrtRatio(uint160(poolLastInterestRate[pool])) :
                poolInterestRateObservations[pool][poolLastIdx[pool]].tick,
            poolLastIdx[pool],
            type(uint8).max
        ));
    }
    
}
