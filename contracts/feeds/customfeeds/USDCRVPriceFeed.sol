/**
 * Copyright 2017-2022, OokiDao. All Rights Reserved.
 * Licensed under the Apache License, Version 2.0.
 */

pragma solidity 0.5.17;

import "../IPriceFeedsExt.sol";


contract USDCRVPriceFeed is IPriceFeedsExt {
    function latestAnswer()
        external
        view
        returns (int256)
    {
        return (IPriceFeedsExt(0xEEf0C605546958c1f899b6fB336C20671f9cD49F).latestAnswer() * 1e18 / IPriceFeedsExt(0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419).latestAnswer());
    }
}
