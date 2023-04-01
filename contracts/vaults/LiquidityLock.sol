pragma solidity ^0.8.0;

import "../../interfaces/IToken.sol";
import "../../interfaces/IBZx.sol";
import "@openzeppelin-4.7.0/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin-4.7.0/access/Ownable.sol";

contract LiquidityLock is Ownable{
    using SafeERC20 for IERC20;

    event Locked(address indexed user, address indexed iToken, bytes32 claimID, uint256 iTokenAmount, uint256 endTimestamp);
    event Unlocked(address indexed user, bytes32 claimID);
    event ClaimableBonus(address indexed token, uint256 amount);
    event LockCap(address indexed token, uint256 amount);
    event UpdatedSettings(uint256 discount, uint256 discountAddition, uint256 maxLock);
    IBZx public immutable PROTOCOL;

    mapping(bytes32=>LockedLiquidity) public claims;
    mapping(address=>uint256) public claimableBonus;
    mapping(address=>Settings) public lockSettings;
    mapping(address=>uint256) public totalLocked;
    mapping(address=>uint256) public lockCap;
    struct LockedLiquidity {
        address token;
        uint256 endTimestamp;
        uint256 iTokenAmount;
        uint256 originalDeposit;
    }
    struct Settings {
        uint256 minimumDiscount;
        uint256 discountAdditionPerSecond;
        uint256 maxLockTime;   
    }
    constructor(IBZx p) {
        PROTOCOL = p;
    }

    function lock(address base, uint256 depositAmount, uint256 endTimestamp) external returns (bytes32 claimID) {
        Settings memory tokenSettings = lockSettings[base];
        IToken iToken = IToken(PROTOCOL.underlyingToLoanPool(base));
        claimID = keccak256(abi.encode(address(iToken),msg.sender,endTimestamp));
        require(claims[claimID].token == address(0), "already used id");
        require(block.timestamp <= endTimestamp && endTimestamp-block.timestamp<tokenSettings.maxLockTime, "invalid ending time");
        IERC20(base).safeTransferFrom(msg.sender, address(this), depositAmount);
        uint256 discountAmount = tokenSettings.minimumDiscount+tokenSettings.discountAdditionPerSecond*(endTimestamp-block.timestamp);
        discountAmount = discountAmount*(endTimestamp-block.timestamp) / 31557600;
        uint256 fullAmount = depositAmount*1e20/(1e20-discountAmount);
        claimableBonus[base] -= fullAmount-depositAmount;
        totalLocked[base] += depositAmount;
        require(lockCap[base] >= totalLocked[base], "over committed");
        uint256 iTokenAmount = iToken.mint(address(this), fullAmount);
        claims[claimID] = LockedLiquidity({
            token:address(iToken),
            endTimestamp: endTimestamp,
            iTokenAmount: iTokenAmount,
            originalDeposit: depositAmount
        });

        emit Locked(msg.sender, address(iToken), claimID, iTokenAmount, endTimestamp);
    }

    function unlock(bytes32 claimID) external returns (uint256 receivedAmount) {
        LockedLiquidity memory claim = claims[claimID];
        bytes32 claimIDCheck = keccak256(abi.encode(claim.token,msg.sender,claim.endTimestamp));
        require(claimID == claimIDCheck, "unauthorized");
        require(block.timestamp >= claim.endTimestamp, "not unlocked yet");
        claims[claimID].iTokenAmount = 0;
        IToken iToken = IToken(claim.token);
        address underlying = iToken.loanTokenAddress();
        totalLocked[underlying] -= claim.originalDeposit;
        IERC20(claim.token).transfer(msg.sender, claim.iTokenAmount);

        emit Unlocked(msg.sender, claimID);

        return claim.iTokenAmount;
    }

    function setApprovals(IERC20[] memory tokens, address[] memory receivers) external onlyOwner {
        require(tokens.length==receivers.length,"mismatch");
        for (uint i; i<tokens.length;) {
            tokens[i].safeApprove(receivers[i], 0);
            tokens[i].safeApprove(receivers[i], type(uint256).max);
            unchecked { ++i; }
        }
    }

    function increaseClaimableBonus(address[] memory tokens, uint256[] memory amounts) external {
        require(tokens.length==amounts.length, "mismatch");
        for (uint i; i<tokens.length;) {
            IERC20(tokens[i]).safeTransferFrom(msg.sender, address(this), amounts[i]);
            claimableBonus[tokens[i]] += amounts[i];
            emit ClaimableBonus(tokens[i], claimableBonus[tokens[i]]);
            unchecked { ++i; }
        }
        
    }

    function setLockCap(address[] memory tokens, uint256[] memory amounts) external onlyOwner {
        require(tokens.length==amounts.length, "mismatch");
        for (uint i; i<tokens.length;) {
            lockCap[tokens[i]] = amounts[i];
            emit LockCap(tokens[i], amounts[i]);
            unchecked { ++i; }
        }
    }

    function updateSettings(address token, uint256 minDiscount, uint256 discountPerSecond, uint256 maxLocking) external onlyOwner {
        Settings memory settings = lockSettings[token];
        if (minDiscount != 0) {
            settings.minimumDiscount = minDiscount;
        }
        if (discountPerSecond != 0) {
            settings.discountAdditionPerSecond = discountPerSecond;
        }
        if (maxLocking != 0) {
            settings.maxLockTime = maxLocking;
        }
        lockSettings[token] = settings;
        emit UpdatedSettings(settings.minimumDiscount, settings.discountAdditionPerSecond, settings.maxLockTime);
    }
}