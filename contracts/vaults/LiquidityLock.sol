pragma solidity ^0.8.0;

import "../../interfaces/IToken.sol";
import "../../interfaces/IBZx.sol";
import "../proxies/0_8/Upgradeable_0_8.sol";
import "@openzeppelin-4.7.0/token/ERC20/utils/SafeERC20.sol";

contract LiquidityLock is Ownable {
    using SafeERC20 for IERC20;

    event Locked(address indexed user, address indexed iToken, bytes32 claimID, uint256 iTokenAmount, uint256 endTimestamp);
    event Unlocked(address indexed user, bytes32 claimID);
    event ClaimableBonus(address indexed token, uint256 amount);
    event LockCap(address indexed token, uint256 amount);
    event UpdatedSettings(uint256 discount, uint256 discountAddition, uint256 maxLock);
    event LockUpdated(bytes32 indexed claimID, uint256 iTokenAmount);
    IBZx public immutable PROTOCOL;
    address public immutable TREASURY;
    mapping(bytes32=>LockedLiquidity) public claims;
    mapping(address=>uint256) public claimableBonus;
    mapping(address=>Settings) public lockSettings;
    mapping(address=>uint256) public totalLocked;
    mapping(address=>uint256) public lockCap;
    struct LockedLiquidity {
        address token;
        uint256 startTimestamp;
        uint256 endTimestamp;
        uint256 iTokenAmount;
        uint256 originalDeposit;
        uint256 endAmountReceived;
    }
    struct Settings {
        uint256 minimumDiscount;
        uint256 discountAdditionPerSecond;
        uint256 maxLockTime;   
    }
    constructor(IBZx p, address t) {
        PROTOCOL = p;
        TREASURY = t;
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
            startTimestamp:block.timestamp,
            endTimestamp: endTimestamp,
            iTokenAmount: iTokenAmount,
            originalDeposit: depositAmount,
            endAmountReceived: fullAmount
        });

        emit Locked(msg.sender, address(iToken), claimID, iTokenAmount, endTimestamp);
        return claimID;
    }

    function increaseLockup(bytes32 claimID, uint256 increaseDeposit) external {
        LockedLiquidity memory claim = claims[claimID];
        require(claim.endTimestamp > block.timestamp && claim.iTokenAmount != 0, "already unlocked or claimed");
        bytes32 claimIDCheck = keccak256(abi.encode(claim.token,msg.sender,claim.endTimestamp));
        require(claimID == claimIDCheck, "unauthorized");
        uint256 minInterest = claim.endAmountReceived-claim.originalDeposit;
        uint256 aprEarning = minInterest*1e20/claim.originalDeposit;
        uint256 realizedInterest = minInterest*(block.timestamp-claim.startTimestamp)/(claim.endTimestamp-claim.startTimestamp);
        uint256 addedDeposit = realizedInterest+increaseDeposit;
        claim.originalDeposit += addedDeposit;
        IToken iToken = IToken(claim.token);
        address base = iToken.loanTokenAddress();
        totalLocked[base] += addedDeposit;
        require(lockCap[base] >= totalLocked[base], "over committed");
        uint256 newBalanceIncreaseAmount = addedDeposit + addedDeposit*aprEarning/1e20;
        IERC20(base).safeTransferFrom(msg.sender, address(this), addedDeposit);
        claimableBonus[base] -= newBalanceIncreaseAmount - addedDeposit;
        claim.iTokenAmount += iToken.mint(address(this), newBalanceIncreaseAmount);
        claim.endAmountReceived += newBalanceIncreaseAmount;
        claims[claimID] = claim;

        emit LockUpdated(claimID, claim.iTokenAmount);
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
        uint256 amountReceived = iToken.burn(address(this), claim.iTokenAmount);
        uint256 protocolCost = claim.endAmountReceived-claim.originalDeposit;
        
        if (amountReceived-protocolCost > claim.endAmountReceived) {
            receivedAmount = amountReceived-protocolCost;
            IERC20(underlying).transfer(TREASURY, protocolCost);
        } else {
            receivedAmount = claim.endAmountReceived;
            IERC20(underlying).transfer(TREASURY, amountReceived-receivedAmount);
        }
        IERC20(underlying).transfer(msg.sender, receivedAmount);

        emit Unlocked(msg.sender, claimID);

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