/**
 * Copyright 2017-2022, OokiDao. All Rights Reserved.
 * Licensed under the Apache License, Version 2.0.
 */

pragma solidity >=0.5.0 <=0.8.4;

interface ICurve3Pool {
    function add_liquidity(
        uint256[3] calldata amounts,
        uint256 min_mint_amount)
        external;

    function get_virtual_price()
        external
        view
        returns (uint256);
}
