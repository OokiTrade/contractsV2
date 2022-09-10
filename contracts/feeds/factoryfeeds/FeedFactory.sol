pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;

import "../../../interfaces/IUniv3Twap.sol";
import "../../governance/PausableGuardian_0_8.sol";
import "./FactoryFeed.sol";
import "../../../interfaces/IPriceFeeds.sol";

contract FeedFactory is PausableGuardian_0_8{
    address public constant QUOTE = address(0);
    address public constant PRICE_FEEDS = address(0);
    address public constant UNIV3_FACTORY = address(0);
    IUniv3Twap.V3Specs public specs;

    constructor() {}

    /* Code from PoolAddress.sol from Uniswap repo but there is compiler issue so it is fixed in here */
    bytes32 internal constant POOL_INIT_CODE_HASH = 0xe34f199b19b2b4f47f68442619d555527d244f78a3297ea89325f843f87b8b54;

    /// @notice The identifying key of the pool
    struct PoolKey {
        address token0;
        address token1;
        uint24 fee;
    }

    /// @notice Returns PoolKey: the ordered tokens with the matched fee levels
    /// @param tokenA The first token of a pool, unsorted
    /// @param tokenB The second token of a pool, unsorted
    /// @param fee The fee level of the pool
    /// @return Poolkey The pool details with ordered token0 and token1 assignments
    function getPoolKey(
        address tokenA,
        address tokenB,
        uint24 fee
    ) internal pure returns (PoolKey memory) {
        if (tokenA > tokenB) (tokenA, tokenB) = (tokenB, tokenA);
        return PoolKey({token0: tokenA, token1: tokenB, fee: fee});
    }

    function computeAddress(address factory, PoolKey memory key) internal pure returns (address pool) {
        require(key.token0 < key.token1);
        pool = address(
            uint160(
                uint256(
                    keccak256(
                        abi.encodePacked(
                            hex'ff',
                            factory,
                            keccak256(abi.encode(key.token0, key.token1, key.fee)),
                            POOL_INIT_CODE_HASH
                        )
                    )
                )
            )
        );
    }

    /* End of code from PoolAddress.sol */

    function newPriceFeed(address token) public {

        address pool = computeAddress(UNIV3_FACTORY, getPoolKey(token, QUOTE, 3000));
        FactoryFeed f = new FactoryFeed(token, QUOTE, pool);
        address[] memory tokens = new address[](1);
        address[] memory feeds = new address[](1);
        tokens[0] = token;
        feeds[0] = address(f);
        require(IPriceFeeds(PRICE_FEEDS).pricesFeeds(token) == address(0), "already populated");
        IPriceFeeds(PRICE_FEEDS).setPriceFeed(tokens, feeds);
    }

    function setSpecs(IUniv3Twap.V3Specs calldata newSpecs) external onlyOwner {
        specs = newSpecs;
    }
}