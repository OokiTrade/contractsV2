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

    // sentAddresses[0]: lender
    // sentAddresses[1]: borrower
    // sentAddresses[2]: receiver
    // sentAddresses[3]: manager
    // sentAmounts[0]: interestRate
    // sentAmounts[1]: newPrincipal
    // sentAmounts[2]: interestInitialAmount
    // sentAmounts[3]: loanTokenSent
    // sentAmounts[4]: collateralTokenSent
    function _verifyTransfers(
        address collateralTokenAddress,
        address[4] memory sentAddresses,
        uint256[5] memory sentAmounts,
        uint256 withdrawalAmount)
        internal
    {
        address _wethToken = wethToken;
        address _loanTokenAddress = _wethToken;
        address receiver = sentAddresses[2];
        uint256 newPrincipal = sentAmounts[1];
        uint256 loanTokenSent = sentAmounts[3];
        uint256 collateralTokenSent = sentAmounts[4];

        require(_loanTokenAddress != collateralTokenAddress, "26");

        if (withdrawalAmount != 0) { // withdrawOnOpen == true
            IWethHelper wethHelper = IWethHelper(0x3b5bDCCDFA2a0a1911984F203C19628EeB6036e0);
            _safeTransfer(_loanTokenAddress, address(wethHelper), withdrawalAmount, "");
            if (withdrawalAmount == wethHelper.claimEther(receiver, withdrawalAmount) &&
                newPrincipal > withdrawalAmount) {
                _safeTransfer(_loanTokenAddress, bZxContract, newPrincipal - withdrawalAmount, "");
            }
        } else {
            _safeTransfer(_loanTokenAddress, bZxContract, newPrincipal, "27");
        }

        if (collateralTokenSent != 0) {
            _safeTransferFrom(collateralTokenAddress, msg.sender, bZxContract, collateralTokenSent, "28");
        }

        if (loanTokenSent != 0) {
            if (msg.value != 0 && msg.value >= loanTokenSent) {
                IWeth(_wethToken).deposit.value(loanTokenSent)();
                _safeTransfer(_loanTokenAddress, bZxContract, loanTokenSent, "29");
            } else {
                _safeTransferFrom(_loanTokenAddress, msg.sender, bZxContract, loanTokenSent, "29");
            }
        }
    }
}
