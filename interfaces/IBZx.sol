/**
 * Copyright 2017-2020, bZeroX, LLC. All Rights Reserved.
 * Licensed under the Apache License, Version 2.0.
 */

pragma solidity >=0.5.0 <0.6.0;
pragma experimental ABIEncoderV2;

import "../contracts/core/State.sol";
import "../contracts/events/ProtocolSettingsEvents.sol";
import "../contracts/events/LoanSettingsEvents.sol";
import "../contracts/events/LoanOpeningsEvents.sol";
import "../contracts/events/LoanClosingsEvents.sol";
import "../contracts/events/FeesEvents.sol";
import "../contracts/events/SwapsEvents.sol";


contract IBZx is
    State,
    ProtocolSettingsEvents,
    LoanSettingsEvents,
    LoanOpeningsEvents,
    LoanClosingsEvents,
    SwapsEvents {


    ////// Protocol //////

    function replaceContract(
        address target)
        external;

    function setTargets(
        string[] calldata sigsArr,
        address[] calldata targetsArr)
        external;

    function getTarget(
        string calldata sig)
        external
        view
        returns (address);


    ////// Protocol Settings //////

    function setPriceFeedContract(
        address newContract)
        external;

    function setSwapsImplContract(
        address newContract)
        external;

    function setLoanPool(
        address[] calldata pools,
        address[] calldata assets)
        external;

    function setSupportedTokens(
        address[] calldata addrs,
        bool[] calldata toggles)
        external;

    function setLendingFeePercent(
        uint256 newValue)
        external;

    function setTradingFeePercent(
        uint256 newValue)
        external;

    function setBorrowingFeePercent(
        uint256 newValue)
        external;

    function setAffiliateFeePercent(
        uint256 newValue)
        external;

    function setLiquidationIncentivePercent(
        uint256 newAmount)
        external;

    function setMaxDisagreement(
        uint256 newAmount)
        external;

    function setSourceBufferPercent(
        uint256 newAmount)
        external;

    function setMaxSwapSize(
        uint256 newAmount)
        external;

    function setFeesController(
        address newController)
        external;

    function withdrawLendingFees(
        address token,
        address receiver,
        uint256 amount)
        external
        returns (bool);

    function withdrawTradingFees(
        address token,
        address receiver,
        uint256 amount)
        external
        returns (bool);

    function withdrawBorrowingFees(
        address token,
        address receiver,
        uint256 amount)
        external
        returns (bool);

    function withdrawProtocolToken(
        address receiver,
        uint256 amount)
        external
        returns (address, bool);

    function depositProtocolToken(
        uint256 amount)
        external;

    function getLoanPoolsList(
        uint256 start,
        uint256 count)
        external;

    function isLoanPool(
        address loanPool)
        external
        view
        returns (bool);


    ////// Loan Settings //////

    function setupLoanParams(
        LoanParams[] calldata loanParamsList)
        external
        returns (bytes32[] memory loanParamsIdList);

    // Deactivates LoanParams for future loans. Active loans using it are unaffected.
    function disableLoanParams(
        bytes32[] calldata loanParamsIdList)
        external;

    function getLoanParams(
        bytes32[] calldata loanParamsIdList)
        external
        view
        returns (LoanParams[] memory loanParamsList);

    function getLoanParamsList(
        address owner,
        uint256 start,
        uint256 count)
        external
        view
        returns (bytes32[] memory loanParamsList);

    function getTotalPrincipal(
        address lender,
        address loanToken)
        external
        view
        returns (uint256);


    ////// Loan Openings //////

    function borrowOrTradeFromPool(
        bytes32 loanParamsId,
        bytes32 loanId, // if 0, start a new loan
        bool isTorqueLoan,
        uint256 initialMargin,
        address[4] calldata sentAddresses,
            // lender: must match loan if loanId provided
            // borrower: must match loan if loanId provided
            // receiver: receiver of funds (address(0) assumes borrower address)
            // manager: delegated manager of loan unless address(0)
        uint256[5] calldata sentValues,
            // newRate: new loan interest rate
            // newPrincipal: new loan size (borrowAmount + any borrowed interest)
            // torqueInterest: new amount of interest to escrow for Torque loan (determines initial loan length)
            // loanTokenReceived: total loanToken deposit (amount not sent to borrower in the case of Torque loans)
            // collateralTokenReceived: total collateralToken deposit
        bytes calldata loanDataBytes)
        external
        payable
        returns (uint256);

    function setDelegatedManager(
        bytes32 loanId,
        address delegated,
        bool toggle)
        external;

    function getEstimatedMarginExposure(
        address loanToken,
        address collateralToken,
        uint256 loanTokenSent,
        uint256 collateralTokenSent,
        uint256 interestRate,
        uint256 newPrincipal)
        external
        view
        returns (uint256);

    function getRequiredCollateral(
        address loanToken,
        address collateralToken,
        uint256 newPrincipal,
        uint256 marginAmount,
        bool isTorqueLoan)
        external
        view
        returns (uint256 collateralAmountRequired);

    function getBorrowAmount(
        address loanToken,
        address collateralToken,
        uint256 collateralTokenAmount,
        uint256 marginAmount,
        bool isTorqueLoan)
        external
        view
        returns (uint256 borrowAmount);


    ////// Loan Closings //////

    function liquidate(
        bytes32 loanId,
        address receiver,
        uint256 closeAmount) // denominated in loanToken
        external
        payable
        returns (
            uint256 loanCloseAmount,
            uint256 seizedAmount,
            address seizedToken
        );

    function rollover(
        bytes32 loanId,
        bytes calldata loanDataBytes)
        external;

    function closeWithDeposit(
        bytes32 loanId,
        address receiver,
        uint256 depositAmount) // denominated in loanToken
        external
        payable
        returns (
            uint256 loanCloseAmount,
            uint256 withdrawAmount,
            address withdrawToken
        );

    function closeWithSwap(
        bytes32 loanId,
        address receiver,
        uint256 swapAmount, // denominated in collateralToken
        bool returnTokenIsCollateral, // true: withdraws collateralToken, false: withdraws loanToken
        bytes calldata loanDataBytes)
        external
        returns (
            uint256 loanCloseAmount,
            uint256 withdrawAmount,
            address withdrawToken
        );


    ////// Loan Maintenance //////

    function depositCollateral(
        bytes32 loanId,
        uint256 depositAmount) // must match msg.value if ether is sent
        external
        payable;

    function withdrawCollateral(
        bytes32 loanId,
        address receiver,
        uint256 withdrawAmount)
        external
        returns (uint256 actualWithdrawAmount);

    function extendLoanByInterest(
        bytes32 loanId,
        address payer,
        uint256 depositAmount,
        bool useCollateral,
        bytes calldata loanDataBytes)
        external
        payable
        returns (uint256 secondsExtended);

    function reduceLoanByInterest(
        bytes32 loanId,
        address receiver,
        uint256 withdrawAmount)
        external
        returns (uint256 secondsReduced);

    function withdrawAccruedInterest(
        address loanToken)
        external;

    function getLenderInterestData(
        address lender,
        address loanToken)
        external
        view
        returns (
            uint256 interestPaid,
            uint256 interestPaidDate,
            uint256 interestOwedPerDay,
            uint256 interestUnPaid,
            uint256 interestFeePercent,
            uint256 principalTotal);

    function getLoanInterestData(
        bytes32 loanId)
        external
        view
        returns (
            address loanToken,
            uint256 interestOwedPerDay,
            uint256 interestDepositTotal,
            uint256 interestDepositRemaining);

    struct LoanReturnData {
        bytes32 loanId;
        address loanToken;
        address collateralToken;
        uint256 principal;
        uint256 collateral;
        uint256 interestOwedPerDay;
        uint256 interestDepositRemaining;
        uint256 startRate; // collateralToLoanRate
        uint256 startMargin;
        uint256 maintenanceMargin;
        uint256 currentMargin;
        uint256 maxLoanTerm;
        uint256 endTimestamp;
        uint256 maxLiquidatable;
        uint256 maxSeizable;
    }

    function getUserLoans(
        address user,
        uint256 start,
        uint256 count,
        uint256 loanType,
        bool isLender,
        bool unsafeOnly)
        external
        view
        returns (LoanReturnData[] memory loansData);

    function getLoan(
        bytes32 loanId)
        external
        view
        returns (LoanReturnData memory loanData);

    function getActiveLoans(
        uint256 start,
        uint256 count,
        bool unsafeOnly)
        external
        view
        returns (LoanReturnData[] memory loansData);


    ////// Protocol Migration //////

    function setLegacyOracles(
        address[] calldata refs,
        address[] calldata oracles)
        external;

    function getLegacyOracle(
        address ref)
        external
        view
        returns (address);
}
