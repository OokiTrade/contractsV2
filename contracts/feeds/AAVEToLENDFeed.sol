/**
 * Copyright 2017-2022, OokiDao. All Rights Reserved.
 * Licensed under the Apache License, Version 2.0.
 */

pragma solidity 0.5.17;

import "./IPriceFeedsExt.sol";


// mainnet: 0xc64F3C3925a216a11Ce0828498133cbC65fA4042
contract AAVEToLENDFeed is IPriceFeedsExt {
    function latestAnswer()
        external
        view
        returns (int256)
    {
        return IPriceFeedsExt(0x6Df09E975c830ECae5bd4eD9d90f3A95a4f88012).latestAnswer() / 100;
    }
}
