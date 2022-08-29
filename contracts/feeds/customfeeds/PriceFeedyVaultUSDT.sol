pragma solidity ^0.8.0;

import "../../../interfaces/IPriceFeeds.sol";
import "../../interfaces/IyVault.sol";

contract PriceFeedyVaultUSDT {
    IPriceFeeds internal constant _priceFeed = IPriceFeeds(0x5AbC9e082Bf6e4F930Bbc79742DA3f6259c4aD1d);
    IyVault public constant VAULT = IyVault(0x3B27F92C0e212C671EA351827EDF93DB27cc0c65);
    address internal constant _usdt = 0xdAC17F958D2ee523a2206206994597C13D831ec7;
    address internal constant _eth = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    function latestAnswer() external view returns (int256) {
        return int256(_priceFeed.queryReturn(_usdt, _eth, VAULT.pricePerShare()));
    }
}