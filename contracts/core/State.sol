/**
 * Copyright 2017-2020, bZeroX, LLC. All Rights Reserved.
 * Licensed under the Apache License, Version 2.0.
 */

pragma solidity 0.5.17;


import "./Constants.sol";
import "./Objects.sol";
import "../mixins/EnumerableBytes32Set.sol";
import "../openzeppelin/ReentrancyGuard.sol";
import "../openzeppelin/Ownable.sol";
import "../openzeppelin/SafeMath.sol";


contract State is Constants, Objects, ReentrancyGuard, Ownable {
    using SafeMath for uint256;
    using EnumerableBytes32Set for EnumerableBytes32Set.Bytes32Set;

    address public protocolTokenAddress;                                            // protocol token address
    address public priceFeeds;                                                 // handles asset reference price lookups
    address public swapsImpl;                                                // handles asset trades

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
    EnumerableBytes32Set.Bytes32Set internal activeLoansSet;                        // active loans set
    //EnumerableBytes32Set.Bytes32Set internal loanParamsSet;                         // active loanParms set
    EnumerableBytes32Set.Bytes32Set internal auxDataKeySet;                         // aux data keys set

    mapping (address => EnumerableBytes32Set.Bytes32Set) internal lenderLoanSets;
    mapping (address => EnumerableBytes32Set.Bytes32Set) internal borrowerLoanSets;

    // TODO: setters for lenders and borrowers
    //  owner can deposit or withdraw (changes locked amount and transfers the token in or out)
    //  owner can change expirationStartTimestamp
    //EnumerableBytes32Set.Bytes32Set internal lendOrdersSet;                         // active loans set
    //EnumerableBytes32Set.Bytes32Set internal borrowOrdersSet;                       // active loans set

    uint256 public protocolFeePercent;                                              //
    mapping (address => uint256) public protocolFeeTokens;                            // delegated => approved
    uint256 public liquidationIncentivePercent;

    mapping (address => address) public loanPoolToUnderlying;                            // delegated => approved
    mapping (address => address) public underlyingToLoanPool;                            // delegated => approved
    EnumerableBytes32Set.Bytes32Set internal loanPoolsSet;                              // active loans set

    // supported tokens for swaps
    mapping (address => bool) public supportedTokens;

    // TODO: setters for these ->
    // A threshold of minimum initial margin for loan to be insured by the guarantee fund
    // A value of 0 indicates that no threshold exists for this parameter.
    uint256 public minInitialMarginAmount = 0;

    // A threshold of minimum maintenance margin for loan to be insured by the guarantee fund
    // A value of 0 indicates that no threshold exists for this parameter.
    uint256 public minMaintenanceMarginAmount = 15 * 10**18;

    uint256 public maxDisagreement = 5 * 10**18;

    // Percentage of maximum slippage allowed for Kyber swap when liquidating
    // This will always be between 0 and 100%
    //uint256 public maxLiquidationSlippagePercent = 10 * 10**18; // 5 * 10**18;

    // Percentage of maximum slippage allowed for Kyber swap during regular trades
    // This will always be between 0 and 100%
    uint256 public maxNormalSlippagePercent = 5 * 10**18; // 3 * 10**18;

    //uint256 public maxSwapSize = 1500 ether;
}
