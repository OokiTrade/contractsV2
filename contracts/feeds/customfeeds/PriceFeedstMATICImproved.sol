pragma solidity ^0.8.0;

import "../../interfaces/IstMATICRateProvider.sol";
import "../../../interfaces/IPriceFeeds.sol";
import "../IPriceFeedsExt.sol";
contract PriceFeedstMATICImproved {

    IPriceFeedsExt public constant MATIC_PRICE_FEED = IPriceFeedsExt(0x5d37E4b374E6907de8Fc7fb33EE3b0af403C7403);
    address internal constant _MATICRATEPROVIDER = 0xdEd6C522d803E35f65318a9a4d7333a22d582199;

    function latestAnswer() external view returns (int256) { 
        return MATIC_PRICE_FEED.latestAnswer() * int256(IstMATICRateProvider(_MATICRATEPROVIDER).getRate())/ 1e18;
    }
}