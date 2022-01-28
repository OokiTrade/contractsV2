/**
 * Copyright 2017-2022, OokiDao. All Rights Reserved.
 * Licensed under the Apache License, Version 2.0.
 */

pragma solidity >=0.5.0 <0.6.0;


interface ILoanPool {
    function tokenPrice()
        external
        view
        returns (uint256 price);

    function borrowInterestRate()
        external
        view
        returns (uint256);

    function _nextBorrowInterestRate(
        uint256 totalBorrow,
        uint256 newBorrow,
        uint256 lastInterestRate)
        external
        view
        returns (uint256 nextRate);

    function totalAssetSupply()
        external
        view
        returns (uint256);

    function assetBalanceOf(
        address _owner)
        external
        view
        returns (uint256);
}