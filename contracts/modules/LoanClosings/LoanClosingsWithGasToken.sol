/**
 * Copyright 2017-2021, bZeroX, LLC. All Rights Reserved.
 * Licensed under the Apache License, Version 2.0.
 */

pragma solidity 0.5.17;
pragma experimental ABIEncoderV2;

import "./LoanClosingsBase.sol";
import "../../connectors/gastoken/GasTokenUser.sol";


contract LoanClosingsWithGasToken is LoanClosingsBase, GasTokenUser {

    function initialize(
        address target)
        external
        onlyOwner
    {
        _setTarget(this.liquidateWithGasToken.selector, target);
        _setTarget(this.rolloverWithGasToken.selector, target);
        _setTarget(this.closeWithDepositWithGasToken.selector, target);
        _setTarget(this.closeWithSwapWithGasToken.selector, target);
    }

    function liquidateWithGasToken(
        bytes32 loanId,
        address receiver,
        address gasTokenUser,
        uint256 closeAmount) // denominated in loanToken
        external
        payable
        usesGasToken(gasTokenUser)
        nonReentrant
        returns (
            uint256 loanCloseAmount,
            uint256 seizedAmount,
            address seizedToken
        )
    {
        return _liquidate(
            loanId,
            receiver,
            closeAmount
        );
    }

    function rolloverWithGasToken(
        bytes32 loanId,
        address gasTokenUser,
        bytes calldata /*loanDataBytes*/) // for future use
        external
        usesGasToken(gasTokenUser)
        nonReentrant
        returns (
            address rebateToken,
            uint256 gasRebate
        )
    {
        uint256 startingGas = gasleft() +
            22088; // estimated used gas ignoring loanDataBytes: 21000 + (4+32+32) * 16

        // restrict to EOAs to prevent griefing attacks, during interest rate recalculation
        require(msg.sender == tx.origin, "only EOAs can call");

        return _rollover(
            loanId,
            startingGas,
            "" // loanDataBytes
        );
    }

    function closeWithDepositWithGasToken(
        bytes32 loanId,
        address receiver,
        address gasTokenUser,
        uint256 depositAmount) // denominated in loanToken
        public
        payable
        usesGasToken(gasTokenUser)
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
            depositAmount
        );
    }

    function closeWithSwapWithGasToken(
        bytes32 loanId,
        address receiver,
        address gasTokenUser,
        uint256 swapAmount, // denominated in collateralToken
        bool returnTokenIsCollateral, // true: withdraws collateralToken, false: withdraws loanToken
        bytes memory /*loanDataBytes*/) // for future use
        public
        usesGasToken(gasTokenUser)
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
            "" // loanDataBytes
        );
    }
}
