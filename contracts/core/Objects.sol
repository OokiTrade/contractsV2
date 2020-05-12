/**
 * Copyright 2017-2020, bZeroX, LLC. All Rights Reserved.
 * Licensed under the Apache License, Version 2.0.
 */

pragma solidity 0.5.17;


contract Objects {
    struct Loan {
        bytes32 id; // positionId
        bytes32 loanParamsId;
        bytes32 pendingTradesId;
        bool active;
        uint256 principal; // loanTokenAmount/loanTokenAmountFilled
        uint256 collateral; // collateralTokenAmountFilled
        uint256 loanStartTimestamp; // loanStartUnixTimestampSec
        uint256 loanEndTimestamp; // loanEndUnixTimestampSec
        address borrower; // trader
        address lender;
    }

    struct LoanParams {
        bytes32 id; // loanParamsLocalHash
        bool active;
        address owner;
        address loanToken; // loanTokenAddress
        address collateralToken; // collateralTokenAddress
        uint256 initialMargin; // initialMarginAmount
        uint256 maintenanceMargin; // maintenanceMarginAmount
        uint256 fixedLoanTerm; // maxDurationUnixTimestampSec
    }

    struct Order {
        uint256 lockedAmount;
        uint256 interestRate;
        uint256 minLoanTerm;
        uint256 maxLoanTerm;
        uint256 createdStartTimestamp;
        uint256 expirationStartTimestamp;
    }

    // TODO
    /*struct PendingTrades {
        limit order
        stop-limit order
        bool active;
        bytes auxData;
    }*/

    struct LenderInterest {
        uint256 principalTotal;     // total borrowed amount outstanding
        uint256 owedPerDay;         // interestOwedPerDay
        uint256 owedTotal;          // interest owed for all loans (assuming they go to full term)
        uint256 paidTotal;          // interestPaid so far
        uint256 updatedTimestamp;   // interestPaidDate
    }

    struct LoanInterest {
        uint256 owedPerDay;         // interestOwedPerDay
        uint256 depositTotal;        // interestDepositTotal
        uint256 updatedTimestamp;   // updatedTimestamp
    }
}
