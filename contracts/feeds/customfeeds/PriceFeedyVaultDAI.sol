pragma solidity ^0.8.0;

import "../../../interfaces/IPriceFeeds.sol";
import "../../interfaces/IyVault.sol";

contract PriceFeedyVaultDAI {
    IPriceFeeds internal constant _priceFeed = IPriceFeeds(0x5AbC9e082Bf6e4F930Bbc79742DA3f6259c4aD1d);
    IyVault public constant VAULT = IyVault(0xdA816459F1AB5631232FE5e97a05BBBb94970c95);
    address internal constant _dai = 0x6B175474E89094C44Da98b954EedeAC495271d0F;
    address internal constant _eth = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    function latestAnswer() external view returns (int256) {
        return int256(_priceFeed.queryReturn(_dai, _eth, VAULT.pricePerShare()));
    }
}