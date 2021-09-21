pragma solidity 0.5.17;

interface uniswapQuoter{
  function quoteExactInput(
    bytes path,
    uint256 amountIn
  ) external returns (uint256 amountOut, uint160[] sqrtPriceX96AfterList, uint32[] initializedTicksCrossedList, uint256 gasEstimate);
  function quoteExactOutput(
    bytes path,
    uint256 amountOut
  ) external returns (uint256 amountIn, uint160[] sqrtPriceX96AfterList, uint32[] initializedTicksCrossedList, uint256 gasEstimate);
}