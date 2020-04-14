/**
 * Copyright 2017-2020, bZeroX, LLC. All Rights Reserved.
 * Licensed under the Apache License, Version 2.0.
 */

pragma solidity 0.5.17;


import "./Constants.sol";
import "../mixins/EnumerableBytes32Set.sol";
import "../openzeppelin/ReentrancyGuard.sol";
import "../openzeppelin/Ownable.sol";
import "../openzeppelin/SafeMath.sol";


contract State is Constants, ReentrancyGuard, Ownable {
    using SafeMath for uint256;
    using EnumerableBytes32Set for EnumerableBytes32Set.Bytes32Set;

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
        uint256 maxLoanDuration; // maxDurationUnixTimestampSec
    }

    struct Order {
        uint256 lockedAmount;
        uint256 interestRate;
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
        uint256 borrowTotal;        // total borrowed amount outstanding
        uint256 owedPerDay;         // interestOwedPerDay
        uint256 owedTotal;          // interest owed for all loans (assuming they go to full term)
        uint256 interestPaid;       // interestPaid so far
        uint256 updatedTimestamp;   // interestPaidDate
    }

    struct LoanInterest {
        uint256 owedPerDay;         // interestOwedPerDay
        uint256 paidTotal;          // interestPaid
        uint256 depositTotal;       // interestDepositTotal
        uint256 updatedTimestamp;   // updatedTimestamp
    }


    address public protocolTokenAddress;                                            // protocol token address
    address public feedsController;                                                 // handles asset reference price lookups
    address public tradesController;                                                // handles asset trades

    mapping (bytes4 => address) public logicTargets;                                // implementations of protocol functions

    mapping (bytes32 => Loan) public loans;                                         // loanId => Loan
    mapping (bytes32 => LoanParams) public loanParams;                              // loanParamsId => LoanParams
    mapping (bytes32 => mapping (bytes32 => bytes)) public auxData;                 // loanId/loanParamsId => key => bytes data

    mapping (address => mapping (bytes32 => Order)) public lenderOrders;            // lender => orderParamsId => Order
    mapping (address => mapping (bytes32 => Order)) public borrowerOrders;          // borrower => orderParamsId => Order

    mapping (address => bool) public protocolManagers;                              // delegated => approved
    mapping (bytes32 => mapping (address => bool)) public delegatedManagers;        // loanId => delegated => approved

    // Interest
    mapping (address => mapping (address => LenderInterest)) public lenderInterest; // lender => loanToken => LenderInterest object
    mapping (bytes32 => LoanInterest) public loanInterest;                          // loanId => LoanInterest object

    // Internals
    EnumerableBytes32Set.Bytes32Set internal logicTargetsSet;                       // implementations set
    EnumerableBytes32Set.Bytes32Set internal loansSet;                              // active loans set
    //EnumerableBytes32Set.Bytes32Set internal loanParamsSet;                         // active loanParms set
    EnumerableBytes32Set.Bytes32Set internal auxDataKeySet;                         // aux data keys set

    // TODO: setters for lenders and borrowers
    //  owner can deposit or withdraw (changes locked amount and transfers the token in or out)
    //  owner can change expirationStartTimestamp
    //EnumerableBytes32Set.Bytes32Set internal lendOrdersSet;                         // active loans set
    //EnumerableBytes32Set.Bytes32Set internal borrowOrdersSet;                       // active loans set
}
