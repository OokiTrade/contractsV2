/**
 * Copyright 2017-2022, OokiDao. All Rights Reserved.
 * Licensed under the Apache License, Version 2.0.
 */

pragma solidity 0.5.17;
pragma experimental ABIEncoderV2;

import "./AdvancedTokenStorage.sol";
import "./StorageExtension.sol";
import "../../../interfaces/IBZx.sol";
import "../../interfaces/ICurvedInterestRate.sol";

contract LoanTokenSettingsLowerAdmin is AdvancedTokenStorage, StorageExtension {
    using SafeMath for uint256;

    //address public constant bZxContract = 0xD8Ee69652E4e4838f2531732a46d1f7F584F0b7f; // mainnet
    //address public constant bZxContract = 0x5cfba2639a3db0D9Cc264Aa27B2E6d134EeA486a; // kovan
    //address public constant bZxContract = 0xD154eE4982b83a87b0649E5a7DDA1514812aFE1f; // bsc
    //address public constant bZxContract = 0x059D60a9CEfBc70b9Ea9FFBb9a041581B1dFA6a8; // polygon
    address public constant bZxContract = 0x37407F3178ffE07a6cF5C847F8f680FEcf319FAB; // arbitrum

    bytes32 internal constant iToken_LowerAdminAddress = 0x7ad06df6a0af6bd602d90db766e0d5f253b45187c3717a0f9026ea8b10ff0d4b;    // keccak256("iToken_LowerAdminAddress")
    bytes32 internal constant iToken_LowerAdminContract = 0x34b31cff1dbd8374124bd4505521fc29cab0f9554a5386ba7d784a4e611c7e31;   // keccak256("iToken_LowerAdminContract")

    function()
        external
    {
        revert("fallback not allowed");
    }

    function setupLoanParams(
        IBZx.LoanParams[] memory loanParamsList,
        bool areTorqueLoans)
        public
    {
        bytes32[] memory loanParamsIdList;
        address _loanTokenAddress = loanTokenAddress;

        for (uint256 i = 0; i < loanParamsList.length; i++) {
            loanParamsList[i].loanToken = _loanTokenAddress;
            loanParamsList[i].maxLoanTerm = areTorqueLoans ? 0 : 28 days;
        }
        loanParamsIdList = IBZx(bZxContract).setupLoanParams(loanParamsList);
        for (uint256 i = 0; i < loanParamsIdList.length; i++) {
            loanParamsIds[uint256(keccak256(abi.encodePacked(
                loanParamsList[i].collateralToken,
                areTorqueLoans // isTorqueLoan
            )))] = loanParamsIdList[i];
        }
    }

    function disableLoanParams(
        address[] memory collateralTokens,
        bool[] memory isTorqueLoans)
        public
    {
        require(collateralTokens.length == isTorqueLoans.length, "count mismatch");

        bytes32[] memory loanParamsIdList = new bytes32[](collateralTokens.length);
        for (uint256 i = 0; i < collateralTokens.length; i++) {
            uint256 id = uint256(keccak256(abi.encodePacked(
                collateralTokens[i],
                isTorqueLoans[i]
            )));
            loanParamsIdList[i] = loanParamsIds[id];
            delete loanParamsIds[id];
        }

        IBZx(bZxContract).disableLoanParams(loanParamsIdList);
    }

    function disableLoanParamsAll(address[] memory collateralTokens, bool[][] memory isTorqueLoans) public {
        disableLoanParams(collateralTokens, isTorqueLoans[0]);
        disableLoanParams(collateralTokens, isTorqueLoans[1]);
    }

    // These params should be percentages represented like so: 5% = 5000000000000000000
    // rateMultiplier + baseRate can't exceed 100%
    // function setDemandCurve(
    //     uint256 _baseRate,
    //     uint256 _rateMultiplier,
    //     uint256 _lowUtilBaseRate,
    //     uint256 _lowUtilRateMultiplier,
    //     uint256 _targetLevel,
    //     uint256 _kinkLevel,
    //     uint256 _maxScaleRate)
    //     public
    // {
    //     require(_rateMultiplier.add(_baseRate) <= WEI_PERCENT_PRECISION, "curve params too high");
    //     require(_lowUtilRateMultiplier.add(_lowUtilBaseRate) <= WEI_PERCENT_PRECISION, "curve params too high");

    //     require(_targetLevel <= WEI_PERCENT_PRECISION && _kinkLevel <= WEI_PERCENT_PRECISION, "levels too high");

    //     baseRate = _baseRate;
    //     rateMultiplier = _rateMultiplier;
    //     lowUtilBaseRate = _lowUtilBaseRate;
    //     lowUtilRateMultiplier = _lowUtilRateMultiplier;

    //     targetLevel = _targetLevel; // 80 ether
    //     kinkLevel = _kinkLevel; // 90 ether
    //     maxScaleRate = _maxScaleRate; // 100 ether
    // }

    function setDemandCurve(
        ICurvedInterestRate _rateHelper)
        public
    {
        require(address(_rateHelper) != address(0), "no zero address");
        rateHelper = _rateHelper;
    }
}
