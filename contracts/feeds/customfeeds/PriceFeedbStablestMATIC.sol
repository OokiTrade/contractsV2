pragma solidity ^0.8.0;

import "../../../interfaces/IPriceFeeds.sol";
import "../../interfaces/IBalancerVault.sol";
import "../../interfaces/IBalancerPool.sol";

import "@openzeppelin-4.7.0/token/ERC20/IERC20.sol";
contract PriceFeedbStablestMATIC {
    IPriceFeeds internal constant _PRICEFEED = IPriceFeeds(0x600F8E7B10CF6DA18871Ff79e4A61B13caCEd9BC);

    address public constant WMATIC = 0x0d500B1d8E8eF31E21C99d1Db9A6444d3ADf1270;
    address public constant USDC = 0x2791Bca1f2de4661ED88A30C99A7a9449Aa84174;
    address public constant BSTABLEPOOL = 0xaF5E0B5425dE1F5a630A8cB5AA9D97B8141C908D;

    IBalancerPool.OracleAverageQuery public TWAP = IBalancerPool.OracleAverageQuery({
        variable: 1,
        secs: 1200,
        ago: 300
    });

    function latestAnswer() external view returns (int256 USDCTotals) {
        IBalancerPool.OracleAverageQuery[] memory sets = new IBalancerPool.OracleAverageQuery[](1);
        sets[0] = TWAP;
        uint256 poolPrice = IBalancerPool(BSTABLEPOOL).getTimeWeightedAverage(sets)[0];
        USDCTotals = int256(_PRICEFEED.queryReturn(WMATIC, USDC, poolPrice))*100;
    }
}