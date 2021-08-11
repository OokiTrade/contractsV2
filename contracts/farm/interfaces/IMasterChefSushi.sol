/**
 * Copyright 2017-2020, bZeroX, LLC. All Rights Reserved.
 * Licensed under the Apache License, Version 2.0.
 */

pragma solidity 0.5.17;

interface IMasterChefSushi {

    function deposit(uint256 _pid, uint256 _amount)
        external;

    function withdraw(uint256 _pid, uint256 _amount)
        external;

}