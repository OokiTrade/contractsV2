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

    ////// Protocol Settings //////

    // setCoreParams(address,address,address,uint256)
    function setCoreParams(
        address _protocolTokenAddress,
        address _feedsController,
        address _swapsController,
        uint256 _protocolFeePercent) // 10 * 10**18;
        external;

    // setProtocolManagers(address[],bool[])
    function setProtocolManagers(
        address[] calldata addrs,
        bool[] calldata toggles)
        external;

    // setLoanPools(address[],address[])
    function setLoanPools(
        address[] calldata pools,
        address[] calldata assets)
        external;

    // getloanPoolsList(uint256,uint256)
    function getloanPoolsList(
        uint256 start,
        uint256 count)
        external;


    ////// Loan Settings //////

    // setupLoanParams((bytes32,bool,address,address,address,uint256,uint256,uint256)[])
    function setupLoanParams(
        LoanParams[] calldata loanParamsList)
        external;

    // setupOrder((bytes32,bool,address,address,address,uint256,uint256,uint256),uint256,uint256,uint256,bool)
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

    // setupOrderWithId(uint256,uint256,uint256,uint256,bool)
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

    // depositToOrder(bytes32,uint256,bool)
    function depositToOrder(
        bytes32 loanParamsId,
        uint256 depositAmount,
        bool isLender)
        external
        payable;

    // withdrawFromOrder(bytes32,uint256,bool)
    function withdrawFromOrder(
        bytes32 loanParamsId,
        uint256 depositAmount,
        bool isLender)
        external
        payable;

    // Deactivates LoanParams for future loans. Active loans using it are unaffected.
    // disableLoanParams(bytes32[])
    function disableLoanParams(
        bytes32[] calldata loanParamsIdList)
        external;

    // getLoanParams(bytes32)
    function getLoanParams(
        bytes32 loanParamsId)
        external
        view
        returns (LoanParams memory);

    // getLoanParamsBatch(bytes32[])
    function getLoanParamsBatch(
        bytes32[] calldata loanParamsIdList)
        external
        view
        returns (LoanParams[] memory loanParamsList);

    // getTotalPrincipal(address,address)
    function getTotalPrincipal(
        address lender,
        address loanToken)
        external
        view
        returns (uint256);


    ////// Loan Openings //////

    // borrow(bytes32,bytes32,uint256,uint256,address,address,address)
    function borrow(
        bytes32 loanParamsId,
        bytes32 loanId, // if 0, start a new loan
        uint256 borrowAmount,
        uint256 initialLoanDuration,
        address lender,
        address receiver,
        address manager)
        external
        payable
        returns (uint256);

    // borrowOrTradeFromPool(bytes32,bytes32,address[4],uint256[5],bytes)
    function borrowOrTradeFromPool(
        bytes32 loanParamsId,
        bytes32 loanId, // if 0, start a new loan
        bool isTorqueLoan,
        address[4] calldata sentAddresses,
            // lender: must match loan if loanId provided
            // borrower: must match loan if loanId provided
            // receiver: receiver of funds (address(0) assumes borrower address)
            // manager: delegated manager of loan unless address(0)
        uint256[5] calldata sentValues,
            // newRate: new loan interest rate
            // newPrincipal: new loan size (borrowAmount + any borrowed interest)
            // torqueInterest: new amount of interest to escrow for Torque loan (determines initial loan length)
            // loanTokenSent: total loanToken deposit
            // collateralTokenSent: total collateralToken deposit
        bytes calldata loanDataBytes)
        external
        payable
        returns (uint256);

    // getRequiredCollateral(address,address,uint256,uint256,bool)
    function getRequiredCollateral(
        address loanToken,
        address collateralToken,
        uint256 newPrincipal,
        uint256 marginAmount,
        bool isTorqueLoan)
        external
        view
        returns (uint256 collateralAmountRequired);

    // getBorrowAmount(address,address,uint256,uint256)
    function getBorrowAmount(
        address loanToken,
        address collateralToken,
        uint256 collateralTokenAmount,
        uint256 marginAmount,
        bool isTorqueLoan)
        external
        view
        returns (uint256 borrowAmount);

    // setDelegatedManager(bytes32,address,bool)
    function setDelegatedManager(
        bytes32 loanId,
        address delegated,
        bool toggle)
        external;


    ////// Loan Closings //////



    ////// Loan Maintenance //////

    // extendLoanByInterest(bytes32,address,uint256,bool,bytes)
    function extendLoanByInterest(
        bytes32 loanId,
        address payer,
        uint256 depositAmount,
        bool useCollateral,
        bytes calldata loanDataBytes)
        external
        payable
        returns (uint256 secondsExtended);

    // reduceLoanByInterest(bytes32,address,address,uint256)
    function reduceLoanByInterest(
        bytes32 loanId,
        address borrower,
        address receiver,
        uint256 withdrawAmount)
        external
        returns (uint256 secondsReduced);

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

    // getUserLoans(address,uint256,uint256,uint256,bool,bool)
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


    // getLoan(bytes32)
    function getLoan(
        bytes32 loanId)
        external
        view
        returns (LoanReturnData memory loanData);

    // getActiveLoans(uint256,uint256,bool)
    function getActiveLoans(
        uint256 start,
        uint256 count,
        bool unsafeOnly)
        external
        view
        returns (LoanReturnData[] memory loansData);
}
