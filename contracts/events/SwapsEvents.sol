/**
 * Copyright 2017-2020, bZeroX, LLC. All Rights Reserved.
 * Licensed under the Apache License, Version 2.0.
 */

// SPDX-License-Identifier: GNU 
pragma solidity 0.6.12;


contract SwapsEvents {
    event LoanSwap(
        bytes32 indexed loanId,
        address indexed sourceToken,
        address indexed destToken,
        address borrower,
        uint256 sourceAmount,
        uint256 destAmount
    );

    event ExternalSwap(
        address indexed user,
        address indexed sourceToken,
        address indexed destToken,
        uint256 sourceAmount,
        uint256 destAmount
    );
}
