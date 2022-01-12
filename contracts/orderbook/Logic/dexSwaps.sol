pragma solidity ^0.8.0;

interface dexSwaps {
    function dexExpectedRate(
        address sourceTokenAddress,
        address destTokenAddress,
        uint256 sourceTokenAmount
    ) external view virtual returns (uint256);

    function dexAmountOut(bytes memory payload, uint256 amountIn)
        external
        view
        virtual
        returns (uint256 amountOut, address midToken);

    function dexAmountIn(bytes memory payload, uint256 amountOut)
        external
        view
        virtual
        returns (uint256 amountIn, address midToken);
}
