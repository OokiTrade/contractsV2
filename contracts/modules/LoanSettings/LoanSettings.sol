/**
 * Copyright 2017-2022, OokiDao. All Rights Reserved.
 * Licensed under the Apache License, Version 2.0.
 */

pragma solidity 0.5.17;
pragma experimental ABIEncoderV2;

import "../../core/State.sol";
import "../../events/LoanSettingsEvents.sol";
import "../../utils/MathUtil.sol";
import "../../mixins/InterestHandler.sol";


contract LoanSettings is State, InterestHandler, LoanSettingsEvents {
    using MathUtil for uint256;
    
    function initialize(
        address target)
        external
        onlyOwner
    {
        _setTarget(this.setupLoanParams.selector, target);
        _setTarget(this.disableLoanParams.selector, target);
        _setTarget(this.getLoanParams.selector, target);
        _setTarget(this.getLoanParamsList.selector, target);
        _setTarget(this.getTotalPrincipal.selector, target);
        _setTarget(this.getPoolPrincipalStored.selector, target);
        _setTarget(this.getPoolLastInterestRate.selector, target);
        _setTarget(this.getLoanPrincipal.selector, target);
        _setTarget(this.getLoanInterestOutstanding.selector, target);
    }

    function setupLoanParams(
        LoanParams[] calldata loanParamsList)
        external
        returns (bytes32[] memory loanParamsIdList)
    {
        loanParamsIdList = new bytes32[](loanParamsList.length);
        for (uint256 i = 0; i < loanParamsList.length; i++) {
            loanParamsIdList[i] = _setupLoanParams(loanParamsList[i]);
        }
    }

    // Deactivates LoanParams for future loans. Active loans using it are unaffected.
    function disableLoanParams(
        bytes32[] calldata loanParamsIdList)
        external
    {
        for (uint256 i = 0; i < loanParamsIdList.length; i++) {
            require(msg.sender == loanParams[loanParamsIdList[i]].owner, "unauthorized owner");
            loanParams[loanParamsIdList[i]].active = false;

            LoanParams memory loanParamsLocal = loanParams[loanParamsIdList[i]];
            emit LoanParamsDisabled(
                loanParamsLocal.id,
                loanParamsLocal.owner,
                loanParamsLocal.loanToken,
                loanParamsLocal.collateralToken,
                loanParamsLocal.minInitialMargin,
                loanParamsLocal.maintenanceMargin,
                loanParamsLocal.maxLoanTerm
            );
            emit LoanParamsIdDisabled(
                loanParamsLocal.id,
                loanParamsLocal.owner
            );
        }
    }

    function getLoanParams(
        bytes32[] memory loanParamsIdList)
        public
        view
        returns (LoanParams[] memory loanParamsList)
    {
        loanParamsList = new LoanParams[](loanParamsIdList.length);
        uint256 itemCount;

        for (uint256 i = 0; i < loanParamsIdList.length; i++) {
            LoanParams memory loanParamsLocal = loanParams[loanParamsIdList[i]];
            if (loanParamsLocal.id == 0) {
                continue;
            }
            loanParamsList[itemCount] = loanParamsLocal;
            itemCount++;
        }

        if (itemCount < loanParamsList.length) {
            assembly {
                mstore(loanParamsList, itemCount)
            }
        }
    }

    function getLoanParamsList(
        address owner,
        uint256 start,
        uint256 count)
        external
        view
        returns (bytes32[] memory loanParamsList)
    {
        EnumerableBytes32Set.Bytes32Set storage set = userLoanParamSets[owner];
        uint256 end = start.add(count).min256(set.length());
        if (start >= end) {
            return loanParamsList;
        }
        count = end-start;

        loanParamsList = new bytes32[](count);
        for (uint256 i = --end; i >= start; i--) {
            loanParamsList[--count] = set.get(i);

            if (i == 0) {
                break;
            }
        }
    }

    function getTotalPrincipal(
        address lender,
        address /*loanToken*/)
        external
        view
        returns (uint256)
    {
        return _getPoolPrincipal(
            lender
        );
    }

    function getPoolPrincipalStored(
        address pool)
        external
        view
        returns (uint256)
    {
        uint256 _poolInterestTotal = poolInterestTotal[pool];
        uint256 lendingFee = _poolInterestTotal
            .mul(lendingFeePercent)
            .divCeil(WEI_PERCENT_PRECISION);

        return poolPrincipalTotal[pool]
            .add(_poolInterestTotal)
            .sub(lendingFee);
    }

    function getPoolLastInterestRate(
        address pool)
        external
        view
        returns (uint256)
    {
        return poolLastInterestRate[pool];
    }

    function getLoanPrincipal(
        bytes32 loanId)
        external
        view
        returns (uint256)
    {
        Loan memory loanLocal = loans[loanId];
        if (!loanLocal.active) {
            return 0;
        }

        return _getLoanPrincipal(
            loanLocal.lender,
            loanId
        );
    }

    function getLoanInterestOutstanding(
        bytes32 loanId)
        external
        view
        returns (uint256 loanInterest)
    {
        Loan memory loanLocal = loans[loanId];
        if (!loanLocal.active) {
            return 0;
        }

        loanInterest = (_settleInterest2(
            loanLocal.lender,
            loanId,
            false
        ))[5];
    }

    function _setupLoanParams(
        LoanParams memory loanParamsLocal)
        internal
        returns (bytes32)
    {
        bytes32 loanParamsId = keccak256(abi.encode(
            loanParamsLocal.loanToken,
            loanParamsLocal.collateralToken,
            loanParamsLocal.minInitialMargin,
            loanParamsLocal.maintenanceMargin,
            loanParamsLocal.maxLoanTerm,
            block.timestamp
        ));
        require(loanParams[loanParamsId].id == 0, "loanParams exists");

        require(loanParamsLocal.loanToken != address(0) &&
            loanParamsLocal.collateralToken != address(0) &&
            loanParamsLocal.minInitialMargin > loanParamsLocal.maintenanceMargin &&
            (loanParamsLocal.maxLoanTerm == 0 || loanParamsLocal.maxLoanTerm > 1 hours), // a defined maxLoanTerm has to be greater than one hour
            "invalid params"
        );

        loanParamsLocal.id = loanParamsId;
        loanParamsLocal.active = true;
        loanParamsLocal.owner = msg.sender;

        loanParams[loanParamsId] = loanParamsLocal;
        userLoanParamSets[msg.sender].addBytes32(loanParamsId);

        emit LoanParamsSetup(
            loanParamsId,
            loanParamsLocal.owner,
            loanParamsLocal.loanToken,
            loanParamsLocal.collateralToken,
            loanParamsLocal.minInitialMargin,
            loanParamsLocal.maintenanceMargin,
            loanParamsLocal.maxLoanTerm
        );
        emit LoanParamsIdSetup(
            loanParamsId,
            loanParamsLocal.owner
        );

        return loanParamsId;
    }
}