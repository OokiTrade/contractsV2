pragma solidity ^0.8.0;

import "../../interfaces/ICurvePool.sol";
import "../IPriceFeedsExt.sol";

contract PriceFeedCurvestETH {

    ICurvePool public constant POOL = ICurvePool(0xDC24316b9AE028F1497c275EB9192a3Ea0f67022);
    IPriceFeedsExt public constant stETHPriceFeed = IPriceFeedsExt(0xCfE54B5cD566aB89272946F602D76Ea879CAb4a8);
    IPriceFeedsExt public constant ethPriceFeed = IPriceFeedsExt(0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419);
    function latestAnswer() external view returns (int256) {
        return int256(POOL.get_virtual_price())*stETHPriceFeed.latestAnswer()/ethPriceFeed.latestAnswer();
    }
}