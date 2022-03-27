pragma solidity 0.5.17;

import "../IPriceFeedsExt.sol";
import "../../utils/SignedSafeMath.sol";

interface IwstETH {
    function stEthPerToken() external view returns (uint256);
}

contract PriceFeedstETH {
    using SignedSafeMath for int256;

    IPriceFeedsExt public constant priceFeedAddress = IPriceFeedsExt(0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419); // ETHUSD Chainlink feed address
    IwstETH public constant wstETHAddress = IwstETH(0x7f39C581F595B53c5cb19bD0b3f8dA6c935E2Ca0);

    function latestAnswer() public view returns (int256) {
        return
            priceFeedAddress
                .latestAnswer()
                .mul(int256(wstETHAddress.stEthPerToken()))
                .div(1e18);
    }
}
