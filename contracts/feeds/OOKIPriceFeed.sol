/**
 * Copyright 2017-2022, OokiDao. All Rights Reserved.
 * Licensed under the Apache License, Version 2.0.
 */

pragma solidity 0.5.17;

import "./IPriceFeedsExt.sol";
import "../governance/PausableGuardian.sol";

contract OOKIPriceFeed is PausableGuardian, IPriceFeedsExt {
    int256 public storedPrice = 2e6; // $0.02

    function updateStoredPrice(
        int256 price)
        external
        onlyGuardian
    {
        storedPrice = price;
    }

    function latestAnswer()
        external
        view
        returns (int256)
    {
        return storedPrice;
    }
}