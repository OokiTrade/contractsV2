/**
 * Copyright 2017-2020, bZeroX, LLC. All Rights Reserved.
 * Licensed under the Apache License, Version 2.0.
 */

pragma solidity 0.5.17;

import "../openzeppelin/SafeERC20.sol";
import "../core/State.sol";
import "../mixins/VaultController.sol";


contract InterestUser is State, VaultController {
    using SafeERC20 for IERC20;

    function _payInterest(
        LenderInterest memory lenderInterestLocal,
        address lender,
        address interestToken)
        internal
    {
        uint256 interestOwedNow = 0;
        if (lenderInterestLocal.owedPerDay != 0 && lenderInterestLocal.updatedTimestamp != 0) {
            interestOwedNow = block.timestamp.sub(lenderInterestLocal.updatedTimestamp).mul(lenderInterestLocal.owedPerDay).div(86400);
            if (interestOwedNow > lenderInterestLocal.owedTotal)
	            interestOwedNow = lenderInterestLocal.owedTotal;

            if (interestOwedNow != 0) {
                lenderInterestLocal.paidTotal = lenderInterestLocal.paidTotal.add(interestOwedNow);
                lenderInterestLocal.owedTotal = lenderInterestLocal.owedTotal.sub(interestOwedNow);

                uint256 interestFee = interestOwedNow
                    .mul(protocolFeePercent)
                    .div(10**20);
                protocolFeeTokens[interestToken] = protocolFeeTokens[interestToken]
                    .add(interestFee);

                // transfers the interest to the lender, less the interest fee
                vaultWithdraw(
                    interestToken,
                    lender,
                    interestOwedNow.sub(interestFee)
                );
            }
        }

        lenderInterestLocal.updatedTimestamp = block.timestamp;
        lenderInterest[lender][interestToken] = lenderInterestLocal;
    }
}
