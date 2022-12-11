pragma solidity ^0.8.0;

interface StakingVault {
    event PriceFeed(address feed);
    event Protocol(address protocol);
    event ValuationToken(address token);
    event TokensSupported(address[] supportedTokens);
    event Deposit(address depositor, address tokenBacked, address depositToken, uint256 amount);
    event Withdraw(address withdrawer, address tokenBacked, address receivedToken, uint256 amount);
    event RewardToken(address token);
    event PoolDraw(address tokenBacked, address tokenCovered, uint256 amountCovered);
    event AddRewards(address tokenBacked, uint256 amount);
    event AccumulateRewards(address tokenBacked, uint256 amount);
    event DistributeRewards(address tokenBacked, uint256 amount);

    function updateTokenSupport(address[] memory tokens, bool[] memory support, address[] memory listOfSupportedTokens) external;
    function setRewardToken(address r) external;
    function deposit(address depositToken, address tokenToBack, uint256 amount) external;
    function withdraw(address depositToken, address tokenToBack, uint256 amount) external;
    function getTokenBacked(address depositToken, address tokenToBack) external view returns (uint256);
    function getSupply(address depositToken, address tokenToBack) external view returns (uint256);
    function setPriceFeed(address priceFeed_) external;
    function setValuationToken(address token) external;
    function setProtocol(address protocol_) external;
    function initializeToken(uint256 tokenID) external;
    function priceFeed() external view returns (address);
    function valuationToken() external view returns (address);
    function stakingTokens() external view returns (address[] memory);
    function rewardToken() external view returns (address);

}
