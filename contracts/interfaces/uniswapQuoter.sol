pragma solidity 0.5.17;

interface uniswapQuoter {
    function quoteExactInput(bytes calldata path, uint256 amountIn)
        external
        returns (
            uint256 amountOut
        );

    function quoteExactOutput(bytes calldata path, uint256 amountOut)
        external
        returns (
            uint256 amountIn
        );
}
