/**
 * Copyright 2017-2022, OokiDao. All Rights Reserved.
 * Licensed under the Apache License, Version 2.0.
 */

pragma solidity >=0.5.0 <0.6.0;

import "./IWeth.sol";
import "@openzeppelin-2.5.0/token/ERC20/IERC20.sol";


contract IWethERC20 is IWeth, IERC20 {}
