pragma solidity 0.5.17;

import "../interfaces/IwstETH.sol";

contract PriceFeedwstETH {
    IwstETH public constant wstETHAddress = IwstETH(0x7f39C581F595B53c5cb19bD0b3f8dA6c935E2Ca0);

    function latestAnswer() public view returns (int256) {
        return int256(wstETHAddress.getStETHByWstETH(1e18));
    }
}