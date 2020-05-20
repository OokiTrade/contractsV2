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

    function setCoreParams(
        address _protocolTokenAddress,
        address _feedsController,
        address _swapsController,
        uint256 _protocolFeePercent) // 10 * 10**18;
        external;

    function setProtocolManagers(
        address[] calldata addrs,
        bool[] calldata toggles)
        external;

    function setLoanPoolToUnderlying(
        address[] calldata pools,
        address[] calldata assets)
        external;

    function setSupportedTokens(
        address[] calldata addrs,
        bool[] calldata toggles)
        external;

    function getloanPoolsList(
        uint256 start,
        uint256 count)
        external;


    ////// Loan Settings //////

    function setupLoanParams(
        LoanParams[] calldata loanParamsList)
        external
        returns (bytes32[] memory loanParamsIdList);

    function setupOrder(
        LoanParams calldata loanParamsLocal,
        uint256 lockedAmount,
        uint256 interestRate,
        uint256 minLoanTerm,
        uint256 maxLoanTerm,
        uint256 expirationStartTimestamp,
        bool isLender)
        external
        payable;

    function setupOrderWithId(
        bytes32 loanParamsId,
        uint256 lockedAmount, // initial deposit
        uint256 interestRate,
        uint256 minLoanTerm,
        uint256 maxLoanTerm,
        uint256 expirationStartTimestamp,
        bool isLender)
        external
        payable;

    function depositToOrder(
        bytes32 loanParamsId,
        uint256 depositAmount,
        bool isLender)
        external
        payable;

    function withdrawFromOrder(
        bytes32 loanParamsId,
        uint256 depositAmount,
        bool isLender)
        external
        payable;

    // Deactivates LoanParams for future loans. Active loans using it are unaffected.
    function disableLoanParams(
        bytes32[] calldata loanParamsIdList)
        external;

    function getLoanParams(
        bytes32 loanParamsId)
        external
        view
        returns (LoanParams memory);

    function getLoanParamsBatch(
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

    function borrow(
        bytes32 loanParamsId,
        bytes32 loanId, // if 0, start a new loan
        uint256 borrowAmount,
        uint256 initialLoanDuration,
        address lender,
        address receiver,
        address manager,
        bool depositCollateral)
        external
        payable
        returns (uint256);

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

    function getDepositAmountForBorrow(
        address loanToken,            // address(0) means ETH
        address collateralToken,      // address(0) means ETH
        uint256 borrowAmount,
        uint256 marginAmount,
        uint256 initialLoanDuration,  // duration in seconds
        uint256 interestRate)
        external
        view
        returns (uint256 depositAmount);

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
            uint256 collateralWithdrawAmount,
            address collateralToken
        );

    function repayWithDeposit(
        bytes32 loanId,
        address payer,
        address receiver,
        uint256 closeAmount) // denominated in loanToken
        external
        payable
        returns (
            uint256 loanCloseAmount,
            uint256 collateralWithdrawAmount,
            address collateralToken
        );

    function closeTrade(
        bytes32 loanId,
        address receiver,
        uint256 positionCloseAmount, // denominated in collateralToken
        bytes calldata loanDataBytes)
        external
        returns (
            uint256 loanCloseAmount,
            uint256 collateralWithdrawAmount,
            address collateralToken
        );

    function repayWithCollateral(
        bytes32 loanId,
        address receiver,
        uint256 closeAmount, // denominated in loanToken
        bytes calldata loanDataBytes)
        external
        returns (
            uint256 loanCloseAmount,
            uint256 collateralWithdrawAmount,
            address collateralToken
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
        uint256 initialMargin;
        uint256 maintenanceMargin;
        uint256 currentMargin;
        uint256 fixedLoanTerm;
        uint256 loanEndTimestamp;
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
