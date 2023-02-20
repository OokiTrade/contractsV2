pragma solidity ^0.8.0;

import "@openzeppelin-4.8.0/token/ERC1155/ERC1155.sol";
import "@openzeppelin-4.8.0/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin-4.8.0/token/ERC20/extensions/IERC20Metadata.sol";

import "../../interfaces/IPriceFeeds.sol";
import "../proxies/0_8/Upgradeable_0_8.sol";
import "../../interfaces/IStakingVault.sol";

contract StakingVault is IStakingVault, Upgradeable_0_8, ERC1155 {
  using SafeERC20 for IERC20;
  struct TokenComposition {
    address depositToken;
    address tokenToBack;
  }
  address private immutable PROTOCOL;
  IPriceFeeds private immutable PRICE_FEED;
  address private immutable VALUATION_TOKEN;
  address private immutable REWARD_TOKEN;


  address[] private _stakingTokens;
  mapping(address => bool) public tokenSupported;
  mapping(uint256 => uint256) private _sTokenPrice;
  mapping(uint256 => TokenComposition) public identifierToTokens;
  mapping(uint256 => uint256) public balanceStakedPerID;
  mapping(uint256 => uint256) public supplyPerID;

  mapping(address => uint256) public undistributedRewards;
  mapping(uint256 => uint256) public rewardsPerToken;
  
  mapping(address => mapping(uint256 => uint256)) public lastClaimRewardAccrual;
  mapping(uint256 => bool) public initialized;
  mapping(address => uint8) public tokenDecimalCache;

  modifier onlyProtocol() {
    require(msg.sender == PROTOCOL, "not protocol");
    _;
  }

  constructor(string memory uri_, IPriceFeeds pFeed, address rToken, address p, address vToken) ERC1155(uri_) {
    PRICE_FEED = pFeed;
    REWARD_TOKEN = rToken;
    PROTOCOL = p;
    VALUATION_TOKEN = vToken;
  }

  function priceFeed() external view returns (IPriceFeeds) {
    return PRICE_FEED;
  }

  function rewardToken() external view returns (address) {
    return REWARD_TOKEN;
  }

  function protocol() external view returns (address) {
    return PROTOCOL;
  }

  function valuationToken() external view returns (address) {
    return VALUATION_TOKEN;
  }

  function stakingTokens() external view returns (address[] memory) {
    return _stakingTokens;
  }

  function updateTokenSupport(
    address[] memory tokens,
    bool[] memory support,
    address[] memory listOfSupportedTokens,
    uint8[] memory tokenDecimals
  ) external onlyOwner {
    _stakingTokens = listOfSupportedTokens;
    require(tokens.length == tokenDecimals.length, "mismatch");
    for (uint256 i; i < tokens.length; ) {
      tokenSupported[tokens[i]] = support[i];
      if (support[i]) {
        tokenDecimalCache[tokens[i]] = tokenDecimals[i];
      }
      unchecked {
        ++i;
      }
    }

    emit TokensSupported(listOfSupportedTokens);
  }

  function deposit(
    address depositToken,
    address tokenToBack,
    uint256 amount
  ) external {
    require(tokenSupported[depositToken], "unsupported deposit token");
    uint256 tokenID = convertToID(depositToken, tokenToBack);
    if (identifierToTokens[tokenID].depositToken == address(0)) {
      _sTokenPrice[tokenID] = 1e18;
    }
    identifierToTokens[tokenID] = TokenComposition({depositToken: depositToken, tokenToBack: tokenToBack});
    IERC20(depositToken).safeTransferFrom(msg.sender, address(this), amount);
    uint256 mintAmount = _amountToMint(tokenID, amount);
    _claimReward(tokenID);
    _mint(msg.sender, tokenID, mintAmount, "");
    balanceStakedPerID[tokenID] += amount;
    supplyPerID[tokenID] += mintAmount;

    emit Deposit(msg.sender, tokenToBack, depositToken, amount);
  }

  function withdraw(
    address depositToken,
    address tokenToBack,
    uint256 amount
  ) external {
    uint256 tokenID = convertToID(depositToken, tokenToBack);
    _claimReward(tokenID);
    _burn(msg.sender, tokenID, amount);
    supplyPerID[tokenID] -= amount;
    uint256 sendAmount = _amountToSend(tokenID, amount);
    balanceStakedPerID[tokenID] -= sendAmount;
    IERC20(depositToken).safeTransfer(msg.sender, sendAmount);

    emit Withdraw(msg.sender, tokenToBack, depositToken, amount);
  }

  function drawOnPool(
    address tokenBacked,
    address tokenToCover,
    uint256 amountToCover
  ) external onlyProtocol returns (uint256[] memory) {
    address[] memory tokensStaked = _stakingTokens;
    uint256[] memory valuesPerToken = new uint256[](tokensStaked.length);
    uint256 totalValue;
    for (uint256 i = 0; i < tokensStaked.length; ) {
      valuesPerToken[i] = PRICE_FEED.queryReturn(tokensStaked[i], VALUATION_TOKEN, balanceStakedPerID[convertToID(tokensStaked[i], tokenBacked)]);
      totalValue += valuesPerToken[i];
      unchecked {
        ++i;
      }
    }
    uint256[] memory amountDrawnPerToken = new uint256[](tokensStaked.length);
    uint256 valueOfCoverage = PRICE_FEED.queryReturn(tokenToCover, VALUATION_TOKEN, amountToCover);
    for (uint256 i = 0; i < tokensStaked.length; ) {
      amountDrawnPerToken[i] = PRICE_FEED.queryReturn(VALUATION_TOKEN, tokensStaked[i], (valueOfCoverage * valuesPerToken[i]) / totalValue);
      IERC20(tokensStaked[i]).safeTransfer(msg.sender, amountDrawnPerToken[i]);
      unchecked {
        ++i;
      }
    }

    _updatePrice(tokenBacked, amountDrawnPerToken);

    emit PoolDraw(tokenBacked, tokenToCover, amountToCover);
    return amountDrawnPerToken;
  }

  function getStoredTokenPrice(uint256 ID) external view returns (uint256) {
    return _sTokenPrice[ID];
  }

  function getBackingAmount(address token) external view returns (uint256) {
    address[] memory tokensStaked = _stakingTokens;
    uint256 value;
    for (uint256 i; i < tokensStaked.length; ) {
      value += PRICE_FEED.queryReturn(tokensStaked[i], VALUATION_TOKEN, balanceStakedPerID[convertToID(token, tokensStaked[i])]);
    }
    return value;
  }

  function getBackingAmountInNativeTokens(address token) external view returns (uint256[] memory balances) {
    address[] memory tokensStaked = _stakingTokens;
    balances = new uint256[](tokensStaked.length);
    for (uint256 i; i < tokensStaked.length; ) {
      balances[i] = balanceStakedPerID[convertToID(token, tokensStaked[i])];
      unchecked {
        ++i;
      }
    }
  }

  function convertToID(address depositToken, address tokenToBack) public pure returns (uint256) {
    return uint256(keccak256(abi.encode(depositToken, tokenToBack)));
  }

  function addRewards(address tokenBacked, uint256 rewardAmount) external {
    _addRewards(rewardAmount, tokenBacked);
    IERC20(REWARD_TOKEN).safeTransferFrom(msg.sender, address(this), rewardAmount);

    emit AddRewards(tokenBacked, rewardAmount);
  }

  function accumulateRewards(address tokenBacked, uint256 rewardAmount) external {
    undistributedRewards[tokenBacked] += rewardAmount;
    IERC20(REWARD_TOKEN).safeTransferFrom(msg.sender, address(this), rewardAmount);

    emit AccumulateRewards(tokenBacked, rewardAmount);
  }

  function distributeRewards(address tokenBacked) external {
    uint256 rewards = undistributedRewards[tokenBacked];
    _addRewards(rewards, tokenBacked);
    undistributedRewards[tokenBacked] = 0;

    emit DistributeRewards(tokenBacked, rewards);
  }

  function claimRewards(uint256[] memory tokenIDs) external {
    for (uint256 i; i < tokenIDs.length; ) {
      _claimReward(tokenIDs[i]);
      unchecked {
        ++i;
      }
    }
  }

  function _updatePrice(address tokenBacked, uint256[] memory amountsDrawn) internal {
    address[] memory tokensStaked = _stakingTokens;
    uint256 previousBalance;
    for (uint256 i = 0; i < tokensStaked.length; ) {
      uint256 tokenID = convertToID(tokensStaked[i], tokenBacked);
      previousBalance = balanceStakedPerID[tokenID];
      balanceStakedPerID[tokenID] = previousBalance - amountsDrawn[i];
      _sTokenPrice[tokenID] = (_sTokenPrice[tokenID] * (previousBalance - balanceStakedPerID[tokenID])) / previousBalance;
      unchecked {
        ++i;
      }
    }
  }

  function _amountToMint(uint256 tokenID, uint256 amount) internal view returns (uint256) {
    uint8 decimals = tokenDecimalCache[identifierToTokens[tokenID].depositToken];

    return ((amount * 1e18) / _sTokenPrice[tokenID]) * 10**(18 - decimals);
  }

  function _amountToSend(uint256 tokenID, uint256 amountBurnt) internal view returns (uint256) {
    uint8 decimals = IERC20Metadata(identifierToTokens[tokenID].depositToken).decimals();

    return ((_sTokenPrice[tokenID] * amountBurnt) / 1e18) / 10**(18 - decimals);
  }

  function _addRewards(uint256 rewardAmount, address tokenBacked) internal {
    address[] memory tokensStaked = _stakingTokens;
    uint256 totalValue;
    uint256[] memory values = new uint256[](tokensStaked.length);
    uint256 tokenID;
    for (uint256 i; i < tokensStaked.length; ) {
      tokenID = convertToID(tokensStaked[i], tokenBacked);
      values[i] = PRICE_FEED.queryReturn(tokensStaked[i], VALUATION_TOKEN, balanceStakedPerID[tokenID]);
      totalValue += values[i];
      unchecked {
        ++i;
      }
    }
    for (uint256 i; i < tokensStaked.length; ) {
      tokenID = convertToID(tokensStaked[i], tokenBacked);
      values[i] = (values[i] * 1e18) / totalValue;
      rewardsPerToken[tokenID] += (rewardAmount * values[i]) / supplyPerID[tokenID];
      unchecked {
        ++i;
      }
    }
  }

  function _claimReward(uint256 tokenID) internal {
    uint256 previousAmount = lastClaimRewardAccrual[msg.sender][tokenID];
    if (previousAmount == 0 && initialized[tokenID]) {
      lastClaimRewardAccrual[msg.sender][tokenID] = rewardsPerToken[tokenID];
      return;
    }
    uint256 newAmount = rewardsPerToken[tokenID];
    if (newAmount - previousAmount == 0) {
      return;
    }
    IERC20(REWARD_TOKEN).safeTransfer(msg.sender, ((newAmount - previousAmount) * balanceOf(msg.sender, tokenID)) / 1e18);
    if (!initialized[tokenID] && newAmount > 0) {
      initialized[tokenID] = true;
    }
    lastClaimRewardAccrual[msg.sender][tokenID] = newAmount;
  }
}
