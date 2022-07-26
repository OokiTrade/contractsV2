/**
 * Copyright 2017-2022, OokiDao. All Rights Reserved.
 * Licensed under the Apache License, Version 2.0.
 */

pragma solidity 0.5.17;
pragma experimental ABIEncoderV2;

import "../../core/State.sol";
import "../../events/LoanSettingsEvents.sol";
import "../../utils/MathUtil.sol";
import "../../utils/InterestOracle.sol";
import "../../mixins/InterestHandler.sol";
import "../../governance/PausableGuardian.sol";
import "../../../interfaces/IPriceFeeds.sol";

contract LoanSettings is State, InterestHandler, LoanSettingsEvents, PausableGuardian {
    using MathUtil for uint256;
    using InterestOracle for InterestOracle.Observation[256];

    function initialize(address target) external onlyOwner {
        _setTarget(this.setupLoanPoolTWAI.selector, target);
        _setTarget(this.setTWAISettings.selector, target);
        _setTarget(this.disableLoanParams.selector, target);
        _setTarget(this.getTotalPrincipal.selector, target);
        _setTarget(this.getPoolPrincipalStored.selector, target);
        _setTarget(this.getPoolLastInterestRate.selector, target);
        _setTarget(this.getLoanPrincipal.selector, target);
        _setTarget(this.getLoanInterestOutstanding.selector, target);
        _setTarget(this.modifyLoanParams.selector, target);
        _setTarget(this.migrateLoanParamsList.selector, target); // TODO remove after migration

        // TODO remove after deployment
        _setTarget(bytes4(keccak256("setupLoanParams(LoanParams[])")), address(0));
        _setTarget(bytes4(keccak256("getLoanParamsList(address,uint256,uint256)")), address(0));
    }

    function setTWAISettings(uint32 delta, uint32 secondsAgo) external onlyGuardian {
        timeDelta = delta;
        twaiLength = secondsAgo;
    }

    function setupLoanPoolTWAI(address pool) external onlyGuardian {
        require(poolInterestRateObservations[pool][0].blockTimestamp == 0, "already initialized");

        if (poolLastUpdateTime[pool] == 0) {
            poolLastUpdateTime[pool] = block.timestamp;
        }

        poolInterestRateObservations[pool][0].blockTimestamp = uint32(poolLastUpdateTime[pool].sub(twaiLength + timeDelta));
        if (poolLastInterestRate[pool] < 1e11) {
            poolLastInterestRate[pool] = 1e11;
        }
    }

    // Deactivates LoanParams for future loans. Active loans using it are unaffected.
    function disableLoanParams(bytes32[] calldata loanParamsIdList) external onlyGuardian {
        for (uint256 i = 0; i < loanParamsIdList.length; i++) {
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
            emit LoanParamsIdDisabled(loanParamsLocal.id, loanParamsLocal.owner);
        }
    }

    function modifyLoanParams(LoanParams[] calldata loanParamsList) external onlyGuardian {
        for (uint256 i = 0; i < loanParamsList.length; i++) {
            require(
                supportedTokens[loanParamsList[i].loanToken] &&
                    supportedTokens[loanParamsList[i].collateralToken] &&
                    loanParamsList[i].id ==
                    generateLoanParamId(
                        loanParamsList[i].loanToken,
                        loanParamsList[i].collateralToken,
                        loanParamsList[i].maxLoanTerm == 0 // isTorqueLoan
                    ) &&
                    loanParamsList[i].minInitialMargin > loanParamsList[i].maintenanceMargin,
                "invalid loanParam"
            );
            LoanParams memory loanParam = loanParamsList[i];
            loanParams[loanParam.id] = loanParam;
            emit LoanParamsSetup(
                loanParamsList[i].id,
                loanParamsList[i].owner,
                loanParamsList[i].loanToken,
                loanParamsList[i].collateralToken,
                loanParamsList[i].minInitialMargin,
                loanParamsList[i].maintenanceMargin,
                loanParamsList[i].maxLoanTerm
            );
            emit LoanParamsIdSetup(loanParamsList[i].id, loanParamsList[i].owner);
        }
    }

    function migrateLoanParamsList(
        address owner,
        uint256 start,
        uint256 count
    ) external onlyGuardian {
        EnumerableBytes32Set.Bytes32Set storage set = userLoanParamSets[owner];
        uint256 end = start.add(count).min256(set.length());
        if (start >= end) {
            return;
        }
        
        bytes32 loanParamId;
        LoanParams memory loanParamsLocal;
        bytes32 oldLoanParamId;
        for (uint256 i = start; i < end; ++i) {
            oldLoanParamId = set.get(i);
            loanParamsLocal = loanParams[oldLoanParamId];
            loanParamId = generateLoanParamId(
                loanParamsLocal.loanToken,
                loanParamsLocal.collateralToken,
                loanParamsLocal.maxLoanTerm == 0 // isTorqueLoan
                    ? true
                    : false
            );
            loanParamsLocal.id = loanParamId;
            // delete loanParams[oldLoanParamId]; don't delete old so that existing positions can be closed
            loanParams[loanParamId] = loanParamsLocal;
            // userLoanParamSets[owner].removeBytes32(oldLoanParamId); removing in loop breaks the index. we don't really need to clean this up
        }
    }

    function generateLoanParamId(
        address loanToken,
        address collateralToken,
        bool isTorqueLoan
    ) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(loanToken, collateralToken, isTorqueLoan));
    }

    function getTotalPrincipal(
        address lender,
        address /*loanToken*/
    ) external view returns (uint256) {
        return _getPoolPrincipal(lender);
    }

    function getPoolPrincipalStored(address pool) external view returns (uint256) {
        uint256 _poolInterestTotal = poolInterestTotal[pool];
        uint256 lendingFee = _poolInterestTotal.mul(lendingFeePercent).divCeil(WEI_PERCENT_PRECISION);

        return poolPrincipalTotal[pool].add(_poolInterestTotal).sub(lendingFee);
    }

    function getPoolLastInterestRate(address pool) external view returns (uint256) {
        return poolLastInterestRate[pool];
    }

    function getLoanPrincipal(bytes32 loanId) external view returns (uint256) {
        Loan memory loanLocal = loans[loanId];
        if (!loanLocal.active) {
            return 0;
        }

        return _getLoanPrincipal(loanLocal.lender, loanId);
    }

    function getLoanInterestOutstanding(bytes32 loanId) external view returns (uint256 loanInterest) {
        Loan storage loanLocal = loans[loanId];
        if (!loanLocal.active) {
            return 0;
        }

        loanInterest = (_settleInterest2(loanLocal.lender, loanId, false))[5];
    }
}
