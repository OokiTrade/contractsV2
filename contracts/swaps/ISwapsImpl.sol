/**
 * Copyright 2017-2022, OokiDao. All Rights Reserved.
 * Licensed under the Apache License, Version 2.0.
 */

pragma solidity >=0.5.17;

interface ISwapsImpl {
    function dexSwap(
        address sourceTokenAddress,
        address destTokenAddress,
        address receiverAddress,
        address returnToSenderAddress,
        uint256 minSourceTokenAmount,
        uint256 maxSourceTokenAmount,
        uint256 requiredDestTokenAmount,
        bytes calldata payload
    )
        external
        returns (
            uint256 destTokenAmountReceived,
            uint256 sourceTokenAmountUsed
        );

    function dexExpectedRate(
        address sourceTokenAddress,
        address destTokenAddress,
        uint256 sourceTokenAmount
    ) external view returns (uint256);

    function dexAmountOut(bytes calldata route, uint256 amountIn)
        external
        returns (uint256 amountOut, address midToken);

    function dexAmountOutFormatted(bytes calldata route, uint256 amountOut)
        external
        returns (uint256 amountIn, address midToken);

    function dexAmountIn(bytes calldata route, uint256 amountOut)
        external
        returns (uint256 amountIn, address midToken);

    function dexAmountInFormatted(bytes calldata route, uint256 amountOut)
        external
        returns (uint256 amountIn, address midToken);

    function setSwapApprovals(address[] calldata tokens) external;
}
