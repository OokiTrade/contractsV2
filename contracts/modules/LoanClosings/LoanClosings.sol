/**
 * Copyright 2017-2022, OokiDao. All Rights Reserved.
 * Licensed under the Apache License, Version 2.0.
 */

pragma solidity ^0.8.0;

import "./LoanClosingsShared.sol";

contract LoanClosings is LoanClosingsShared {

    function initialize(
        address target)
        external
        onlyOwner
    {
        // TODO remove after migration
        _setTarget(bytes4(keccak256("closeWithDeposit(bytes32,address,uint256)")), address(0));
        _setTarget(bytes4(keccak256("closeWithSwap(bytes32,address,uint256)")), address(0));

        _setTarget(this.closeWithDeposit.selector, target);
        _setTarget(this.closeWithSwap.selector, target);
    }

    function closeWithDeposit(
        bytes32 loanId,
        address receiver,
        uint256 depositAmount, // denominated in loanToken
        bytes memory loanDataBytes)
        public
        payable
        nonReentrant
        returns (
            uint256 loanCloseAmount,
            uint256 withdrawAmount,
            address withdrawToken
        )
    {
        return _closeWithDeposit(
            loanId,
            receiver,
            depositAmount,
            loanDataBytes
        );
    }

    function closeWithSwap(
        bytes32 loanId,
        address receiver,
        uint256 swapAmount, // denominated in collateralToken
        bool returnTokenIsCollateral, // true: withdraws collateralToken, false: withdraws loanToken
        bytes memory loanDataBytes)
        public
        nonReentrant
        returns (
            uint256 loanCloseAmount,
            uint256 withdrawAmount,
            address withdrawToken
        )
    {
        return _closeWithSwap(
            loanId,
            receiver,
            swapAmount,
            returnTokenIsCollateral,
            loanDataBytes
        );
    }

    function _checkPermit(address token, bytes memory loanDataBytes) internal {
        if (loanDataBytes.length != 0) {
            if(abi.decode(loanDataBytes, (uint128)) & WITH_PERMIT != 0) {
                (uint128 f, bytes[] memory payload) = abi.decode(
                    loanDataBytes,
                    (uint128, bytes[])
                );
                (address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) = abi.decode(payload[2], (address, address, uint, uint, uint8, bytes32, bytes32));
                require(spender == address(this), "Permit");
                IERC20Permit(token).permit(owner, spender, value, deadline, v, r, s);
            }
        }
    }

    function _closeWithDeposit(
        bytes32 loanId,
        address receiver,
        uint256 depositAmount, // denominated in loanToken
        bytes memory loanDataBytes)
        internal
        pausable
        returns (
            uint256 loanCloseAmount,
            uint256 withdrawAmount,
            address withdrawToken
        )
    {
        require(depositAmount != 0, "depositAmount == 0");

        Loan memory loanLocal = loans[loanId];
        _checkAuthorized(
            loanLocal.id,
            loanLocal.active,
            loanLocal.borrower
        );

        if (receiver == address(0)) {
            receiver = msg.sender;
        }

        LoanParams memory loanParamsLocal = loanParams[loanLocal.loanParamsId];

        _checkPermit(loanParamsLocal.loanToken, loanDataBytes);

        uint256 principalPlusInterest = _settleInterest(loanLocal.lender, loanId) + loanLocal.principal;

        // can't close more than the full principal
        loanCloseAmount = depositAmount > principalPlusInterest ?
            principalPlusInterest :
            depositAmount;

        if (loanCloseAmount != 0) {
            _returnPrincipalWithDeposit(
                loanParamsLocal.loanToken,
                loanLocal.lender,
                loanCloseAmount
            );
        }

        if (loanCloseAmount == principalPlusInterest) {
            // collateral is only withdrawn if the loan is closed in full
            withdrawAmount = loanLocal.collateral;
            withdrawToken = loanParamsLocal.collateralToken;
            loanLocal.collateral = 0;

            _withdrawAsset(
                withdrawToken,
                receiver,
                withdrawAmount
            );
        }

        _finalizeClose(
            loanLocal,
            loanParamsLocal,
            loanCloseAmount,
            withdrawAmount, // collateralCloseAmount
            0, // collateralToLoanSwapRate
            CloseTypes.Deposit
        );
    }

    function _closeWithSwap(
        bytes32 loanId,
        address receiver,
        uint256 swapAmount,
        bool returnTokenIsCollateral,
        bytes memory loanDataBytes)
        internal
        pausable
        returns (
            uint256 loanCloseAmount,
            uint256 withdrawAmount,
            address withdrawToken
        )
    {
        require(swapAmount != 0, "swapAmount == 0");

        Loan memory loanLocal = loans[loanId];
        _checkAuthorized(
            loanLocal.id,
            loanLocal.active,
            loanLocal.borrower
        );

        if (receiver == address(0)) {
            receiver = msg.sender;
        }

        LoanParams memory loanParamsLocal = loanParams[loanLocal.loanParamsId];

        uint256 principalPlusInterest = _settleInterest(loanLocal.lender, loanId) + loanLocal.principal;

        if (swapAmount > loanLocal.collateral) {
            swapAmount = loanLocal.collateral;
        }

        loanCloseAmount = principalPlusInterest;
        if (swapAmount != loanLocal.collateral) {
            loanCloseAmount = loanCloseAmount * swapAmount / loanLocal.collateral;
        }
        require(loanCloseAmount != 0, "loanCloseAmount == 0");

        uint256 usedCollateral;
        uint256 collateralToLoanSwapRate;
        (usedCollateral, withdrawAmount, collateralToLoanSwapRate) = _coverPrincipalWithSwap(
            loanLocal,
            loanParamsLocal,
            swapAmount,
            loanCloseAmount,
            returnTokenIsCollateral,
            loanDataBytes
        );

        if (loanCloseAmount != 0) {
            // Repays principal to lender
            vaultWithdraw(
                loanParamsLocal.loanToken,
                loanLocal.lender,
                loanCloseAmount
            );
        }

        if (usedCollateral != 0) {
            loanLocal.collateral = loanLocal.collateral - usedCollateral;
        }

        withdrawToken = returnTokenIsCollateral ?
            loanParamsLocal.collateralToken :
            loanParamsLocal.loanToken;

        if (withdrawAmount != 0) {
            _withdrawAsset(
                withdrawToken,
                receiver,
                withdrawAmount
            );
        }

        _finalizeClose(
            loanLocal,
            loanParamsLocal,
            loanCloseAmount,
            usedCollateral,
            collateralToLoanSwapRate,
            CloseTypes.Swap
        );
    }

    function _updateDepositAmount(
        bytes32 loanId,
        uint256 principalBefore,
        uint256 principalAfter)
        internal
    {
        uint256 depositValueAsLoanToken;
        uint256 depositValueAsCollateralToken;
        bytes32 slot = keccak256(abi.encode(loanId, LoanDepositValueID));
        assembly {
            switch principalAfter
            case 0 {
                sstore(slot, 0)
                sstore(add(slot, 1), 0)
            }
            default {
                depositValueAsLoanToken := div(mul(sload(slot), principalAfter), principalBefore)
                sstore(slot, depositValueAsLoanToken)

                slot := add(slot, 1)
                depositValueAsCollateralToken := div(mul(sload(slot), principalAfter), principalBefore)
                sstore(slot, depositValueAsCollateralToken)
            }
        }

        emit LoanDeposit(
            loanId,
            depositValueAsLoanToken,
            depositValueAsCollateralToken
        );
    }

    function _checkAuthorized(
        bytes32 _id,
        bool _active,
        address _borrower)
        internal
        view
    {
        require(_active, "loan is closed");
        require(
            msg.sender == _borrower ||
            delegatedManagers[_id][msg.sender],
            "unauthorized"
        );
    }



    function _coverPrincipalWithSwap(
        Loan memory loanLocal,
        LoanParams memory loanParamsLocal,
        uint256 swapAmount,
        uint256 principalNeeded,
        bool returnTokenIsCollateral,
        bytes memory loanDataBytes)
        internal
        returns (uint256 usedCollateral, uint256 withdrawAmount, uint256 collateralToLoanSwapRate)
    {
        uint256 destTokenAmountReceived;
        uint256 sourceTokenAmountUsed;
        (destTokenAmountReceived, sourceTokenAmountUsed, collateralToLoanSwapRate) = _doCollateralSwap(
            loanLocal,
            loanParamsLocal,
            swapAmount,
            principalNeeded,
            returnTokenIsCollateral,
            loanDataBytes
        );

        if (returnTokenIsCollateral) {
            if (destTokenAmountReceived > principalNeeded) {
                // better fill than expected, so send excess to borrower
                vaultWithdraw(
                    loanParamsLocal.loanToken,
                    loanLocal.borrower,
                    destTokenAmountReceived - principalNeeded
                );
            }
            withdrawAmount = swapAmount > sourceTokenAmountUsed ?
                swapAmount - sourceTokenAmountUsed :
                0;
        } else {
            require(sourceTokenAmountUsed == swapAmount, "swap error");
            withdrawAmount = destTokenAmountReceived - principalNeeded;
        }

        usedCollateral = sourceTokenAmountUsed > swapAmount ?
            sourceTokenAmountUsed :
            swapAmount;
    }

    function _doCollateralSwap(
        Loan memory loanLocal,
        LoanParams memory loanParamsLocal,
        uint256 swapAmount,
        uint256 principalNeeded,
        bool returnTokenIsCollateral,
        bytes memory loanDataBytes)
        internal
        returns (uint256 destTokenAmountReceived, uint256 sourceTokenAmountUsed, uint256 collateralToLoanSwapRate)
    {
        (destTokenAmountReceived, sourceTokenAmountUsed, collateralToLoanSwapRate) = _loanSwap(
            loanLocal.id,
            loanParamsLocal.collateralToken,
            loanParamsLocal.loanToken,
            loanLocal.borrower,
            swapAmount, // minSourceTokenAmount
            loanLocal.collateral, // maxSourceTokenAmount
            returnTokenIsCollateral ?
                principalNeeded :  // requiredDestTokenAmount
                0,
            false, // bypassFee
            loanDataBytes
        );
        require(destTokenAmountReceived >= principalNeeded, "insufficient dest amount");
        require(sourceTokenAmountUsed <= loanLocal.collateral, "excessive source amount");
    }

    function _getCurrentMargin(
        address loanToken,
        address collateralToken,
        uint256 principal,
        uint256 collateral,
        bool silentFail)
        internal
        override
        returns (uint256 currentMargin, uint256 collateralToLoanRate)
    {
        address _priceFeeds = priceFeeds;
        (bool success, bytes memory data) = _priceFeeds.staticcall(
            abi.encodeWithSelector(
                IPriceFeeds(_priceFeeds).getCurrentMargin.selector,
                loanToken,
                collateralToken,
                principal,
                collateral
            )
        );
        if (success) {
            assembly {
                currentMargin := mload(add(data, 32))
                collateralToLoanRate := mload(add(data, 64))
            }
        } else {
            require(silentFail, "margin query failed");
        }
    }

    function _finalizeClose(
        Loan memory loanLocal,
        LoanParams memory loanParamsLocal,
        uint256 loanCloseAmount,
        uint256 collateralCloseAmount,
        uint256 collateralToLoanSwapRate,
        CloseTypes closeType)
        internal
    {
        (uint256 principalBefore, uint256 principalAfter)  = _closeLoan(
            loanLocal,
            loanParamsLocal.loanToken,
            loanCloseAmount
        );

        // this is still called even with full loan close to return collateralToLoanRate
        (uint256 currentMargin, uint256 collateralToLoanRate) = _getCurrentMargin(
            loanParamsLocal.loanToken,
            loanParamsLocal.collateralToken,
            principalAfter,
            loanLocal.collateral,
            true // silentFail
        );

        //// Note: We can safely skip the margin check if closing via closeWithDeposit or if closing the loan in full by any method ////
        require(
            closeType == CloseTypes.Deposit ||
            principalAfter == 0 || // loan fully closed
            currentMargin > loanParamsLocal.maintenanceMargin,
            "unhealthy position"
        );

        _updateDepositAmount(
            loanLocal.id,
            principalBefore,
            principalAfter
        );

        _emitClosingEvents(
            loanParamsLocal,
            loanLocal,
            loanCloseAmount,
            collateralCloseAmount,
            collateralToLoanRate,
            collateralToLoanSwapRate,
            currentMargin,
            closeType
        );
    }
}