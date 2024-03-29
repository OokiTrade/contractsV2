/**
 * Copyright 2017-2022, OokiDao. All Rights Reserved.
 * Licensed under the Apache License, Version 2.0.
 */

pragma solidity 0.5.17;

import "../IPriceFeedsExt.sol";

contract PriceFeedWETHETHDenominated is IPriceFeedsExt {
    int256 internal constant WEI_PRECISION = 10**18;

    function latestAnswer() external view returns (int256) {
        return WEI_PRECISION;
    }
}
