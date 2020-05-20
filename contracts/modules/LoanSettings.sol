/**
 * Copyright 2017-2020, bZeroX, LLC. All Rights Reserved.
 * Licensed under the Apache License, Version 2.0.
 */

pragma solidity 0.5.17;
pragma experimental ABIEncoderV2;

import "../core/State.sol";
import "../events/LoanSettingsEvents.sol";
import "../mixins/VaultController.sol";


contract LoanSettings is State, LoanSettingsEvents, VaultController {

    constructor() public {}

    function()
        external
    {
        revert("fallback not allowed");
    }

    function initialize(
        address target)
        external
        onlyOwner
    {
        logicTargets[this.setupLoanParams.selector] = target;
        logicTargets[this.setupOrder.selector] = target;
        logicTargets[this.setupOrderWithId.selector] = target;
        logicTargets[this.depositToOrder.selector] = target;
        logicTargets[this.withdrawFromOrder.selector] = target;
        logicTargets[this.disableLoanParams.selector] = target;
        logicTargets[this.getLoanParams.selector] = target;
        logicTargets[this.getLoanParamsBatch.selector] = target;
        logicTargets[this.getLoanParamsList.selector] = target;
        logicTargets[this.getTotalPrincipal.selector] = target;
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

    function setupOrder(
        LoanParams calldata loanParamsLocal,
        uint256 lockedAmount,
        uint256 interestRate,
        uint256 minLoanTerm,
        uint256 maxLoanTerm,
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
            minLoanTerm,
            maxLoanTerm,
            expirationStartTimestamp,
            isLender
        );
    }

    function setupOrderWithId(
        bytes32 loanParamsId,
        uint256 lockedAmount, // initial deposit
        uint256 interestRate,
        uint256 minLoanTerm,
        uint256 maxLoanTerm,
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
            minLoanTerm,
            maxLoanTerm,
            expirationStartTimestamp,
            isLender
        );
    }

    function depositToOrder(
        bytes32 loanParamsId,
        uint256 depositAmount,
        bool isLender)
        external
        payable
    {
        _changeOrderBalance(
            loanParamsId,
            depositAmount, // changeAmount,
            isLender,
            true // isDeposit
        );
    }

    function withdrawFromOrder(
        bytes32 loanParamsId,
        uint256 depositAmount,
        bool isLender)
        external
        payable
    {
        _changeOrderBalance(
            loanParamsId,
            depositAmount, // changeAmount,
            isLender,
            false // isDeposit
        );
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
        bytes32 loanParamsId)
        public
        view
        returns (LoanParams memory)
    {
        return loanParams[loanParamsId];
    }

    function getLoanParamsBatch(
        bytes32[] memory loanParamsIdList)
        public
        view
        returns (LoanParams[] memory loanParamsList)
    {
        loanParamsList = new LoanParams[](loanParamsIdList.length);
        uint256 itemCount;

        for (uint256 i = 0; i < loanParamsIdList.length; i++) {
            LoanParams memory loanParamsLocal = getLoanParams(loanParamsIdList[i]);
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

        uint256 end = count.min256(set.values.length);
        if (end == 0 || start >= end) {
            return loanParamsList;
        }

        loanParamsList = new bytes32[](count);
        uint256 itemCount;
        for (uint256 i = end-start; i > 0; i--) {
            if (itemCount == count) {
                break;
            }
            loanParamsList[itemCount] = set.get(i+start-1);
            itemCount++;
        }

        if (itemCount < count) {
            assembly {
                mstore(loanParamsList, itemCount)
            }
        }
    }

    function getTotalPrincipal(
        address lender,
        address loanToken)
        external
        view
        returns (uint256)
    {
        return lenderInterest[lender][loanToken].principalTotal;
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
            loanParamsLocal.minInitialMargin > loanParamsLocal.maintenanceMargin,
            "invalid params"
        );

        loanParamsLocal.id = loanParamsId;
        loanParamsLocal.active = true;
        loanParamsLocal.owner = msg.sender;

        loanParams[loanParamsId] = loanParamsLocal;
        userLoanParamSets[msg.sender].add(loanParamsId);

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

    function _setupOrder(
        LoanParams memory loanParamsLocal,
        uint256 lockedAmount,
        uint256 interestRate,
        uint256 minLoanTerm,
        uint256 maxLoanTerm,
        uint256 expirationStartTimestamp,
        bool isLender)
        internal
    {
        require(msg.value == 0 || loanParamsLocal.collateralToken == address(wethToken), "wrong asset sent");
        require(lockedAmount != 0 && (msg.value == 0 || msg.value == lockedAmount), "insufficient asset sent");

        Order memory orderLocal = isLender ?
            lenderOrders[msg.sender][loanParamsLocal.id] :
            borrowerOrders[msg.sender][loanParamsLocal.id];
        require(orderLocal.createdStartTimestamp == 0, "order exists");

        require(maxLoanTerm >= minLoanTerm, "invalid term range");

        orderLocal.lockedAmount = lockedAmount;
        orderLocal.interestRate = interestRate;
        orderLocal.minLoanTerm = minLoanTerm;
        orderLocal.maxLoanTerm = maxLoanTerm;
        orderLocal.createdStartTimestamp = block.timestamp;
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
            vaultEtherDeposit(
                msg.sender,
                lockedAmount // == msg.value
            );
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

    function _changeOrderBalance(
        bytes32 loanParamsId,
        uint256 changeAmount,
        bool isLender,
        bool isDeposit)
        internal
    {
        LoanParams memory loanParamsLocal = loanParams[loanParamsId];
        require(loanParamsLocal.id != 0, "loanParams not exists");

        Order memory orderLocal = isLender ?
            lenderOrders[msg.sender][loanParamsLocal.id] :
            borrowerOrders[msg.sender][loanParamsLocal.id];
        require(orderLocal.createdStartTimestamp != 0, "order not exists");

        uint256 oldLockedAmount = orderLocal.lockedAmount;

        if (isDeposit) {
            require(msg.value == 0 || loanParamsLocal.collateralToken == address(wethToken), "wrong asset sent");
            require(changeAmount != 0 && (msg.value == 0 || msg.value == changeAmount), "insufficient asset sent");

            orderLocal.lockedAmount = orderLocal.lockedAmount
                .add(changeAmount);

            if (msg.value == 0) {
                vaultDeposit(
                    isLender ?
                        loanParamsLocal.loanToken :
                        loanParamsLocal.collateralToken,
                    msg.sender,
                    changeAmount
                );
            } else {
                vaultEtherDeposit(
                    msg.sender,
                    changeAmount // == msg.value
                );
            }
        } else {
            require(msg.value == 0, "ether sent");
            require(changeAmount <= orderLocal.lockedAmount, "insufficient lockedAmount");

            orderLocal.lockedAmount = orderLocal.lockedAmount
                .sub(changeAmount);

            if (loanParamsLocal.collateralToken == address(wethToken)) {
                vaultWithdraw(
                    isLender ?
                        loanParamsLocal.loanToken :
                        loanParamsLocal.collateralToken,
                    msg.sender,
                    changeAmount
                );
            } else {
                vaultEtherWithdraw(
                    msg.sender,
                    changeAmount
                );
            }

        }

        if (isLender) {
            lenderOrders[msg.sender][loanParamsLocal.id] = orderLocal;
        } else {
            borrowerOrders[msg.sender][loanParamsLocal.id] = orderLocal;
        }

        emit LoanOrderChangeAmount(
            loanParamsLocal.id,
            msg.sender,
            isLender,
            oldLockedAmount,
            orderLocal.lockedAmount
        );
    }
}