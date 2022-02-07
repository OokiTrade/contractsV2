/**
 * Copyright 2017-2022, OokiDao. All Rights Reserved.
 * Licensed under the Apache License, Version 2.0.
 */

pragma solidity 0.5.17;


contract InterestRateEvents {

    event PoolInterestRateVals(
        address indexed pool,
        uint256 poolPrincipalTotal,
        uint256 poolInterestTotal,
        uint256 poolRatePerTokenStored,
        uint256 poolNextInterestRate
    );

    event LoanInterestRateVals(
        bytes32 indexed loanId,
        uint256 loanPrincipalTotal,
        uint256 loanInterestTotal,
        uint256 loanRatePerTokenPaid
    );
}