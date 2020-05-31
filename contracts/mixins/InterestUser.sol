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

    event InterestData(
        uint256 interestOwedNow,
        uint256 lenderSent,
        uint256 feeKept
    );

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

                emit InterestData(
                    interestOwedNow,
                    interestOwedNow.sub(interestFee),
                    interestFee
                );
            }
        }

        lenderInterestLocal.updatedTimestamp = block.timestamp;
        lenderInterest[lender][interestToken] = lenderInterestLocal;
    }
}
/*
TODO - Bug fixes:

    - test borrow and payback.. for some reason it leaves beind more DAI than it should
        - check InterestData event above
    - there may still be a bug with profit checkpointing in iToken. test again


also:
    - reploy iTokens
    - this bug:
    ok, looks like a bug somewhere for collateral estimates when utilization the pool is really high. 
    i just lended more DAI to bring the util now, now DAI borrow works

also:
    - test collateralized iTokens <- update so that Swaps contract handles the iToken conversions

also:
    - how to handle swaps of collateralized itokens?

also:
    - implement roll-over liquidations for interest
*/