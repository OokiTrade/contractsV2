/**
 * Copyright 2017-2023, OokiDao. All Rights Reserved.
 * Licensed under the Apache License, Version 2.0.
 */

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

import "contracts/feeds/IPriceFeedsExt.sol";
import "interfaces/IPriceFeedHelper.sol";
import "interfaces/IToken.sol";

contract ITokenPriceFeedHelper_ETH is IPriceFeedHelper {
    IPriceFeedsExt private immutable PRICE_FEED_EXT; // underlying token Chainlink feed address

    constructor(IPriceFeedsExt _priceFeedAddress) {
        PRICE_FEED_EXT = _priceFeedAddress;
    }

    function latestAnswer(address token) public view returns (uint256) {
        return (uint256(PRICE_FEED_EXT.latestAnswer()) * IToken(token).tokenPrice()) / 1e18;
    }
}
