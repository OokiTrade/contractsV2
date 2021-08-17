/**
 * Copyright 2017-2021, bZeroX, LLC. All Rights Reserved.
 * Licensed under the Apache License, Version 2.0.
 */

pragma solidity 0.5.17;
pragma experimental ABIEncoderV2;

import "./LoanClosingsBase.sol";


contract LoanClosings is LoanClosingsBase {

    function initialize(
        address target)
        external
        onlyOwner
    {
        _setTarget(this.liquidate.selector, target);
        _setTarget(this.rollover.selector, target);
        _setTarget(this.closeWithDeposit.selector, target);
        _setTarget(this.closeWithSwap.selector, target);
    }

    function liquidate(
        bytes32 loanId,
        address receiver,
        uint256 closeAmount) // denominated in loanToken
        external
        payable
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

    function rollover(
        bytes32 loanId,
        bytes calldata /*loanDataBytes*/) // for future use
        external
        nonReentrant
        returns (
            address rebateToken,
            uint256 gasRebate
        )
    {
        uint256 startingGas = gasleft() +
            21576; // estimated used gas ignoring loanDataBytes: 21000 + (4+32) * 16

        // restrict to EOAs to prevent griefing attacks, during interest rate recalculation
        require(msg.sender == tx.origin, "only EOAs can call");

        return _rollover(
            loanId,
            startingGas,
            "" // loanDataBytes
        );
    }

    function closeWithDeposit(
        bytes32 loanId,
        address receiver,
        uint256 depositAmount) // denominated in loanToken
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
            depositAmount
        );
    }

    function closeWithSwap(
        bytes32 loanId,
        address receiver,
        uint256 swapAmount, // denominated in collateralToken
        bool returnTokenIsCollateral, // true: withdraws collateralToken, false: withdraws loanToken
        bytes memory /*loanDataBytes*/) // for future use
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
            "" // loanDataBytes
        );
    }
}
