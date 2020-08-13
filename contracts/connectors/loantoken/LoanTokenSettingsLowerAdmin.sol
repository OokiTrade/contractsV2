/**
 * Copyright 2017-2020, bZeroX, LLC. All Rights Reserved.
 * Licensed under the Apache License, Version 2.0.
 */

// SPDX-License-Identifier: GNU 
pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

import "./AdvancedTokenStorage.sol";
import "./interfaces/ProtocolSettingsLike.sol";


contract LoanTokenSettingsLowerAdmin is AdvancedTokenStorage {
    using SafeMath for uint256;

    //address public constant bZxContract = 0xAbd9372723C735D426D0a760D047206Fe115ee6d; // mainnet
    address public constant bZxContract = 0xAbd9372723C735D426D0a760D047206Fe115ee6d; // kovan

    modifier onlyAdmin() {
        address _lowerAdmin;
        //keccak256("iToken_LowerAdminAddress")
        assembly {
            _lowerAdmin := sload(0x7ad06df6a0af6bd602d90db766e0d5f253b45187c3717a0f9026ea8b10ff0d4b)
        }

        require(msg.sender == address(this) ||
            msg.sender == _lowerAdmin ||
            msg.sender == owner(), "unauthorized");
        _;
    }

    receive()
        external
    {
        revert("fallback not allowed");
    }

    function setupTorqueLoanParams(
        LoanParamsStruct.LoanParams[] memory loanParamsList)
        public
        onlyAdmin
    {
        bytes32[] memory loanParamsIdList;
        address _loanTokenAddress = loanTokenAddress;

        // setup torque loan params
        for (uint256 i = 0; i < loanParamsList.length; i++) {
            loanParamsList[i].loanToken = _loanTokenAddress;
            loanParamsList[i].maxLoanTerm = 0;
        }
        loanParamsIdList = ProtocolSettingsLike(bZxContract).setupLoanParams(loanParamsList);
        for (uint256 i = 0; i < loanParamsIdList.length; i++) {
            loanParamsIds[uint256(keccak256(abi.encodePacked(
                loanParamsList[i].collateralToken,
                true // isTorqueLoan
            )))] = loanParamsIdList[i];
        }
    }

    function setupMarginLoanParams(
        LoanParamsStruct.LoanParams[] memory loanParamsList)
        public
        onlyAdmin
    {
        bytes32[] memory loanParamsIdList;
        address _loanTokenAddress = loanTokenAddress;

        // setup margin loan params
        for (uint256 i = 0; i < loanParamsList.length; i++) {
            loanParamsList[i].loanToken = _loanTokenAddress;
            loanParamsList[i].maxLoanTerm = 2419200; // 28 days
        }
        loanParamsIdList = ProtocolSettingsLike(bZxContract).setupLoanParams(loanParamsList);
        for (uint256 i = 0; i < loanParamsIdList.length; i++) {
            loanParamsIds[uint256(keccak256(abi.encodePacked(
                loanParamsList[i].collateralToken,
                false // isTorqueLoan
            )))] = loanParamsIdList[i];
        }
    }

    function disableLoanParams(
        address[] calldata collateralTokens,
        bool[] calldata isTorqueLoans)
        external
        onlyAdmin
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

        ProtocolSettingsLike(bZxContract).disableLoanParams(loanParamsIdList);
    }

    // These params should be percentages represented like so: 5% = 5000000000000000000
    // rateMultiplier + baseRate can't exceed 100%
    function setDemandCurve(
        uint256 _baseRate,
        uint256 _rateMultiplier,
        uint256 _lowUtilBaseRate,
        uint256 _lowUtilRateMultiplier)
        public
        onlyAdmin
    {
        require(_rateMultiplier.add(_baseRate) <= 10**20, "");
        require(_lowUtilRateMultiplier.add(_lowUtilBaseRate) <= 10**20, "");

        baseRate = _baseRate;
        rateMultiplier = _rateMultiplier;
        lowUtilBaseRate = _lowUtilBaseRate;
        lowUtilRateMultiplier = _lowUtilRateMultiplier;
    }

    function toggleFunctionPause(
        string memory funcId,  // example: "mint(uint256,uint256)"
        bool isPaused)
        public
        onlyAdmin
    {
        // keccak256("iToken_FunctionPause")
        bytes32 slot = keccak256(abi.encodePacked(bytes4(keccak256(abi.encodePacked(funcId))), uint256(0xd46a704bc285dbd6ff5ad3863506260b1df02812f4f857c8cc852317a6ac64f2)));
        assembly {
            sstore(slot, isPaused)
        }
    }
}
