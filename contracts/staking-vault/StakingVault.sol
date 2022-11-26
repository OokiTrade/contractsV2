pragma solidity ^0.8.0;

import "@openzeppelin-4.7.0/token/ERC1155/ERC1155.sol";
import "@openzeppelin-4.7.0/token/ERC20/utils/SafeERC20.sol";
import "../../interfaces/IPriceFeeds.sol";
import "../proxies/0_8/Upgradeable_0_8.sol";
contract StakingVault is Upgradeable_0_8, ERC1155 {
    using SafeERC20 for IERC20;
    struct tokenComposition {
        address depositToken;
        address tokenToBack;
    }
    address public protocol;
    IPriceFeeds public priceFeed;
    address public valuationToken;
    address[] public stakingTokens;
    mapping(address=>bool) public tokenSupported;
    mapping(uint256=>uint256) public sTokenPrice;
    mapping(uint256=>tokenComposition) public IDToTokens;
    mapping(uint256=>uint256) public balanceStakedPerID;
    mapping(uint256=>uint256) public supplyPerID;

    mapping(address=>uint256) public undistributedRewards;
    mapping(uint256=>uint256) public rewardsPerToken;
    address public rewardToken;
    mapping(address=>mapping(uint256=>uint256)) public lastClaimRewardAccrual;

    modifier onlyProtocol() {
        require(msg.sender==protocol, "not protocol");_;
    }

    constructor(string memory uri_)ERC1155(uri_) {}

    function updateTokenSupport(address[] memory tokens, bool[] memory support, address[] memory listOfSupportedTokens) external onlyOwner {
        stakingTokens = listOfSupportedTokens;
        for (uint i; i<tokens.length;) {
            tokenSupported[tokens[i]] = support[i];
            unchecked { ++i; }
        }

    }

    function setRewardToken(address r) external onlyOwner {
        rewardToken = r;
    }

    function deposit(address depositToken, address tokenToBack, uint256 amount) external {
        require(tokenSupported[depositToken], "unsupported deposit token");
        uint256 tokenID = convertToID(depositToken, tokenToBack);
        if (IDToTokens[tokenID].depositToken == address(0)) {
            sTokenPrice[tokenID] = 1e18;
        }
        IDToTokens[tokenID] = tokenComposition({depositToken:depositToken, tokenToBack:tokenToBack});
        uint256 mintAmount = _amountToMint(tokenID, amount);
        _claimReward(tokenID);
        _mint(msg.sender, tokenID, mintAmount, "");
        balanceStakedPerID[tokenID] += amount;
        supplyPerID[tokenID] += mintAmount;
        IERC20(depositToken).safeTransferFrom(msg.sender, address(this), amount);
    }

    function withdraw(address depositToken, address tokenToBack, uint256 amount) external {
        uint256 tokenID = convertToID(depositToken, tokenToBack);
        _claimReward(tokenID);
        _burn(msg.sender, tokenID, amount);
        supplyPerID[tokenID] -= amount;
        uint256 sendAmount = _amountToSend(tokenID, amount);
        balanceStakedPerID[tokenID] -= sendAmount;
        IERC20(depositToken).safeTransfer(msg.sender, sendAmount);
    }

    function drawOnPool(address tokenBacked, uint256 amountToCover) external onlyProtocol returns (uint256[] memory) {
        uint256 valueOfCoverage = priceFeed.queryReturn(tokenBacked, valuationToken, amountToCover);
        address[] memory tokensStaked = stakingTokens;
        uint256[] memory tokenAmounts = new uint256[](tokensStaked.length);
        uint256[] memory valuesPerToken = new uint256[](tokenAmounts.length);
        uint256 totalValue;
        for (uint i=0;i<tokensStaked.length;) {
            tokenAmounts[i] = balanceStakedPerID[convertToID(tokensStaked[i], tokenBacked)];
            valuesPerToken[i] = priceFeed.queryReturn(tokensStaked[i], valuationToken, tokenAmounts[i]);
            totalValue += valuesPerToken[i];
            unchecked { ++i; }
        }
        uint256[] memory amountDrawnPerToken = new uint256[](tokenAmounts.length);
        for (uint i = 0;i<amountDrawnPerToken.length;) {
            amountDrawnPerToken[i] = tokenAmounts[i]*valueOfCoverage*valuesPerToken[i]/totalValue/1e18;
            IERC20(tokensStaked[i]).safeTransfer(msg.sender, amountDrawnPerToken[i]);
            unchecked {++i;}
        }

        _updatePrice(tokenBacked, amountDrawnPerToken);
        return amountDrawnPerToken;
    }

    function _updatePrice(address tokenBacked, uint256[] memory amountsDrawn) internal {
        address[] memory tokensStaked = stakingTokens;
        for (uint i=0;i<tokensStaked.length;) {
            uint256 tokenID = convertToID(tokensStaked[i], tokenBacked);
            balanceStakedPerID[tokenID] -= amountsDrawn[i];
            sTokenPrice[tokenID] = balanceStakedPerID[tokenID]*1e18/supplyPerID[tokenID];
            unchecked { ++i; }
        }
    }

    function getBackingAmount(address token) external view returns (uint256) {
        address[] memory tokensStaked = stakingTokens;
        uint256 value;
        for (uint i;i<tokensStaked.length;) {
            value += priceFeed.queryReturn(tokensStaked[i], valuationToken, balanceStakedPerID[convertToID(token, tokensStaked[i])]);
        }
        return value;
    }

    function getBackingAmountInNativeTokens(address token) external view returns (uint256[] memory balances) {
        address[] memory tokensStaked = stakingTokens;
        balances = new uint256[](tokensStaked.length);
        for (uint i;i<tokensStaked.length;) {
            balances[i] = balanceStakedPerID[convertToID(token, tokensStaked[i])];
            unchecked { ++i; }
        }
    }

    function convertToID(address depositToken, address tokenToBack) public pure returns (uint256) {
        return uint256(keccak256(abi.encode(depositToken,tokenToBack)));
    }

    function _amountToMint(uint256 tokenID, uint256 amount) internal returns (uint256) {
        return amount*1e18/sTokenPrice[tokenID];
    }

    function _amountToSend(uint256 tokenID, uint256 amountBurnt) internal returns (uint256) {
        return sTokenPrice[tokenID]*amountBurnt/1e18;
    }

    function addRewards(uint256 rewardAmount, address tokenBacked) external {
        _addRewards(rewardAmount, tokenBacked);
        IERC20(rewardToken).safeTransferFrom(msg.sender, address(this), rewardAmount);
    }

    function accumulateRewards(uint256 rewardAmount, address tokenBacked) external {
        undistributedRewards[tokenBacked] += rewardAmount;
        IERC20(rewardToken).safeTransferFrom(msg.sender, address(this), rewardAmount);
    }

    function distributeRewards(address tokenBacked) external {
        _addRewards(undistributedRewards[tokenBacked], tokenBacked);
        undistributedRewards[tokenBacked] = 0;
    }

    function _addRewards(uint256 rewardAmount, address tokenBacked) internal {
        address[] memory tokensStaked = stakingTokens;
        uint256 totalValue;
        uint256[] memory tokenAmounts = new uint256[](tokensStaked.length);
        uint256[] memory values = new uint256[](tokensStaked.length);
        uint256 tokenID;
        for (uint i;i<tokensStaked.length;) {
            tokenID = convertToID(tokensStaked[i], tokenBacked);
            tokenAmounts[i] = balanceStakedPerID[tokenID];
            values[i] = priceFeed.queryReturn(tokensStaked[i], valuationToken, tokenAmounts[i]);
            totalValue += values[i];
            unchecked { ++i; }
        }
        for (uint i;i<tokensStaked.length;) {
            tokenID = convertToID(tokensStaked[i], tokenBacked);
            values[i] = values[i]*1e18/totalValue;
            rewardsPerToken[tokenID] += rewardAmount*values[i]/supplyPerID[tokenID];
            unchecked { ++i; }
        }
    }

    function claimRewards(uint256[] memory tokenIDs) external {
        for (uint i;i<tokenIDs.length;) {
            _claimReward(tokenIDs[i]);
            unchecked { ++i; }
        }
    }

    function _claimReward(uint256 tokenID) internal {
        uint256 previousAmount = lastClaimRewardAccrual[msg.sender][tokenID];
        if (previousAmount == 0) {
            lastClaimRewardAccrual[msg.sender][tokenID] = rewardsPerToken[tokenID];
            return;
        }
        uint256 newAmount = rewardsPerToken[tokenID];
        IERC20(rewardToken).safeTransfer(msg.sender, (newAmount-previousAmount)*supplyPerID[tokenID]);
        lastClaimRewardAccrual[msg.sender][tokenID] = newAmount;
    }

    function setPriceFeed(IPriceFeeds p) external onlyOwner {
        priceFeed = p;
    }

    function setProtocol(address p) external onlyOwner {
        protocol = p;
    }

    function setValuationToken(address v) external onlyOwner {
        valuationToken = v;
    }

}