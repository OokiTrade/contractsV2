/**
 * Copyright 2017-2020, bZeroX, LLC. All Rights Reserved.
 * Licensed under the Apache License, Version 2.0.
 */

pragma solidity 0.5.17;
pragma experimental ABIEncoderV2;

import "./LoanTokenLogicStandard.sol";


interface IWethHelper {
    function claimEther(
        address receiver,
        uint256 amount)
        external
        returns (uint256 claimAmount);
}

contract LoanTokenLogicWeth is LoanTokenLogicStandard {

    function mintWithEther(
        address receiver)
        external
        payable
        nonReentrant
        returns (uint256 mintAmount)
    {
        return _mintToken(
            receiver,
            msg.value
        );
    }

    function burnToEther(
        address receiver,
        uint256 burnAmount)
        external
        nonReentrant
        returns (uint256 loanAmountPaid)
    {
        loanAmountPaid = _burnToken(
            burnAmount
        );

        if (loanAmountPaid != 0) {
            IWethHelper wethHelper = IWethHelper(0x3b5bDCCDFA2a0a1911984F203C19628EeB6036e0);

            _safeTransfer(loanTokenAddress, address(wethHelper), loanAmountPaid, "4");
            require(loanAmountPaid == wethHelper.claimEther(receiver, loanAmountPaid), "4");
        }
    }

    /* Internal functions */

    function _verifyTransfers(
        address collateralTokenAddress,
        address[4] memory sentAddresses,
        uint256[5] memory sentAmounts,
        uint256 withdrawalAmount)
        internal
    {
        address _loanTokenAddress = wethToken;
        address receiver = sentAddresses[2];
        uint256 newPrincipal = sentAmounts[1];
        uint256 loanTokenSent = sentAmounts[3];
        uint256 collateralTokenSent = sentAmounts[4];

        bool success;
        if (withdrawalAmount != 0) { // withdrawOnOpen == true
            IWethHelper wethHelper = IWethHelper(0x3b5bDCCDFA2a0a1911984F203C19628EeB6036e0);
            _safeTransfer(_loanTokenAddress, address(wethHelper), withdrawalAmount, "");
            if (withdrawalAmount == wethHelper.claimEther(receiver, withdrawalAmount) &&
                newPrincipal > withdrawalAmount) {
                _safeTransfer(_loanTokenAddress, bZxContract, newPrincipal - withdrawalAmount, "");
            }
        } else {
            _safeTransfer(_loanTokenAddress, bZxContract, newPrincipal, "26");
        }

        if (collateralTokenSent != 0) {
            if (collateralTokenAddress == wethToken && msg.value != 0 && collateralTokenSent == msg.value) {
                IWeth(wethToken).deposit.value(collateralTokenSent)();
                _safeTransfer(collateralTokenAddress, bZxContract, collateralTokenSent, "27");
            } else {
                if (collateralTokenAddress == _loanTokenAddress) {
                    loanTokenSent = loanTokenSent.add(collateralTokenSent);
                } else {
                    _safeTransferFrom(collateralTokenAddress, msg.sender, bZxContract, collateralTokenSent, "27");
                }
            }
        }

        if (loanTokenSent != 0) {
            _safeTransferFrom(_loanTokenAddress, msg.sender, bZxContract, loanTokenSent, "31");
        }
    }
}
