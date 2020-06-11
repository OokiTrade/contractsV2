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

    address public protocolTokenAddress;                                                // protocol token address
    address public priceFeeds;                                                          // handles asset reference price lookups
    address public swapsImpl;                                                           // handles asset trades

    mapping (bytes4 => address) public logicTargets;                                    // implementations of protocol functions

    mapping (bytes32 => Loan) public loans;                                             // loanId => Loan
    mapping (bytes32 => LoanParams) public loanParams;                                  // loanParamsId => LoanParams
    mapping (bytes32 => mapping (bytes32 => bytes)) public auxData;                     // loanId/loanParamsId => key => bytes data

    mapping (address => mapping (bytes32 => Order)) public lenderOrders;                // lender => orderParamsId => Order
    mapping (address => mapping (bytes32 => Order)) public borrowerOrders;              // borrower => orderParamsId => Order

    mapping (bytes32 => mapping (address => bool)) public delegatedManagers;            // loanId => delegated => approved

    // Interest
    mapping (address => mapping (address => LenderInterest)) public lenderInterest;     // lender => loanToken => LenderInterest object
    mapping (bytes32 => LoanInterest) public loanInterest;                              // loanId => LoanInterest object

    // Internals
    EnumerableBytes32Set.Bytes32Set internal logicTargetsSet;                           // implementations set
    EnumerableBytes32Set.Bytes32Set internal activeLoansSet;                            // active loans set
    EnumerableBytes32Set.Bytes32Set internal auxDataKeySet;                             // aux data keys set

    mapping (address => EnumerableBytes32Set.Bytes32Set) internal lenderLoanSets;
    mapping (address => EnumerableBytes32Set.Bytes32Set) internal borrowerLoanSets;
    mapping (address => EnumerableBytes32Set.Bytes32Set) internal userLoanParamSets;

    address public feesAdmin;

    uint256 public lendingFeePercent = 10**19; // 10% fee
    mapping (address => uint256) public lendingFeeTokensHeld;
    mapping (address => uint256) public lendingFeeTokensPaid;

    uint256 public tradingFeePercent = 10**17; // 0.1% fee
    mapping (address => uint256) public tradingFeeTokensHeld;
    mapping (address => uint256) public tradingFeeTokensPaid;

    uint256 public borrowingFeePercent = 9 * 10**16; // 0.09% fee
    mapping (address => uint256) public borrowingFeeTokensHeld;
    mapping (address => uint256) public borrowingFeeTokensPaid;

    uint256 public affiliateFeePercent = 30 * 10**18; // 30% fee share

    uint256 public liquidationIncentivePercent = 5 * 10**18; // 5% collateral discount

    mapping (address => address) public loanPoolToUnderlying;                            // loanPool => underlying
    mapping (address => address) public underlyingToLoanPool;                            // underlying => loanPool
    EnumerableBytes32Set.Bytes32Set internal loanPoolsSet;                               // loan pools set

    // supported tokens for swaps
    mapping (address => bool) public supportedTokens;

    // A threshold of minimum initial margin for loan to be insured by the guarantee fund
    // A value of 0 indicates that no threshold exists for this parameter.
    uint256 public guaranteedInitialMargin = 0;

    // A threshold of minimum maintenance margin for loan to be insured by the guarantee fund
    // A value of 0 indicates that no threshold exists for this parameter.
    uint256 public guaranteedMaintenanceMargin = 15 * 10**18;

    uint256 public maxDisagreement = 5 * 10**18;

    uint256 public sourceBufferPercent = 5 * 10**18;

    uint256 public maxSwapSize = 1500 ether;


    function _setTarget(
        bytes4 sig,
        address target)
        internal
    {
        logicTargets[sig] = target;

        if (target != address(0)) {
            logicTargetsSet.add(bytes32(sig));
        } else {
            logicTargetsSet.remove(bytes32(sig));
        }
    }
}
