pragma solidity 0.5.17;

import "../../interfaces/IToken.sol";
import "./PriceFeeds.sol";
import "../utils/SignedSafeMath.sol";

contract PriceFeedIToken {
    using SignedSafeMath for int256;
    address public underlyingToken;
    PriceFeeds public constant PRICE_FEED = PriceFeeds(address(0)); //set to price feed contract on the chain
    IToken public iTokenAddress;

    constructor(address underlying, IToken iToken) public {
        iTokenAddress = iToken;
        underlyingToken = underlying;
    }

    function latestAnswer() public view returns (int256) {
        return
            IPriceFeedsExt(PRICE_FEED.pricesFeeds(underlyingToken))
                .latestAnswer()
                .mul(int256(iTokenAddress.tokenPrice()))
                .div(1e18);
    }
}
