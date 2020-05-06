/**
 * Copyright 2017-2020, bZeroX, LLC. All Rights Reserved.
 * Licensed under the Apache License, Version 2.0.
 */

pragma solidity >=0.5.0 <0.6.0;

import "./IWeth.sol";
import "./IERC20.sol";


contract IWethERC20 is IWeth, IERC20 {}
