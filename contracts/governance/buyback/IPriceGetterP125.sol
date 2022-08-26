pragma solidity >=0.6.12;
pragma experimental ABIEncoderV2;

interface IPriceGetterP125 {
    struct V3Specs {
        address token0;
        address token1;
        address pool;
        uint128 baseAmount;
        uint32 secondsAgo;
        bytes route;
    }

    function worstExecPrice(V3Specs memory specs)
        external
        view
        returns (uint256 quoteAmount);
}
