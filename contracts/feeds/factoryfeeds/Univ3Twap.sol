pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;
import "@uniswap/v3-periphery/contracts/libraries/OracleLibrary.sol";

import "../../../interfaces/IUniv3Twap.sol";

contract Univ3Twap is IUniv3Twap {
    function twapValue(V3Specs memory specsForTWAP)
        public
        view
        override
        returns (uint256 quoteAmount)
    {
        (int24 timeWeightedAverageTick, ) = OracleLibrary.consult(
            specsForTWAP.pool,
            specsForTWAP.secondsAgo
        );
        quoteAmount = OracleLibrary.getQuoteAtTick(
            timeWeightedAverageTick,
            specsForTWAP.baseAmount,
            specsForTWAP.token0,
            specsForTWAP.token1
        );
    }
}