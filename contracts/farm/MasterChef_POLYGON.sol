pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

/// SPDX-License-Identifier: MIT

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "./Upgradeable.sol";
import "./PGovToken.sol";
import "./MintCoordinator_BSC.sol";


contract MasterChef_POLYGON is Upgradeable {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    // Info of each user.
    struct UserInfo {
        uint256 amount; // How many LP tokens the user has provided.
        uint256 rewardDebt; // Reward debt. See explanation below.
        //
        // We do some fancy math here. Basically, any point in time, the amount of PGOVs
        // entitled to a user but is pending to be distributed is:
        //
        //   pending reward = (user.amount * pool.accPGOVPerShare) - user.rewardDebt
        //
        // Whenever a user deposits or withdraws LP tokens to a pool. Here's what happens:
        //   1. The pool's `accPGOVPerShare` (and `lastRewardBlock`) gets updated.
        //   2. User receives the pending reward sent to his/her address.
        //   3. User's `amount` gets updated.
        //   4. User's `rewardDebt` gets updated.
    }
    // Info of each pool.
    struct PoolInfo {
        IERC20 lpToken; // Address of LP token contract.
        uint256 allocPoint; // How many allocation points assigned to this pool. PGOVs to distribute per block.
        uint256 lastRewardBlock; // Last block number that PGOVs distribution occurs.
        uint256 accPGOVPerShare; // Accumulated PGOVs per share, times 1e12. See below.
    }
    // The PGOV TOKEN!
    PGovToken public PGOV;
    // Dev address.
    address public devaddr;
    // Block number when bonus PGOV period ends.
    uint256 public bonusEndBlock;
    // PGOV tokens created per block.
    uint256 public PGOVPerBlock;
    // Bonus muliplier for early PGOV makers.
    uint256 public constant BONUS_MULTIPLIER = 10;
    // unused
    address public migrator;
    // Info of each pool.
    PoolInfo[] public poolInfo;
    // Info of each user that stakes LP tokens.
    mapping(uint256 => mapping(address => UserInfo)) public userInfo;
    // Total allocation poitns. Must be the sum of all allocation points in all pools.
    uint256 public totalAllocPoint = 0;
    // The block number when PGOV mining starts.
    uint256 public startBlock;
    event Deposit(address indexed user, uint256 indexed pid, uint256 amount);
    event Withdraw(address indexed user, uint256 indexed pid, uint256 amount);
    event EmergencyWithdraw(
        address indexed user,
        uint256 indexed pid,
        uint256 amount
    );

    MintCoordinator public constant coordinator = MintCoordinator(0xfffffffffffffffffffffffffffffff);

    mapping(IERC20 => bool) public poolExists;
    modifier nonDuplicated(IERC20 _lpToken) {
        require(!poolExists[_lpToken], "pool exists");
        _;
    }

    function initialize(
        PGovToken _PGOV,
        address _devaddr,
        uint256 _PGOVPerBlock,
        uint256 _startBlock,
        uint256 _bonusEndBlock
    ) public onlyOwner {
        require(address(PGOV) == address(0), "unauthorized");
        PGOV = _PGOV;
        devaddr = _devaddr;
        PGOVPerBlock = _PGOVPerBlock;
        bonusEndBlock = _bonusEndBlock;
        startBlock = _startBlock;
    }

    function poolLength() external view returns (uint256) {
        return poolInfo.length;
    }

    // Add a new lp to the pool. Can only be called by the owner.
    function add(uint256 _allocPoint, IERC20 _lpToken, bool _withUpdate)
        public
        onlyOwner
        nonDuplicated(_lpToken)
    {
        if (_withUpdate) {
            massUpdatePools();
        }
        uint256 lastRewardBlock =
            block.number > startBlock ? block.number : startBlock;
        totalAllocPoint = totalAllocPoint.add(_allocPoint);
        poolExists[_lpToken] = true;
        poolInfo.push(
            PoolInfo({
                lpToken: _lpToken,
                allocPoint: _allocPoint,
                lastRewardBlock: lastRewardBlock,
                accPGOVPerShare: 0
            })
        );
    }

    // Update the given pool's PGOV allocation point. Can only be called by the owner.
    function set(uint256 _pid, uint256 _allocPoint, bool _withUpdate)
        public
        onlyOwner
    {
        if (_withUpdate) {
            massUpdatePools();
        }
        totalAllocPoint = totalAllocPoint.sub(poolInfo[_pid].allocPoint).add(
            _allocPoint
        );
        poolInfo[_pid].allocPoint = _allocPoint;
    }

    function transferTokenOwnership(address newOwner)
        public
        onlyOwner
    {
        PGOV.transferOwnership(newOwner);
    }


    function getMultiplier(uint256 _from, uint256 _to)
        public
        view
        returns (uint256)
    {
        return getMultiplierPrecise(_from, _to).div(1e18);
    }

    function getMultiplierNow()
        public
        view
        returns (uint256)
    {
        return getMultiplierPrecise(block.number - 1, block.number);
    }

    function getMultiplierPrecise(uint256 _from, uint256 _to)
        public
        view
        returns (uint256)
    {
        uint256 _bonusEndBlock = bonusEndBlock;
        if (_to <= _bonusEndBlock) {
            return _to.sub(_from).mul(BONUS_MULTIPLIER).mul(1e18);
        } else if (_from >= _bonusEndBlock) {
            return _getDecliningMultipler(_from, _to, _bonusEndBlock);
        } else {
            return
                _bonusEndBlock.sub(_from).mul(BONUS_MULTIPLIER).mul(1e18).add(
                    _getDecliningMultipler(_bonusEndBlock, _to, _bonusEndBlock)
                );
        }
    }

    function _getDecliningMultipler(uint256 _from, uint256 _to, uint256 _bonusStartBlock)
        internal
        view
        returns (uint256)
    {
        // _periodBlocks = 864000 = 60 * 60 * 24 * 30 / 3 = blocks_in_30_days
        uint256 _bonusEndBlock = _bonusStartBlock + 864000;

        // multiplier = 7.64e18 = BONUS_MULTIPLIER * 191 / 250 * 10^18
        // declinePerBlock = 7685185185185 = (7.64e18 - 1e18) / _periodBlocks

        uint256 _startMultipler;
        uint256 _endMultipler;
        uint256 _avgMultiplier;

        if (_to <= _bonusEndBlock) {
            _startMultipler = SafeMath.sub(7.64e18,
                _from.sub(_bonusStartBlock)
                    .mul(7685185185185)
            );

            _endMultipler = SafeMath.sub(7.64e18,
                _to.sub(_bonusStartBlock)
                    .mul(7685185185185)
            );

            _avgMultiplier = (_startMultipler + _endMultipler) / 2;

            return _to.sub(_from).mul(_avgMultiplier);
        } else if (_from >= _bonusEndBlock) {
            return _to.sub(_from).mul(1e18);
        } else {

            _startMultipler = SafeMath.sub(7.64e18,
                _from.sub(_bonusStartBlock)
                    .mul(7685185185185)
            );

            _endMultipler = 1e18;

            _avgMultiplier = (_startMultipler + _endMultipler) / 2;

            return _bonusEndBlock.sub(_from).mul(_avgMultiplier).add(
                    _to.sub(_bonusEndBlock).mul(1e18)
                );
        }
    }
    
    function _pendingPGOV(uint256 _pid, address _user)
        internal
        view
        returns (uint256)
    {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][_user];
        uint256 accPGOVPerShare = pool.accPGOVPerShare.mul(1e18);
        uint256 lpSupply = pool.lpToken.balanceOf(address(this));
        if (block.number > pool.lastRewardBlock && lpSupply != 0) {
            uint256 multiplier =
                getMultiplierPrecise(pool.lastRewardBlock, block.number);
            uint256 PGOVReward =
                multiplier.mul(PGOVPerBlock).mul(pool.allocPoint).div(
                    totalAllocPoint
                );
            accPGOVPerShare = accPGOVPerShare.add(
                PGOVReward.mul(1e12).div(lpSupply)
            );
        }
        return user.amount.mul(accPGOVPerShare).div(1e30).sub(user.rewardDebt);
    }


    // View function to see pending PGOVs on frontend.
    function pendingPGOV(uint256 _pid, address _user)
        external
        view
        returns (uint256)
    {
        return _pendingPGOV(_pid, _user);
    }


    // Update reward vairables for all pools. Be careful of gas spending!
    function massUpdatePools() public {
        uint256 length = poolInfo.length;
        for (uint256 pid = 0; pid < length; ++pid) {
            updatePool(pid);
        }
    }

    // Update reward variables of the given pool to be up-to-date.
    function updatePool(uint256 _pid) public {
        PoolInfo storage pool = poolInfo[_pid];
        if (block.number <= pool.lastRewardBlock) {
            return;
        }
        uint256 lpSupply = pool.lpToken.balanceOf(address(this));
        if (lpSupply == 0) {
            pool.lastRewardBlock = block.number;
            return;
        }
        uint256 multiplier = getMultiplierPrecise(pool.lastRewardBlock, block.number);
        uint256 PGOVReward =
            multiplier.mul(PGOVPerBlock).mul(pool.allocPoint).div(
                totalAllocPoint
            );
        coordinator.mint(devaddr, PGOVReward.div(1e19));
        coordinator.mint(address(this), PGOVReward.div(1e18));
        pool.accPGOVPerShare = pool.accPGOVPerShare.add(
            PGOVReward.div(1e6).div(lpSupply)
        );
        pool.lastRewardBlock = block.number;
    }

    // Deposit LP tokens to MasterChef for PGOV allocation.
    function deposit(uint256 _pid, uint256 _amount) public {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        updatePool(_pid);
        if (user.amount > 0) {
            uint256 pending =
                user.amount.mul(pool.accPGOVPerShare).div(1e12).sub(
                    user.rewardDebt
                );
            safePGOVTransfer(msg.sender, pending);
        }
        pool.lpToken.safeTransferFrom(
            address(msg.sender),
            address(this),
            _amount
        );
        user.amount = user.amount.add(_amount);
        user.rewardDebt = user.amount.mul(pool.accPGOVPerShare).div(1e12);
        emit Deposit(msg.sender, _pid, _amount);
    }

    function claimReward(uint256 _pid) public {
        deposit(_pid, 0);
    }

    // Withdraw LP tokens from MasterChef.
    function withdraw(uint256 _pid, uint256 _amount) public {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        require(user.amount >= _amount, "withdraw: not good");
        updatePool(_pid);
        uint256 pending =
            user.amount.mul(pool.accPGOVPerShare).div(1e12).sub(
                user.rewardDebt
            );
        safePGOVTransfer(msg.sender, pending);
        user.amount = user.amount.sub(_amount);
        user.rewardDebt = user.amount.mul(pool.accPGOVPerShare).div(1e12);
        pool.lpToken.safeTransfer(address(msg.sender), _amount);
        emit Withdraw(msg.sender, _pid, _amount);
    }

    // Withdraw without caring about rewards. EMERGENCY ONLY.
    function emergencyWithdraw(uint256 _pid) public {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        pool.lpToken.safeTransfer(address(msg.sender), user.amount);
        emit EmergencyWithdraw(msg.sender, _pid, user.amount);
        user.amount = 0;
        user.rewardDebt = 0;
    }

    // Safe PGOV transfer function, just in case if rounding error causes pool to not have enough PGOVs.
    function safePGOVTransfer(address _to, uint256 _amount) internal {
        uint256 PGOVBal = PGOV.balanceOf(address(this));
        if (_amount > PGOVBal) {
            PGOV.transfer(_to, PGOVBal);
        } else {
            PGOV.transfer(_to, _amount);
        }
    }

    // Update dev address by the previous dev.
    function dev(address _devaddr) public {
        require(msg.sender == devaddr, "dev: wut?");
        devaddr = _devaddr;
    }


    // Custom logic - helpers


    function getPoolInfos() external view returns(PoolInfo[] memory poolInfos){
        uint256 length = poolInfo.length;
        poolInfos = new PoolInfo[](length);
        for (uint256 pid = 0; pid < length; ++pid) {
            poolInfos[pid] = poolInfo[pid];
        }
    }

    function getOptimisedUserInfos(address _user) external view returns(uint256[2][] memory userInfos){
        uint256 length = poolInfo.length;
        userInfos = new uint256[2][](length);
        for (uint256 pid = 0; pid < length; ++pid) {
            userInfos[pid][0] = userInfo[pid][_user].amount;
            userInfos[pid][1] = _pendingPGOV(pid, _user);

        }
    }

    function getUserInfos(address _wallet) external view returns(UserInfo[] memory userInfos){
        uint256 length = poolInfo.length;
        userInfos = new UserInfo[](length);
        for (uint256 pid = 0; pid < length; ++pid) {
            userInfos[pid] = userInfo[pid][_wallet];
        }
    }

    function getPendingPGOV(address _user) external view returns(uint256[] memory pending){
        uint256 length = poolInfo.length;
        pending = new uint256[](length);
        for (uint256 pid = 0; pid < length; ++pid) {
            pending[pid] = _pendingPGOV(pid, _user);
        }
    }

}