/**
 * Copyright 2017-2020, bZeroX, LLC. All Rights Reserved.
 * Licensed under the Apache License, Version 2.0.
 */

pragma solidity >=0.5.0 <0.6.0;
pragma experimental ABIEncoderV2;

import "../contracts/core/State.sol";


contract IBZx is State {

    ////// Protocol Settings //////
    event CoreParamsSet(
        address protocolTokenAddress,
        address feedsController,
        address swapsController,
        uint256 protocolFeePercent
    );
    event ProtocolManagerSet(
        address indexed delegator,
        address indexed delegated,
        bool isActive
    );

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
    event LoanParamsSetup(
        bytes32 indexed id,
        address owner,
        address indexed loanToken,
        address indexed collateralToken,
        uint256 initialMargin,
        uint256 maintenanceMargin,
        uint256 fixedLoanTerm
    );
    event LoanParamsIdSetup(
        bytes32 indexed id,
        address indexed owner
    );

    event LoanParamsDisabled(
        bytes32 indexed id,
        address owner,
        address indexed loanToken,
        address indexed collateralToken,
        uint256 initialMargin,
        uint256 maintenanceMargin,
        uint256 fixedLoanTerm
    );
    event LoanParamsIdDisabled(
        bytes32 indexed id,
        address indexed owner
    );

    event LoanOrderSetup(
        bytes32 indexed loanParamsId,
        address indexed owner,
        bool indexed isLender,
        uint256 lockedAmount,
        uint256 interestRate,
        uint256 expirationStartTimestamp
    );

    event LoanOrderChangeAmount(
        bytes32 indexed loanParamsId,
        address indexed owner,
        bool indexed isLender,
        uint256 oldBalance,
        uint256 newBalance
    );


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
    event Borrow(
        bytes32 indexed loanId,
        address indexed borrower,
        address indexed loanToken,
        address collateralToken,
        uint256 newPrincipal,
        uint256 newCollateral,
        uint256 interestRate,
        uint256 collateralToLoanRate,
        uint256 currentMargin
    );

    event DelegatedManagerSet(
        bytes32 indexed loanId,
        address indexed delegator,
        address indexed delegated,
        bool isActive
    );

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

    function setDelegatedManager(
        bytes32 loanId,
        address delegated,
        bool toggle)
        external;


    ////// Loan Closings //////



}
