/**
 * Copyright 2017-2021, bZeroX, LLC. All Rights Reserved.
 * Licensed under the Apache License, Version 2.0.
 */

pragma solidity 0.6.12;

interface GovTokenLike {
    function mint(address to, uint256 amount) external;
    function transferOwnership(address newOwner) external;
}