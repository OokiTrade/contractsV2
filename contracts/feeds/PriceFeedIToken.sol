pragma solidity 0.5.17;

import "../../interfaces/IToken.sol";
import "./PriceFeeds.sol";
import "../utils/SignedSafeMath.sol";

contract PriceFeedIToken {
    using SignedSafeMath for int256;
    address public underlyingToken;
    PriceFeeds public constant PRICE_FEED = PriceFeeds(0x5AbC9e082Bf6e4F930Bbc79742DA3f6259c4aD1d); //Ethereum PriceFeeds contract
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
