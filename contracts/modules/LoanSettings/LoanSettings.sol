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
        count = end - start;

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
            delete loanParams[oldLoanParamId];
            loanParams[loanParamId] = loanParamsLocal;
            userLoanParamSets[owner].removeBytes32(loanParamId);
        }
    }

    function generateLoanParamId(
        address loanToken,
        address collateralToken,
        bool isTorqueLoan
    ) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(loanToken, collateralToken, isTorqueLoan));
    }

    // // This function intends to be PUBLIC so that anyone can create params if loanToken and collateralToken are approved by the protocol
    // function createDefaultParams(
    //     address loanToken,
    //     address collateralToken,
    //     bool isTorqueLoan
    // ) external {
    //     // requires loanToken approved
    //     require(supportedTokens[loanToken], "loan not supported");
    //     // requires collateralToken approved
    //     require(supportedTokens[collateralToken], "collateral not supported");
    //     // requires there is a pricefeed
    //     require(IPriceFeeds(priceFeeds).pricesFeeds(collateralToken) != address(0), "no price feed");
    //     // requires param does not exist
    //     bytes32 loanParamId = generateLoanParamId(loanToken, collateralToken, isTorqueLoan);

    //     LoanParams memory loanParamsLocal;
    //     loanParamsLocal.active = true;
    //     loanParamsLocal.loanToken = loanToken;
    //     loanParamsLocal.collateralToken = collateralToken;
    //     loanParamsLocal.minInitialMargin = 20 ether;
    //     loanParamsLocal.maintenanceMargin = 15 ether;
    //     if (isTorqueLoan) {
    //         loanParamsLocal.maxLoanTerm = 0;
    //     } else {
    //         loanParamsLocal.maxLoanTerm = 28 days; // for historical reasons zero means torque loans non zero means fulcrum loans
    //     }

    //     loanParamsLocal.id = loanParamId;

    //     require(loanParams[loanParamId].id == 0, "params already exist");

    //     loanParams[loanParamId] = loanParamsLocal;

    //     // tripple healty check just as before
    //     require(
    //         loanParamsLocal.loanToken != address(0) &&
    //             loanParamsLocal.collateralToken != address(0) &&
    //             loanParamsLocal.minInitialMargin > loanParamsLocal.maintenanceMargin &&
    //             (loanParamsLocal.maxLoanTerm == 0 || loanParamsLocal.maxLoanTerm > 1 hours), // a defined maxLoanTerm has to be greater than one hour
    //         "invalid params"
    //     );

    //     emit LoanParamsSetup(
    //         loanParamId,
    //         loanParamsLocal.owner,
    //         loanParamsLocal.loanToken,
    //         loanParamsLocal.collateralToken,
    //         loanParamsLocal.minInitialMargin,
    //         loanParamsLocal.maintenanceMargin,
    //         loanParamsLocal.maxLoanTerm
    //     );
    //     emit LoanParamsIdSetup(loanParamId, loanParamsLocal.owner);
    // }

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
