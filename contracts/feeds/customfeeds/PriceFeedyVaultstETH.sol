pragma solidity ^0.8.0;

import "../../../interfaces/IPriceFeeds.sol";
import "../../interfaces/IyVault.sol";

contract PriceFeedyVaultstETH {
    IPriceFeeds internal constant _priceFeed = IPriceFeeds(0x5AbC9e082Bf6e4F930Bbc79742DA3f6259c4aD1d);
    IyVault public constant VAULT = IyVault(0xdCD90C7f6324cfa40d7169ef80b12031770B4325);
    address internal constant _steCRV = 0x06325440D014e39736583c165C2963BA99fAf14E;
    address internal constant _eth = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    function latestAnswer() external view returns (int256) {
        return int256(_priceFeed.queryReturn(_steCRV, _eth, VAULT.pricePerShare()));
    }
}