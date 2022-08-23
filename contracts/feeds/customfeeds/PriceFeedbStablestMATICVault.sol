pragma solidity ^0.8.0;

import "../../../interfaces/IPriceFeeds.sol";
import "../../interfaces/IVault.sol";

contract PriceFeedbStablestMATICVault {
    IPriceFeeds internal constant _priceFeed = IPriceFeeds(0x600F8E7B10CF6DA18871Ff79e4A61B13caCEd9BC);
    IVault internal constant _bStableVault = IVault(address(0));

    address public constant BSTABLE = 0xaF5E0B5425dE1F5a630A8cB5AA9D97B8141C908D;
    address public constant USDC = 0x2791Bca1f2de4661ED88A30C99A7a9449Aa84174;

    function latestAnswer() external view returns (int256) {
        return int256(_priceFeed.queryReturn(BSTABLE, USDC, _bStableVault.convertToAssets(1e18)))*100;
    }
}