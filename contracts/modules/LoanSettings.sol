/**
 * Copyright 2017-2020, bZeroX, LLC. All Rights Reserved.
 * Licensed under the Apache License, Version 2.0.
 */

pragma solidity 0.5.17;
pragma experimental ABIEncoderV2;

import "../core/State.sol";

import "../mixins/VaultController.sol";


contract LoanSettings is State, VaultController {

    event LoanParamsSetup(
        bytes32 indexed id,
        address owner,
        address indexed loanToken,
        address indexed collateralToken,
        uint256 initialMargin,
        uint256 maintenanceMargin,
        uint256 maxLoanDuration
    );
    event LoanParamsIdSetup(
        bytes32 indexed id,
        address indexed owner
    );

    event LoanParamsDisabled(
        bytes32 indexed id,
        address owner,
        address indexed loanToken,
        address indexed collateralToken,
        uint256 initialMargin,
        uint256 maintenanceMargin,
        uint256 maxLoanDuration
    );
    event LoanParamsIdDisabled(
        bytes32 indexed id,
        address indexed owner
    );

    event LoanOrderSetup(
        bytes32 indexed loanParamsId,
        address indexed owner,
        bool indexed isLender,
        uint256 lockedAmount,
        uint256 interestRate,
        uint256 expirationStartTimestamp
    );

    constructor() public {}

    function()
        external
    {
        revert("fallback not allowed");
    }

    // Setup for new LoanParams
    // setupLoanParams((bytes32,bool,address,address,address,uint256,uint256,uint256))
    // setupLoanParams((bytes32,bool,address,address,address,uint256,uint256,uint256)[])
    function setupLoanParams(
        LoanParams calldata loanParamsLocal)
        external
    {
        _setupLoanParams(loanParamsLocal);
    }
    function setupLoanParams(
        LoanParams[] calldata loanParamsList)
        external
    {
        for (uint256 i=0; i < loanParamsList.length; i++) {
            _setupLoanParams(loanParamsList[i]);
        }
    }

    // setupOrder((bytes32,bool,address,address,address,uint256,uint256,uint256),uint256,uint256,uint256,bool)
    // setupOrder(uint256,uint256,uint256,uint256,bool)
    function setupOrder(
        LoanParams calldata loanParamsLocal,
        uint256 lockedAmount,
        uint256 interestRate,
        uint256 expirationStartTimestamp,
        bool isLender)
        external
        payable
    {
        bytes32 loanParamsId = _setupLoanParams(loanParamsLocal);
        _setupOrder(
            loanParams[loanParamsId],
            lockedAmount,
            interestRate,
            expirationStartTimestamp,
            isLender
        );
    }
    function setupOrder(
        bytes32 loanParamsId,
        uint256 lockedAmount, // initial deposit
        uint256 interestRate,
        uint256 expirationStartTimestamp,
        bool isLender)
        external
        payable
    {
        LoanParams memory loanParamsLocal = loanParams[loanParamsId];
        require(loanParamsLocal.id != 0, "loanParams not exists");
        _setupOrder(
            loanParamsLocal,
            lockedAmount,
            interestRate,
            expirationStartTimestamp,
            isLender
        );
    }

    // Deactivates LoanParams for future loans. Active loans using it are unaffected.
    // disableLoanParams(bytes32[])
    function disableLoanParams(
        bytes32[] calldata loanParamsIdList)
        external
    {
        for (uint256 i=0; i < loanParamsIdList.length; i++) {
            require(msg.sender == loanParams[loanParamsIdList[i]].owner, "unauthorized owner");
            loanParams[loanParamsIdList[i]].active = false;
            //loanParamsSet.remove(loanParamsIdList[i]);

            LoanParams memory loanParamsLocal = loanParams[loanParamsIdList[i]];
            emit LoanParamsDisabled(
                loanParamsLocal.id,
                loanParamsLocal.owner,
                loanParamsLocal.loanToken,
                loanParamsLocal.collateralToken,
                loanParamsLocal.initialMargin,
                loanParamsLocal.maintenanceMargin,
                loanParamsLocal.maxLoanDuration
            );
            emit LoanParamsIdDisabled(
                loanParamsLocal.id,
                loanParamsLocal.owner
            );
        }
    }

    // getLoanParams(bytes32[])
    /*function getLoanParams(
        bytes32[] calldata loanParamsIdList)
        external
        view
        returns (LoanParams[] memory loanParamsList)
    {
        loanParamsList = new LoanParams[](loanParamsIdList.length);
        uint256 itemCount;

        for (uint256 i=0; i < loanParamsIdList.length; i++) {
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
    }*/

    // getLoanParams(bytes32)
    function getLoanParams(
        bytes32 loanParamsId)
        external
        view
        returns (LoanParams memory)
    {
        return loanParams[loanParamsId];
    }


    function _setupLoanParams(
        LoanParams memory loanParamsLocal)
        internal
        returns (bytes32)
    {
        bytes32 loanParamsId = keccak256(abi.encodePacked(
            loanParamsLocal.loanToken,
            loanParamsLocal.collateralToken,
            block.timestamp
        ));
        require(loanParams[loanParamsId].id == 0, "loanParams exists");

        require(loanParamsLocal.loanToken != address(0) &&
            loanParamsLocal.collateralToken != address(0) &&
            loanParamsLocal.initialMargin > loanParamsLocal.maintenanceMargin,
            "invalid params"
        );

        loanParamsLocal.id = loanParamsId;
        loanParamsLocal.active = true;
        loanParamsLocal.owner = msg.sender;

        loanParams[loanParamsId] = loanParamsLocal;
        //loanParamsSet.add(loanParamsId);

        emit LoanParamsSetup(
            loanParamsId,
            loanParamsLocal.owner,
            loanParamsLocal.loanToken,
            loanParamsLocal.collateralToken,
            loanParamsLocal.initialMargin,
            loanParamsLocal.maintenanceMargin,
            loanParamsLocal.maxLoanDuration
        );
        emit LoanParamsIdSetup(
            loanParamsId,
            loanParamsLocal.owner
        );

        return loanParamsId;
    }

    function _setupOrder(
        LoanParams memory loanParamsLocal,
        uint256 lockedAmount,
        uint256 interestRate,
        uint256 expirationStartTimestamp,
        bool isLender)
        internal
    {
        require(msg.value == 0 || loanParamsLocal.collateralToken == address(wethToken), "wrong asset sent");
        require(lockedAmount != 0 && (msg.value == 0 || msg.value == lockedAmount), "insufficient asset sent");

        Order memory orderLocal = isLender ?
            lenderOrders[msg.sender][loanParamsLocal.id] :
            borrowerOrders[msg.sender][loanParamsLocal.id];
        require(orderLocal.lockedAmount == 0, "order exists");

        orderLocal.lockedAmount = lockedAmount;
        orderLocal.interestRate = interestRate;
        orderLocal.expirationStartTimestamp = expirationStartTimestamp;
        if (isLender) {
            lenderOrders[msg.sender][loanParamsLocal.id] = orderLocal;
        } else {
            borrowerOrders[msg.sender][loanParamsLocal.id] = orderLocal;
        }

        if (msg.value == 0) {
            vaultDeposit(
                isLender ?
                    loanParamsLocal.loanToken :
                    loanParamsLocal.collateralToken,
                msg.sender,
                lockedAmount
            );
        } else {
            vaultEtherDeposit(msg.value);
        }

        emit LoanOrderSetup(
            loanParamsLocal.id,
            msg.sender,
            isLender,
            lockedAmount,
            interestRate,
            expirationStartTimestamp
        );
    }
}