pragma solidity ^0.8.0;

import "./IPriceFeeds.sol";

interface IStakingVault {
    event TokensSupported(address[] supportedTokens);
    event Deposit(address depositor, address tokenBacked, address depositToken, uint256 amount);
    event Withdraw(address withdrawer, address tokenBacked, address receivedToken, uint256 amount);
    event PoolDraw(address tokenBacked, address tokenCovered, uint256 amountCovered);
    event AddRewards(address tokenBacked, uint256 amount);
    event AccumulateRewards(address tokenBacked, uint256 amount);
    event DistributeRewards(address tokenBacked, uint256 amount);

    function updateTokenSupport(address[] memory tokens, bool[] memory support, address[] memory listOfSupportedTokens, uint8[] memory decimals) external;
    function deposit(address depositToken, address tokenToBack, uint256 amount) external;
    function withdraw(address depositToken, address tokenToBack, uint256 amount) external;
    function getStoredTokenPrice(uint256 ID) external view returns (uint256);
    function getBackingAmount(address token) external view returns (uint256);
    function getBackingAmountInNativeTokens(address token) external view returns (uint256[] memory balances);
    function convertToID(address depositToken, address tokenToBack) external pure returns (uint256);
    function addRewards(address tokenBacked, uint256 rewardAmount) external;
    function accumulateRewards(address tokenBacked, uint256 rewardAmount) external;
    function distributeRewards(address tokenBacked) external;
    function claimRewards(uint256[] memory tokenIDs) external;
    function priceFeed() external view returns (IPriceFeeds);
    function protocol() external view returns (address);
    function valuationToken() external view returns (address);
    function stakingTokens() external view returns (address[] memory);
    function rewardToken() external view returns (address);
    function drawOnPool(address tokenBacked, address tokenToCover, uint256 amountToCover) external returns (uint256[] memory);

}
