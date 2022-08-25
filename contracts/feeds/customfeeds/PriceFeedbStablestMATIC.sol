pragma solidity ^0.8.0;

import "../../../interfaces/IPriceFeeds.sol";
import "../../interfaces/IBalancerVault.sol";
import "@openzeppelin-4.7.0/token/ERC20/IERC20.sol";
contract PriceFeedbStablestMATIC {
    address internal constant _vault = 0xBA12222222228d8Ba445958a75a0704d566BF2C8;
    bytes32 internal constant _poolId = 0xaf5e0b5425de1f5a630a8cb5aa9d97b8141c908d000200000000000000000366;
    IPriceFeeds internal constant _priceFeed = IPriceFeeds(0x600F8E7B10CF6DA18871Ff79e4A61B13caCEd9BC);

    address public constant WMATIC = 0x0d500B1d8E8eF31E21C99d1Db9A6444d3ADf1270;
    address public constant STMATIC = 0x3A58a54C066FdC0f2D55FC9C89F0415C92eBf3C4;
    address public constant USDC = 0x2791Bca1f2de4661ED88A30C99A7a9449Aa84174;
    address public constant BSTABLEPOOL = 0xaF5E0B5425dE1F5a630A8cB5AA9D97B8141C908D;

    function latestAnswer() external view returns (int256 USDCTotals) {
        (address[] memory tokens, uint256[] memory balances, ) = IBalancerVault(_vault).getPoolTokens(_poolId);
        for (uint i; i < tokens.length;) {
            USDCTotals += int256(_priceFeed.queryReturn(tokens[i], USDC, balances[i]));
            unchecked { ++i; }
        }
        USDCTotals *= 1e20;
        USDCTotals /= int256(IERC20(BSTABLEPOOL).totalSupply());
    }
}