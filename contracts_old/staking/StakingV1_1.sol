/**
 * Copyright 2017-2022, OokiDao. All Rights Reserved.
 * Licensed under the Apache License, Version 2.0.
 */

pragma solidity 0.5.17;
pragma experimental ABIEncoderV2;

import "./StakingState.sol";
import "./StakingConstants.sol";
import "../interfaces/IVestingToken.sol";
import "../../interfaces/IBZx.sol";
import "../../interfaces/IPriceFeeds.sol";
import "../utils/MathUtil.sol";
import "../interfaces/IMasterChefSushi.sol";
import "../../interfaces/IStaking.sol";
import "../governance/PausableGuardian.sol";

contract StakingV1_1 is StakingState, StakingConstants, PausableGuardian {
    using MathUtil for uint256;

    modifier onlyEOA() {
        require(msg.sender == tx.origin, "unauthorized");
        _;
    }

    function _pendingSushiRewards(address _user)
        internal
        view
        returns (uint256)
    {
        uint256 pendingSushi = IMasterChefSushi(SUSHI_MASTERCHEF)
            .pendingSushi(BZRX_ETH_SUSHI_MASTERCHEF_PID, address(this));

        uint256 totalSupply = _totalSupplyPerToken[LPToken];
        return _pendingAltRewards(
            SUSHI,
            _user,
            balanceOfByAsset(LPToken, _user),
            totalSupply != 0 ? pendingSushi.mul(1e12).div(totalSupply) : 0
        );
    }

    function _pendingAltRewards(address token, address _user, uint256 userSupply, uint256 extraRewardsPerShare)
        internal
        view
        returns (uint256)
    {
        uint256 _altRewardsPerShare = altRewardsPerShare[token].add(extraRewardsPerShare);
        if (_altRewardsPerShare == 0)
            return 0;

        IStaking.AltRewardsUserInfo memory altRewardsUserInfo = userAltRewardsPerShare[_user][token];
        return altRewardsUserInfo.pendingRewards.add(
                (_altRewardsPerShare.sub(altRewardsUserInfo.rewardsPerShare)).mul(userSupply).div(1e12)
            );
    }

    function _depositToSushiMasterchef(uint256 amount)
        internal
    {
        uint256 sushiBalanceBefore = IERC20(SUSHI).balanceOf(address(this));
        IMasterChefSushi(SUSHI_MASTERCHEF).deposit(
            BZRX_ETH_SUSHI_MASTERCHEF_PID,
            amount
        );
        uint256 sushiRewards = IERC20(SUSHI).balanceOf(address(this)) - sushiBalanceBefore;
        if (sushiRewards != 0) {
            _addAltRewards(SUSHI, sushiRewards);
        }
    }

    function _withdrawFromSushiMasterchef(uint256 amount)
        internal
    {
        uint256 sushiBalanceBefore = IERC20(SUSHI).balanceOf(address(this));
        IMasterChefSushi(SUSHI_MASTERCHEF).withdraw(
            BZRX_ETH_SUSHI_MASTERCHEF_PID,
            amount
        );
        uint256 sushiRewards = IERC20(SUSHI).balanceOf(address(this)) - sushiBalanceBefore;
        if (sushiRewards != 0) {
            _addAltRewards(SUSHI, sushiRewards);
        }
    }

    function withdrawFrom3Pool(uint256 amount)
        public onlyGuardian
    {
        _withdrawFrom3Pool(amount);
    }

    function _withdrawFrom3Pool(uint256 amount)
        internal
    {
        if(amount != 0)
            curve3PoolGauge.withdraw(amount);

        //Trigger claim rewards from curve pool
        curveMinter.mint(address(curve3PoolGauge));
    }


    function unstake(
        address[] memory tokens,
        uint256[] memory values
    )
        public
        pausable
        updateRewards(msg.sender)
    {
        require(tokens.length == values.length, "count mismatch");

        for (uint256 i = 0; i < tokens.length; i++) {
            address token = tokens[i];
            require(token == BZRX || token == vBZRX || token == iBZRX || token == LPToken || token == LPTokenOld, "invalid token");

            uint256 unstakeAmount = values[i];
            uint256 stakedAmount = _balancesPerToken[token][msg.sender];
            if (unstakeAmount == 0 || stakedAmount == 0) {
                continue;
            }
            if (unstakeAmount > stakedAmount) {
                unstakeAmount = stakedAmount;
            }

            uint256 pendingBefore = (token == LPToken) ? _pendingSushiRewards(msg.sender) : 0;

            _balancesPerToken[token][msg.sender] = stakedAmount - unstakeAmount; // will not overflow
            _totalSupplyPerToken[token] = _totalSupplyPerToken[token] - unstakeAmount; // will not overflow

            if (token == BZRX && IERC20(BZRX).balanceOf(address(this)) < unstakeAmount) {
                // settle vested BZRX only if needed
                IVestingToken(vBZRX).claim();
            }

            // Withdraw to sushi masterchef
            if (token == LPToken) {
                _withdrawFromSushiMasterchef(unstakeAmount);

                userAltRewardsPerShare[msg.sender][SUSHI] = IStaking.AltRewardsUserInfo({
                        rewardsPerShare: altRewardsPerShare[SUSHI],
                        pendingRewards: pendingBefore
                    }
                );

            }
            IERC20(token).safeTransfer(msg.sender, unstakeAmount);

            emit Unstake(
                msg.sender,
                token,
                address(0), //currentDelegate
                unstakeAmount
            );
        }
    }

    function claim(
        bool restake)
        external
        pausable
        updateRewards(msg.sender)
        returns (uint256 bzrxRewardsEarned, uint256 stableCoinRewardsEarned)
    {
        return _claim(restake);
    }


    function claimAltRewards()
        public
        pausable
        returns (uint256 sushiRewardsEarned)
    {
        sushiRewardsEarned = _claimSushi();

        if(sushiRewardsEarned != 0){
            emit ClaimAltRewards(msg.sender, SUSHI, sushiRewardsEarned);
        }
    }

    function claimBzrx()
        external
        pausable
        updateRewards(msg.sender)
        returns (uint256 bzrxRewardsEarned)
    {
        bzrxRewardsEarned = _claimBzrx(false);

        emit Claim(
            msg.sender,
            bzrxRewardsEarned,
            0
        );
    }

    function claim3Crv()
        external
        pausable
        updateRewards(msg.sender)
        returns (uint256 stableCoinRewardsEarned)
    {
        stableCoinRewardsEarned = _claim3Crv();

        emit Claim(
            msg.sender,
            0,
            stableCoinRewardsEarned
        );
    }

    function claimSushi()
        external
        pausable
        returns (uint256 sushiRewardsEarned)
    {
        sushiRewardsEarned = _claimSushi();
        if(sushiRewardsEarned != 0){
            emit ClaimAltRewards(msg.sender, SUSHI, sushiRewardsEarned);
        }
    }

    function _claim(
        bool restake)
        internal
        returns (uint256 bzrxRewardsEarned, uint256 stableCoinRewardsEarned)
    {
        bzrxRewardsEarned = _claimBzrx(false);
        stableCoinRewardsEarned = _claim3Crv();

        emit Claim(
            msg.sender,
            bzrxRewardsEarned,
            stableCoinRewardsEarned
        );
    }

    function _claimBzrx(
        bool restake)
        internal
        returns (uint256 bzrxRewardsEarned)
    {
        bzrxRewardsEarned = bzrxRewards[msg.sender];
        if (bzrxRewardsEarned != 0) {
            bzrxRewards[msg.sender] = 0;

            uint256 vestingAmount = bzrxVesting[msg.sender];
            if (vestingAmount != 0) {
                (vestingAmount,) = _discountVesting(vestingAmount, 0);
                bzrxRewardsEarned += vestingAmount;
                bzrxVesting[msg.sender] = 0;
            }


            if (IERC20(BZRX).balanceOf(address(this)) < bzrxRewardsEarned) {
                // settle vested BZRX only if needed
                IVestingToken(vBZRX).claim();
            }

            IERC20(BZRX).transfer(msg.sender, bzrxRewardsEarned);

        }
    }

    function _claim3Crv()
        internal 
        returns (uint256 stableCoinRewardsEarned)
    {
        stableCoinRewardsEarned = stableCoinRewards[msg.sender];
        if (stableCoinRewardsEarned != 0) {
            stableCoinRewards[msg.sender] = 0;

            uint256 vestingAmount = stableCoinVesting[msg.sender];
            if (vestingAmount != 0) {
                (,vestingAmount) = _discountVesting(0, vestingAmount);
                stableCoinRewardsEarned += vestingAmount;
                stableCoinVesting[msg.sender] = 0;
            }

            curve3Crv.transfer(msg.sender, stableCoinRewardsEarned);
        }
    }

    function _claimSushi()
        internal
        returns (uint256)
    {
        address _user = msg.sender;
        uint256 lptUserSupply = balanceOfByAsset(LPToken, _user);

        //This will trigger claim rewards from sushi masterchef
        _depositToSushiMasterchef(
            IERC20(LPToken).balanceOf(address(this))
        );

        uint256 pendingSushi = _pendingAltRewards(SUSHI, _user, lptUserSupply, 0);

        userAltRewardsPerShare[_user][SUSHI] = IStaking.AltRewardsUserInfo({
                rewardsPerShare: altRewardsPerShare[SUSHI],
                pendingRewards: 0
            }
        );
        if (pendingSushi != 0) {
            IERC20(SUSHI).safeTransfer(_user, pendingSushi);
        }


        return pendingSushi;
    }

    function exit()
        public
        // unstake() does check pausable
    {
        address[] memory tokens = new address[](4);
        uint256[] memory values = new uint256[](4);
        tokens[0] = iBZRX;
        tokens[1] = LPToken;
        tokens[2] = vBZRX;
        tokens[3] = BZRX;
        values[0] = uint256(-1);
        values[1] = uint256(-1);
        values[2] = uint256(-1);
        values[3] = uint256(-1);
        
        unstake(tokens, values); // calls updateRewards
        _claim(false);
        claimAltRewards();
    }

    modifier updateRewards(address account) {
        uint256 _bzrxPerTokenStored = bzrxPerTokenStored;
        uint256 _stableCoinPerTokenStored = stableCoinPerTokenStored;

        (uint256 bzrxRewardsEarned, uint256 stableCoinRewardsEarned, uint256 bzrxRewardsVesting, uint256 stableCoinRewardsVesting) = _earned(
            account,
            _bzrxPerTokenStored,
            _stableCoinPerTokenStored
        );
        bzrxRewardsPerTokenPaid[account] = _bzrxPerTokenStored;
        stableCoinRewardsPerTokenPaid[account] = _stableCoinPerTokenStored;

        // vesting amounts get updated before sync
        bzrxVesting[account] = bzrxRewardsVesting;
        stableCoinVesting[account] = stableCoinRewardsVesting;

        (bzrxRewards[account], stableCoinRewards[account]) = _syncVesting(
            account,
            bzrxRewardsEarned,
            stableCoinRewardsEarned,
            bzrxRewardsVesting,
            stableCoinRewardsVesting
        );
        vestingLastSync[account] = block.timestamp;

        _;
    }

    function _discountVesting(
        uint256 bzrxRewardsVesting,
        uint256 stableCoinRewardsVesting)
        internal
        view
        returns (uint256, uint256)
    {
        // discount vesting amounts for vesting time
        uint256 multiplier = vestedBalanceForAmount(
            1e36,
            0,
            block.timestamp
        );
        if (bzrxRewardsVesting != 0) {
            bzrxRewardsVesting = bzrxRewardsVesting
                .sub(bzrxRewardsVesting
                    .mul(multiplier)
                    .div(1e36)
                );
        }
        if (stableCoinRewardsVesting != 0) {
            stableCoinRewardsVesting = stableCoinRewardsVesting
                .sub(stableCoinRewardsVesting
                    .mul(multiplier)
                    .div(1e36)
                );
        }
        return (bzrxRewardsVesting, stableCoinRewardsVesting);
    }

    function earned(
        address account)
        external
        view
        returns (uint256 bzrxRewardsEarned, uint256 stableCoinRewardsEarned, uint256 bzrxRewardsVesting,
            uint256 stableCoinRewardsVesting, uint256 sushiRewardsEarned)
    {
        (bzrxRewardsEarned, stableCoinRewardsEarned, bzrxRewardsVesting, stableCoinRewardsVesting) = _earned(
            account,
            bzrxPerTokenStored,
            stableCoinPerTokenStored
        );

        (bzrxRewardsEarned, stableCoinRewardsEarned) = _syncVesting(
            account,
            bzrxRewardsEarned,
            stableCoinRewardsEarned,
            bzrxRewardsVesting,
            stableCoinRewardsVesting
        );

        (bzrxRewardsVesting, stableCoinRewardsVesting) = _discountVesting(bzrxRewardsVesting, stableCoinRewardsVesting);
        bzrxRewardsEarned += bzrxRewardsVesting;
        bzrxRewardsVesting = 0;
        stableCoinRewardsEarned += stableCoinRewardsVesting;
        stableCoinRewardsVesting = 0;

        uint256 pendingSushi = IMasterChefSushi(SUSHI_MASTERCHEF)
            .pendingSushi(BZRX_ETH_SUSHI_MASTERCHEF_PID, address(this));

        sushiRewardsEarned = _pendingAltRewards(
            SUSHI,
            account,
            balanceOfByAsset(LPToken, account),
            (_totalSupplyPerToken[LPToken] != 0) ? pendingSushi.mul(1e12).div(_totalSupplyPerToken[LPToken]) : 0
        );
    }

    function _earned(
        address account,
        uint256 _bzrxPerToken,
        uint256 _stableCoinPerToken)
        internal
        view
        returns (uint256 bzrxRewardsEarned, uint256 stableCoinRewardsEarned, uint256 bzrxRewardsVesting, uint256 stableCoinRewardsVesting)
    {
        uint256 bzrxPerTokenUnpaid = _bzrxPerToken.sub(bzrxRewardsPerTokenPaid[account]);
        uint256 stableCoinPerTokenUnpaid = _stableCoinPerToken.sub(stableCoinRewardsPerTokenPaid[account]);

        bzrxRewardsEarned = bzrxRewards[account];
        stableCoinRewardsEarned = stableCoinRewards[account];
        bzrxRewardsVesting = bzrxVesting[account];
        stableCoinRewardsVesting = stableCoinVesting[account];

        if (bzrxPerTokenUnpaid != 0 || stableCoinPerTokenUnpaid != 0) {
            uint256 value;
            uint256 multiplier;
            uint256 lastSync;

            (uint256 vestedBalance, uint256 vestingBalance) = balanceOfStored(account);

            value = vestedBalance
                .mul(bzrxPerTokenUnpaid);
            value /= 1e36;
            bzrxRewardsEarned = value
                .add(bzrxRewardsEarned);

            value = vestedBalance
                .mul(stableCoinPerTokenUnpaid);
            value /= 1e36;
            stableCoinRewardsEarned = value
                .add(stableCoinRewardsEarned);

            if (vestingBalance != 0 && bzrxPerTokenUnpaid != 0) {
                // add new vesting amount for BZRX
                value = vestingBalance
                    .mul(bzrxPerTokenUnpaid);
                value /= 1e36;
                bzrxRewardsVesting = bzrxRewardsVesting
                    .add(value);

                // true up earned amount to vBZRX vesting schedule
                lastSync = vestingLastSync[account];
                multiplier = vestedBalanceForAmount(
                    1e36,
                    0,
                    lastSync
                );
                value = value
                    .mul(multiplier);
                value /= 1e36;
                bzrxRewardsEarned = bzrxRewardsEarned
                    .add(value);
            }
            if (vestingBalance != 0 && stableCoinPerTokenUnpaid != 0) {
                // add new vesting amount for 3crv
                value = vestingBalance
                    .mul(stableCoinPerTokenUnpaid);
                value /= 1e36;
                stableCoinRewardsVesting = stableCoinRewardsVesting
                    .add(value);

                // true up earned amount to vBZRX vesting schedule
                if (lastSync == 0) {
                    lastSync = vestingLastSync[account];
                    multiplier = vestedBalanceForAmount(
                        1e36,
                        0,
                        lastSync
                    );
                }
                value = value
                    .mul(multiplier);
                value /= 1e36;
                stableCoinRewardsEarned = stableCoinRewardsEarned
                    .add(value);
            }
        }
    }

    function _syncVesting(
        address account,
        uint256 bzrxRewardsEarned,
        uint256 stableCoinRewardsEarned,
        uint256 bzrxRewardsVesting,
        uint256 stableCoinRewardsVesting)
        internal
        view
        returns (uint256, uint256)
    {
        uint256 lastVestingSync = vestingLastSync[account];

        if (lastVestingSync != block.timestamp) {
            uint256 rewardsVested;
            uint256 multiplier = vestedBalanceForAmount(
                1e36,
                lastVestingSync,
                block.timestamp
            );

            if (bzrxRewardsVesting != 0) {
                rewardsVested = bzrxRewardsVesting
                    .mul(multiplier)
                    .div(1e36);
                bzrxRewardsEarned += rewardsVested;
            }

            if (stableCoinRewardsVesting != 0) {
                rewardsVested = stableCoinRewardsVesting
                    .mul(multiplier)
                    .div(1e36);
                stableCoinRewardsEarned += rewardsVested;
            }

            uint256 vBZRXBalance = _balancesPerToken[vBZRX][account];
            if (vBZRXBalance != 0) {
                // add vested BZRX to rewards balance
                rewardsVested = vBZRXBalance
                    .mul(multiplier)
                    .div(1e36);
                bzrxRewardsEarned += rewardsVested;
            }
        }

        return (bzrxRewardsEarned, stableCoinRewardsEarned);
    }

    function _addAltRewards(address token, uint256 amount) internal {

        address poolAddress = token == SUSHI ? LPToken : token;

        uint256 totalSupply = _totalSupplyPerToken[poolAddress];
        require(totalSupply != 0, "no deposits");

        altRewardsPerShare[token] = altRewardsPerShare[token]
            .add(amount.mul(1e12).div(totalSupply));

        emit AddAltRewards(msg.sender, token, amount);
    }

    function getVariableWeights()
        public
        view
        returns (uint256 vBZRXWeight, uint256 iBZRXWeight, uint256 LPTokenWeight)
    {
        uint256 totalVested = vestedBalanceForAmount(
            _startingVBZRXBalance,
            0,
            block.timestamp
        );

        vBZRXWeight = SafeMath.mul(_startingVBZRXBalance - totalVested, 1e18) // overflow not possible
            .div(_startingVBZRXBalance);

        iBZRXWeight = _calcIBZRXWeight();

        uint256 lpTokenSupply = _totalSupplyPerToken[LPToken];
        if (lpTokenSupply != 0) {
            // staked LP tokens are assumed to represent the total unstaked supply (circulated supply - staked BZRX)
            uint256 normalizedLPTokenSupply = initialCirculatingSupply +
                totalVested -
                _totalSupplyPerToken[BZRX];

            LPTokenWeight = normalizedLPTokenSupply
                .mul(1e18)
                .div(lpTokenSupply);
        }
    }

    function _calcIBZRXWeight()
        internal
        view
        returns (uint256)
    {
        return IERC20(BZRX).balanceOf(iBZRX)
            .mul(1e50)
            .div(IERC20(iBZRX).totalSupply());
    }

    function balanceOfByAsset(
        address token,
        address account)
        public
        view
        returns (uint256 balance)
    {
        balance = _balancesPerToken[token][account];
    }

    function balanceOfByAssets(
        address account)
        external
        view
        returns (
            uint256 bzrxBalance,
            uint256 iBZRXBalance,
            uint256 vBZRXBalance,
            uint256 LPTokenBalance,
            uint256 LPTokenBalanceOld
        )
    {
        return (
            balanceOfByAsset(BZRX, account),
            balanceOfByAsset(iBZRX, account),
            balanceOfByAsset(vBZRX, account),
            balanceOfByAsset(LPToken, account),
            balanceOfByAsset(LPTokenOld, account)
        );
    }

    function balanceOfStored(
        address account)
        public
        view
        returns (uint256 vestedBalance, uint256 vestingBalance)
    {
        uint256 balance = _balancesPerToken[vBZRX][account];
        if (balance != 0) {
            vestingBalance = balance
                .mul(vBZRXWeightStored)
                .div(1e18);
        }

        vestedBalance = _balancesPerToken[BZRX][account];

        balance = _balancesPerToken[iBZRX][account];
        if (balance != 0) {
            vestedBalance = balance
                .mul(iBZRXWeightStored)
                .div(1e50)
                .add(vestedBalance);
        }

        balance = _balancesPerToken[LPToken][account];
        if (balance != 0) {
            vestedBalance = balance
                .mul(LPTokenWeightStored)
                .div(1e18)
                .add(vestedBalance);
        }
    }

    function totalSupplyByAsset(
        address token)
        external
        view
        returns (uint256)
    {
        return _totalSupplyPerToken[token];
    }

    function vestedBalanceForAmount(
        uint256 tokenBalance,
        uint256 lastUpdate,
        uint256 vestingEndTime)
        public
        view
        returns (uint256 vested)
    {
        vestingEndTime = vestingEndTime.min256(block.timestamp);
        if (vestingEndTime > lastUpdate) {
            if (vestingEndTime <= vestingCliffTimestamp ||
                lastUpdate >= vestingEndTimestamp) {
                // time cannot be before vesting starts
                // OR all vested token has already been claimed
                return 0;
            }
            if (lastUpdate < vestingCliffTimestamp) {
                // vesting starts at the cliff timestamp
                lastUpdate = vestingCliffTimestamp;
            }
            if (vestingEndTime > vestingEndTimestamp) {
                // vesting ends at the end timestamp
                vestingEndTime = vestingEndTimestamp;
            }

            uint256 timeSinceClaim = vestingEndTime.sub(lastUpdate);
            vested = tokenBalance.mul(timeSinceClaim) / vestingDurationAfterCliff; // will never divide by 0
        }
    }

    // OnlyOwner functions
    function updateSettings(
        address settingsTarget,
        bytes memory callData)
        public
        onlyOwner
        returns(bytes memory)
    {
        (bool result,) = settingsTarget.delegatecall(callData);
        assembly {
            let size := returndatasize
            let ptr := mload(0x40)
            returndatacopy(ptr, 0, size)
            if eq(result, 0) { revert(ptr, size) }
            return(ptr, size)
        }
    }


    function rescue(IERC20 _token, uint256 amount, address receiver) public onlyGuardian {
        require(address(_token) == CRV || _token == curve3Crv, "Invalid token");
        SafeERC20.safeTransfer(_token, receiver, amount);
    }
}
