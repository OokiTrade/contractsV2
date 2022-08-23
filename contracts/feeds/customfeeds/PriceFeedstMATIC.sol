pragma solidity ^0.8.0;

import "../../interfaces/IstMATICRateProvider.sol";
import "../../../interfaces/IPriceFeeds.sol";
contract PriceFeedstMATIC {
    function latestAnswer() external view returns (int256) {
        uint256 amountToSwap = IstMATICRateProvider(0xdEd6C522d803E35f65318a9a4d7333a22d582199).getRate()*100;

        return int256(IPriceFeeds(0x600F8E7B10CF6DA18871Ff79e4A61B13caCEd9BC)
            .queryReturn(
                0x0d500B1d8E8eF31E21C99d1Db9A6444d3ADf1270,
                0x2791Bca1f2de4661ED88A30C99A7a9449Aa84174,
                amountToSwap
            )
        );
    }
}