pragma solidity ^0.8.4;

interface dexSwaps{
    function dexExpectedRate(address sourceTokenAddress,address destTokenAddress,uint256 sourceTokenAmount) external virtual view returns (uint256);
    function dexAmountOut(address sourceTokenAddress,address destTokenAddress,uint256 amountIn) external virtual view returns (uint256 amountOut, address midToken);
    function dexAmountIn(address sourceTokenAddress,address destTokenAddress,uint256 amountOut) external virtual view returns (uint256 amountIn, address midToken);

}