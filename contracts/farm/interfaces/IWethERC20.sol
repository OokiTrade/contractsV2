/**
 * Copyright 2017-2022, OokiDao. All Rights Reserved.
 * Licensed under the Apache License, Version 2.0.
 */

pragma solidity >=0.6.0 <0.7.0;

import "@openzeppelin-3.4.0/token/ERC20/IERC20.sol";
import "./IWeth.sol";


interface IWethERC20 is IWeth, IERC20 {}
