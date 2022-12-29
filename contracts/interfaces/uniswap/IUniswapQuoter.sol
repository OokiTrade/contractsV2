// SPDX-License-Identifier: Apache-2.0
pragma solidity >=0.5.17 <0.9.0;

interface IUniswapQuoter {
  function quoteExactInput(bytes calldata path, uint256 amountIn) external returns (uint256 amountOut);

  function quoteExactOutput(bytes calldata path, uint256 amountOut) external returns (uint256 amountIn);
}
