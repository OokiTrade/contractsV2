pragma solidity ^0.8.0;

import "../../interfaces/IwstETH.sol";
import "../IPriceFeedsExt.sol";
contract PriceFeedwstETH {
    IwstETH public constant wstETHAddress = IwstETH(0x7f39C581F595B53c5cb19bD0b3f8dA6c935E2Ca0);
    IPriceFeedsExt public constant stETHPriceFeed = IPriceFeedsExt(0xCfE54B5cD566aB89272946F602D76Ea879CAb4a8);
    IPriceFeedsExt public constant ethPriceFeed = IPriceFeedsExt(0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419);
    function latestAnswer() public view returns (int256) {
        return int256(wstETHAddress.getStETHByWstETH(1e18))*stETHPriceFeed.latestAnswer()/ethPriceFeed.latestAnswer();
    }
}