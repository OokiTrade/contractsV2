/**
 * Copyright 2017-2020, bZeroX, LLC. All Rights Reserved.
 * Licensed under the Apache License, Version 2.0.
 */

pragma solidity 0.5.17;


interface IBZxPartial {
    enum FeeClaimType {
        All,
        Lending,
        Trading,
        Borrowing
    }
    
    function withdrawFees(
        address[] calldata tokens,
        address receiver,
        FeeClaimType feeType)
        external
        returns (uint256[] memory amounts);

    function queryFees(
        address[] calldata tokens,
        FeeClaimType feeType)
        external
        view
        returns (uint256[] memory amountsHeld, uint256[] memory amountsPaid);

    function priceFeeds()
        external
        view
        returns (address);
}
