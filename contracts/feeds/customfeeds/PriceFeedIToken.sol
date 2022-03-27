pragma solidity 0.5.17;

import "../IPriceFeedsExt.sol";
import "../../../interfaces/IToken.sol";
import "../../utils/SignedSafeMath.sol";


contract PriceFeedIToken {
    using SignedSafeMath for int256;

    IPriceFeedsExt public priceFeedAddress; // underlying token Chainlink feed address
    IToken public iTokenAddress;

    constructor(IPriceFeedsExt _priceFeedAddress, IToken _iTokenAddress) public {
        priceFeedAddress = _priceFeedAddress;
        iTokenAddress = _iTokenAddress;
    }

    function latestAnswer() public view returns (int256) {
        return
            priceFeedAddress
                .latestAnswer()
                .mul(int256(iTokenAddress.tokenPrice()))
                .div(1e18);
    }
}
