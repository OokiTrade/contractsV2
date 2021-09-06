/**
 * Copyright 2017-2021, bZeroX, LLC <https://bzx.network/>. All Rights Reserved.
 * Licensed under the Apache License, Version 2.0.
 */
// SPDX-License-Identifier: Apache License, Version 2.0.
pragma solidity 0.6.12;

// import "@openzeppelin-3.4.0/token/ERC20/ERC20.sol";
import "@openzeppelin-3.4.0/token/ERC20/SafeERC20.sol";
import "@openzeppelin-3.4.0/access/Ownable.sol";
import "../../../interfaces/IMigrator.sol";
import "../../../interfaces/IBZRXv2Converter.sol";
import "../../interfaces/IUniswapV2Router02.sol";


contract SLPMigrator is Ownable, IMigrator {
    using SafeERC20 for IERC20;
    address public CONVERTER;

    address internal constant SUSHI_ROUTER = 0xd9e1cE17f2641f24aE83637ab66a2cca9C378B9F;
    address internal constant WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    address internal constant OOKI = 0xC5c66f91fE2e395078E0b872232A20981bc03B15;
    address internal constant BZRX = 0x56d811088235F11C8920698a204A5010a788f4b3;
    address internal constant LP_TOKEN = 0xa30911e072A0C88D55B5D0A0984B66b0D04569d0;

    constructor(address _CONVERTER) public {
        CONVERTER = _CONVERTER;
    }

    function migrate() external override {
        uint256 lpBalance = IERC20(LP_TOKEN).balanceOf(address(this));

        IERC20(LP_TOKEN).approve(SUSHI_ROUTER, lpBalance);
        (uint256 WETHBalance, uint256 BZRXBalance) = IUniswapV2Router02(SUSHI_ROUTER).removeLiquidity(WETH, BZRX, lpBalance, 1, 1, address(this), block.timestamp);

        IERC20(BZRX).approve(CONVERTER, BZRXBalance);
        IBZRXv2Converter(CONVERTER).convert(address(this), BZRXBalance);

        IERC20(WETH).approve(SUSHI_ROUTER, WETHBalance);
        IERC20(OOKI).approve(SUSHI_ROUTER, BZRXBalance);

        IUniswapV2Router02(SUSHI_ROUTER).addLiquidity(WETH, OOKI, WETHBalance, BZRXBalance, 1, 1, msg.sender, block.timestamp);
    }
}
