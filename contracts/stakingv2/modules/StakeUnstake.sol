/**
 * Copyright 2017-2022, OokiDao. All Rights Reserved.
 * Licensed under the Apache License, Version 2.0.
 */

pragma solidity ^0.8.0;

import "../StakingStateV2.sol";
import "./StakingPausableGuardian.sol";
import "../../interfaces/IMasterChefSushi2.sol";
import "../delegation/VoteDelegator.sol";
import "../../interfaces/IVestingToken.sol";
import "./Common.sol";

contract StakeUnstake is Common {
    using SafeERC20 for IERC20;
    
    function initialize(address target) external onlyOwner {
        _setTarget(this.totalSupplyByAsset.selector, target);
        _setTarget(this.stake.selector, target);
        _setTarget(this.unstake.selector, target);
        _setTarget(this.claim.selector, target);
        _setTarget(this.claimAltRewards.selector, target);
        _setTarget(this.claimBzrx.selector, target);
        _setTarget(this.claim3Crv.selector, target);
        _setTarget(this.claimSushi.selector, target);
        _setTarget(this.earned.selector, target);
        _setTarget(this.addAltRewards.selector, target);
        _setTarget(this.balanceOfByAsset.selector, target);
        _setTarget(this.balanceOfByAssets.selector, target);
        _setTarget(this.balanceOfStored.selector, target);
        _setTarget(this.vestedBalanceForAmount.selector, target);
        _setTarget(this.exit.selector, target);
    }

    function totalSupplyByAsset(
        address token)
    external
    view
    returns (uint256)
    {
        return _totalSupplyPerToken[token];
    }

    function _pendingSushiRewards(address _user) internal view returns (uint256) {
        uint256 lpBalance =  balanceOfByAsset(OOKI_ETH_LP, _user);
        IStakingV2.AltRewardsUserInfo memory altRewardsUserInfo = userAltRewardsInfo[_user][SUSHI];
        uint256 pendingSushi = IMasterChefSushi2(SUSHI_MASTERCHEF).pendingSushi(OOKI_ETH_SUSHI_MASTERCHEF_PID, address(this));
        return _pendingAltRewards(SUSHI, _user, lpBalance, altRewardsUserInfo, pendingSushi);
    }

    function _pendingAltRewards(
        address token,
        address _user,
        uint256 userSupply,
        IStakingV2.AltRewardsUserInfo memory altRewardsUserInfo,
        uint256 extraRewards
    ) internal view returns (uint256) {
        uint256 total;
        if(userSupply != 0){
            uint256 _stakingStartBlock = altRewardsUserInfo.stakingStartBlock;
            if(altRewardsUserInfo.stakingStartBlock > block.number)
                return 0;

            uint256 _altRewardsBlock  = altRewardsBlock[token]; // Last time when addAltRewards was triggered
            uint256 _altRewardsStartBlock = altRewardsStartBlock[token];
            if(_stakingStartBlock < _altRewardsStartBlock){
                _stakingStartBlock = _altRewardsStartBlock;
            }

            uint256 _altRewardsPerShare;
            uint256 _altRewardsPerSharePerBlock;
            if(extraRewards != 0){
                (_altRewardsPerShare, _altRewardsPerSharePerBlock, _altRewardsBlock)  = _addAltRewards(token, extraRewards);
            }
            else{
                _altRewardsPerShare = altRewardsPerShare[token];
                _altRewardsPerSharePerBlock = altRewardsPerSharePerBlock[token];
            }
            total = (_altRewardsBlock - _stakingStartBlock) * _altRewardsPerSharePerBlock * userSupply / 1e12;
        }

        return total + altRewardsUserInfo.pending;
    }

    function _depositToSushiMasterchef(uint256 amount) internal {
        IMasterChefSushi2(SUSHI_MASTERCHEF).deposit(OOKI_ETH_SUSHI_MASTERCHEF_PID, amount, address(this));
    }

    function _withdrawFromSushiMasterchef(uint256 amount) internal {
        IMasterChefSushi2(SUSHI_MASTERCHEF).withdraw(OOKI_ETH_SUSHI_MASTERCHEF_PID, amount, address(this));
    }

    function stake(address[] memory tokens, uint256[] memory values) public pausable updateRewards(msg.sender) {
        require(tokens.length == values.length, "count mismatch");
        VoteDelegator _voteDelegator = VoteDelegator(voteDelegator);
        address currentDelegate = _voteDelegator.delegates(msg.sender);

        ProposalState memory _proposalState = _getProposalState();
        uint256 votingBalanceBefore = _votingFromStakedBalanceOf(msg.sender, _proposalState, true);
        for (uint256 i = 0; i < tokens.length; i++) {
            address token = tokens[i];
            require(token == OOKI || token == vBZRX || token == iOOKI || token == OOKI_ETH_LP, "invalid token");

            uint256 stakeAmount = values[i];
            if (stakeAmount == 0) {
                continue;
            }
            uint256 stakedAmount = _balancesPerToken[token][msg.sender];
            uint256 _balanceAfter = stakedAmount + stakeAmount;
            _totalSupplyPerToken[token] = _totalSupplyPerToken[token] + stakeAmount;

            IERC20(token).safeTransferFrom(msg.sender, address(this), stakeAmount);
            // Deposit to sushi masterchef
            if (token == OOKI_ETH_LP) {
                _depositToSushiMasterchef(IERC20(OOKI_ETH_LP).balanceOf(address(this)));
                if(userAltRewardsInfo[msg.sender][SUSHI].stakingStartBlock == 0){
                    userAltRewardsInfo[msg.sender][SUSHI].stakingStartBlock = block.number;
                    userAltRewardsInfo[msg.sender][SUSHI].pending = 0;
                }

                uint256 _pending = _pendingSushiRewards(msg.sender);
                userAltRewardsInfo[msg.sender][SUSHI].stakingStartBlock = block.number;
                userAltRewardsInfo[msg.sender][SUSHI].pending = _pending;
            }
            _balancesPerToken[token][msg.sender] = _balanceAfter;
            emit Stake(msg.sender, token, currentDelegate, stakeAmount);
        }

        _voteDelegator.moveDelegatesByVotingBalance(votingBalanceBefore, _votingFromStakedBalanceOf(msg.sender, _proposalState, true), msg.sender);
    }

    function unstake(address[] memory tokens, uint256[] memory values) public pausable updateRewards(msg.sender) {
        require(tokens.length == values.length, "count mismatch");

        VoteDelegator _voteDelegator = VoteDelegator(voteDelegator);
        address currentDelegate = _voteDelegator.delegates(msg.sender);

        ProposalState memory _proposalState = _getProposalState();
        uint256 votingBalanceBefore = _votingFromStakedBalanceOf(msg.sender, _proposalState, true);

        for (uint256 i = 0; i < tokens.length; i++) {
            address token = tokens[i];
            require(token == OOKI || token == vBZRX || token == iOOKI || token == OOKI_ETH_LP, "invalid token");

            uint256 unstakeAmount = values[i];
            uint256 stakedAmount = _balancesPerToken[token][msg.sender];
            if (unstakeAmount == 0 || stakedAmount == 0) {
                continue;
            }
            if (unstakeAmount > stakedAmount) {
                unstakeAmount = stakedAmount;
            }

            uint256 _balanceAfter = stakedAmount - unstakeAmount; // will not overflow
            _totalSupplyPerToken[token] = _totalSupplyPerToken[token] - unstakeAmount;

            if (token == OOKI && IERC20(OOKI).balanceOf(address(this)) < unstakeAmount) {
                // settle vested BZRX only if needed
                IVestingToken(vBZRX).claim();
                CONVERTER.convert(address(this), IERC20(BZRX).balanceOf(address(this)));
            }

            // Withdraw from sushi masterchef
            if (token == OOKI_ETH_LP) {
                _withdrawFromSushiMasterchef(unstakeAmount);
                uint256 _pending = _pendingSushiRewards(msg.sender);
                userAltRewardsInfo[msg.sender][SUSHI].stakingStartBlock = block.number;
                userAltRewardsInfo[msg.sender][SUSHI].pending = _pending;
            }
            _balancesPerToken[token][msg.sender] = _balanceAfter;
            IERC20(token).safeTransfer(msg.sender, unstakeAmount);
            emit Unstake(msg.sender, token, currentDelegate, unstakeAmount);
        }

        _voteDelegator.moveDelegatesByVotingBalance(votingBalanceBefore, _votingFromStakedBalanceOf(msg.sender, _proposalState, true), msg.sender);
    }

    function claim(bool restake) external pausable updateRewards(msg.sender) returns (uint256 ookiRewardsEarned, uint256 stableCoinRewardsEarned) {
        return _claim(restake);
    }

    function claimAltRewards() external pausable returns (uint256 sushiRewardsEarned, uint256 crvRewardsEarned) {
        sushiRewardsEarned = _claimSushi();

        if (sushiRewardsEarned != 0) {
            emit ClaimAltRewards(msg.sender, SUSHI, sushiRewardsEarned);
        }
    }

    function claimBzrx() external pausable updateRewards(msg.sender) returns (uint256 ookiRewardsEarned) {
        ookiRewardsEarned = _claimBzrx(false);

        emit Claim(msg.sender, ookiRewardsEarned, 0);
    }

    function claim3Crv() external pausable updateRewards(msg.sender) returns (uint256 stableCoinRewardsEarned) {
        stableCoinRewardsEarned = _claim3Crv();

        emit Claim(msg.sender, 0, stableCoinRewardsEarned);
    }

    function claimSushi() external pausable returns (uint256 sushiRewardsEarned) {
        sushiRewardsEarned = _claimSushi();
        if (sushiRewardsEarned != 0) {
            emit ClaimAltRewards(msg.sender, SUSHI, sushiRewardsEarned);
        }
    }

    function _claim(bool restake) internal returns (uint256 ookiRewardsEarned, uint256 stableCoinRewardsEarned) {
        ookiRewardsEarned = _claimBzrx(restake);
        stableCoinRewardsEarned = _claim3Crv();

        emit Claim(msg.sender, ookiRewardsEarned, stableCoinRewardsEarned);
    }

    function _claimBzrx(bool restake) internal returns (uint256 ookiRewardsEarned) {
        ProposalState memory _proposalState = _getProposalState();
        uint256 votingBalanceBefore = _votingFromStakedBalanceOf(msg.sender, _proposalState, true);

        ookiRewardsEarned = ookiRewards[msg.sender];
        if (ookiRewardsEarned != 0) {
            ookiRewards[msg.sender] = 0;
            if (restake) {
                _restakeBZRX(msg.sender, ookiRewardsEarned);
            } else {
                if (IERC20(OOKI).balanceOf(address(this)) < ookiRewardsEarned) {
                    // settle vested BZRX only if needed
                    IVestingToken(vBZRX).claim();
                    CONVERTER.convert(address(this), IERC20(BZRX).balanceOf(address(this)));
                }

                IERC20(OOKI).transfer(msg.sender, ookiRewardsEarned);
            }
        }
        VoteDelegator(voteDelegator).moveDelegatesByVotingBalance(votingBalanceBefore, _votingFromStakedBalanceOf(msg.sender, _proposalState, true), msg.sender);
    }

    function _claim3Crv() internal returns (uint256 stableCoinRewardsEarned) {
        stableCoinRewardsEarned = stableCoinRewards[msg.sender];
        if (stableCoinRewardsEarned != 0) {
            uint256 curve3CrvBalance = curve3Crv.balanceOf(address(this));
            stableCoinRewards[msg.sender] = 0;
            curve3Crv.transfer(msg.sender, stableCoinRewardsEarned);
        }
    }

    function _claimSushi() internal returns (uint256) {
        address _user = msg.sender;
        uint256 pending = IMasterChefSushi2(SUSHI_MASTERCHEF).pendingSushi(OOKI_ETH_SUSHI_MASTERCHEF_PID, address(this));
        uint256 lptUserSupply = balanceOfByAsset(OOKI_ETH_LP, _user);
        uint256 pendingSushi = _pendingAltRewards(SUSHI, _user, lptUserSupply, userAltRewardsInfo[_user][SUSHI], pending);

        if (pendingSushi != 0) {
            if(IERC20(SUSHI).balanceOf(address(this)) < pendingSushi){
                IMasterChefSushi2(SUSHI_MASTERCHEF).harvest(OOKI_ETH_SUSHI_MASTERCHEF_PID, address(this));
                (altRewardsPerShare[SUSHI], altRewardsPerSharePerBlock[SUSHI], altRewardsBlock[SUSHI])  = _addAltRewards(SUSHI, pendingSushi);
                emit AddAltRewards(msg.sender, SUSHI, pendingSushi);
            }
            IERC20(SUSHI).safeTransfer(_user, pendingSushi);
            userAltRewardsInfo[_user][SUSHI].pending = 0;
            userAltRewardsInfo[_user][SUSHI].stakingStartBlock = block.number;
        }
        return pendingSushi;
    }

    function _restakeBZRX(address account, uint256 amount) internal {
        _balancesPerToken[OOKI][account] = _balancesPerToken[OOKI][account] + amount;

        _totalSupplyPerToken[OOKI] = _totalSupplyPerToken[OOKI] + amount;

        emit Stake(
            account,
            OOKI,
            account, //currentDelegate,
            amount
        );
    }

    modifier updateRewards(address account) {
        uint256 _ookiPerTokenStored = ookiPerTokenStored;
        uint256 _stableCoinPerTokenStored = stableCoinPerTokenStored;

        (uint256 ookiRewardsEarned, uint256 stableCoinRewardsEarned, uint256 ookiRewardsVesting, uint256 stableCoinRewardsVesting) = _earned(
            account,
            _ookiPerTokenStored,
            _stableCoinPerTokenStored
        );
        ookiRewardsPerTokenPaid[account] = _ookiPerTokenStored;
        stableCoinRewardsPerTokenPaid[account] = _stableCoinPerTokenStored;

        // vesting amounts get updated before sync
        bzrxVesting[account] = ookiRewardsVesting;
        stableCoinVesting[account] = stableCoinRewardsVesting;

        (ookiRewards[account], stableCoinRewards[account]) = _syncVesting(account, ookiRewardsEarned, stableCoinRewardsEarned, ookiRewardsVesting, stableCoinRewardsVesting);

        vestingLastSync[account] = block.timestamp;
        _;
    }

    function earned(address account)
        external
        view
        returns (
            uint256 ookiRewardsEarned,
            uint256 stableCoinRewardsEarned,
            uint256 ookiRewardsVesting,
            uint256 stableCoinRewardsVesting,
            uint256 sushiRewardsEarned
        )
    {
        (ookiRewardsEarned, stableCoinRewardsEarned, ookiRewardsVesting, stableCoinRewardsVesting) = _earned(account, ookiPerTokenStored, stableCoinPerTokenStored);

        (ookiRewardsEarned, stableCoinRewardsEarned) = _syncVesting(account, ookiRewardsEarned, stableCoinRewardsEarned, ookiRewardsVesting, stableCoinRewardsVesting);

        // discount vesting amounts for vesting time
        uint256 multiplier = vestedBalanceForAmount(1e36, 0, block.timestamp);
        ookiRewardsVesting = ookiRewardsVesting - (ookiRewardsVesting*multiplier/1e36);
        stableCoinRewardsVesting = stableCoinRewardsVesting-(stableCoinRewardsVesting*multiplier/1e36);
        sushiRewardsEarned = _pendingSushiRewards(account);
    }

    function _earned(
        address account,
        uint256 _ookiPerToken,
        uint256 _stableCoinPerToken
    )
        internal
        view
        returns (
            uint256 ookiRewardsEarned,
            uint256 stableCoinRewardsEarned,
            uint256 ookiRewardsVesting,
            uint256 stableCoinRewardsVesting
        )
    {
        uint256 ookiPerTokenUnpaid = _ookiPerToken-ookiRewardsPerTokenPaid[account];
        uint256 stableCoinPerTokenUnpaid = _stableCoinPerToken-stableCoinRewardsPerTokenPaid[account];

        ookiRewardsEarned = ookiRewards[account];
        stableCoinRewardsEarned = stableCoinRewards[account];
        ookiRewardsVesting = bzrxVesting[account];
        stableCoinRewardsVesting = stableCoinVesting[account];

        if (ookiPerTokenUnpaid != 0 || stableCoinPerTokenUnpaid != 0) {
            uint256 value;
            uint256 multiplier;
            uint256 lastSync;

            (uint256 vestedBalance, uint256 vestingBalance) = balanceOfStored(account);
            value = vestedBalance * ookiPerTokenUnpaid;
            value /= 1e36;
            ookiRewardsEarned = value + ookiRewardsEarned;
            value = vestedBalance * stableCoinPerTokenUnpaid;
            value /= 1e36;
            stableCoinRewardsEarned = value + stableCoinRewardsEarned;

            if (vestingBalance != 0 && ookiPerTokenUnpaid != 0) {
                // add new vesting amount for BZRX
                value = vestingBalance * ookiPerTokenUnpaid;
                value /= 1e36;
                ookiRewardsVesting = ookiRewardsVesting + value;
                // true up earned amount to vBZRX vesting schedule
                lastSync = vestingLastSync[account];
                multiplier = vestedBalanceForAmount(1e36, 0, lastSync);
                value *= multiplier;
                value /= 1e36;
                ookiRewardsEarned = ookiRewardsEarned + value;
            }
            if (vestingBalance != 0 && stableCoinPerTokenUnpaid != 0) {
                
                // add new vesting amount for 3crv
                value = vestingBalance * stableCoinPerTokenUnpaid;
                value /= 1e36;
                stableCoinRewardsVesting = stableCoinRewardsVesting + value;

                // true up earned amount to vBZRX vesting schedule
                if (lastSync == 0) {
                    lastSync = vestingLastSync[account];
                    multiplier = vestedBalanceForAmount(1e36, 0, lastSync);
                }
                value *= multiplier;
                value /= 1e36;
                stableCoinRewardsEarned = stableCoinRewardsEarned + value;
            }
        }
    }

    function _syncVesting(
        address account,
        uint256 ookiRewardsEarned,
        uint256 stableCoinRewardsEarned,
        uint256 ookiRewardsVesting,
        uint256 stableCoinRewardsVesting
    ) internal view returns (uint256, uint256) {
        uint256 lastVestingSync = vestingLastSync[account];

        if (lastVestingSync != block.timestamp) {
            uint256 rewardsVested;
            uint256 multiplier = vestedBalanceForAmount(1e36, lastVestingSync, block.timestamp);

            if (ookiRewardsVesting != 0) {
                rewardsVested = ookiRewardsVesting * multiplier / 1e36;
                ookiRewardsEarned += rewardsVested;
            }

            if (stableCoinRewardsVesting != 0) {
                rewardsVested = stableCoinRewardsVesting * multiplier / 1e36;
                stableCoinRewardsEarned += rewardsVested;
            }

            // OOKI is 10x BZRX
            uint256 vBZRXBalance = _balancesPerToken[vBZRX][account];
            if (vBZRXBalance != 0) {
                // add vested OOKI to rewards balance
                rewardsVested = vBZRXBalance * multiplier / 1e35;  // OOKI is 10x BZRX
                ookiRewardsEarned += rewardsVested;
            }
        }

        return (ookiRewardsEarned, stableCoinRewardsEarned);
    }

    function addAltRewards(address token, uint256 amount) public {
        if (amount != 0) {
            (altRewardsPerShare[token], altRewardsPerSharePerBlock[token], altRewardsBlock[token])  = _addAltRewards(token, amount);
            IERC20(token).transferFrom(msg.sender, address(this), amount);
            emit AddAltRewards(msg.sender, token, amount);
        }
    }

    function _addAltRewards(address token, uint256 amount) internal view
        returns (uint256 _altRewardsPerShare, uint256 _altRewardsPerSharePerBlock, uint256 _altRewardsBlock){
        address poolAddress = token == SUSHI ? OOKI_ETH_LP : token;
        uint256 totalSupply = _totalSupplyPerToken[poolAddress];
        require(totalSupply != 0, "no deposits");
        _altRewardsPerShare = altRewardsPerShare[token] + (amount*1e12/totalSupply);
        _altRewardsPerSharePerBlock = _altRewardsPerShare / (block.number - altRewardsStartBlock[token]);
        _altRewardsBlock = block.number;

    }

    function balanceOfByAsset(address token, address account) public view returns (uint256 balance) {
        balance = _balancesPerToken[token][account];
    }

    function balanceOfByAssets(address account)
        external
        view
        returns (
            uint256 ookiBalance,
            uint256 iBZRXBalance,
            uint256 vBZRXBalance,
            uint256 LPTokenBalance
        )
    {
        return (balanceOfByAsset(OOKI, account), balanceOfByAsset(iOOKI, account), balanceOfByAsset(vBZRX, account), balanceOfByAsset(OOKI_ETH_LP, account));
    }

    function balanceOfStored(address account) public view returns (uint256 vestedBalance, uint256 vestingBalance) {
        uint256 balance = _balancesPerToken[vBZRX][account];
        if (balance != 0) {
            vestingBalance = balance * vBZRXWeightStored / 1e17; // OOKI is 10x BZRX
        }

        vestedBalance = _balancesPerToken[OOKI][account];

        balance = _balancesPerToken[iOOKI][account];
        if (balance != 0) {
            vestedBalance = balance * iOOKIWeightStored / 1e50 + vestedBalance;
        }

        balance = _balancesPerToken[OOKI_ETH_LP][account];
        if (balance != 0) {
            vestedBalance = balance * LPTokenWeightStored / 1e18 + vestedBalance;
        }
    }


    function exit()
        public
        // unstake() does check pausable
    {
        address[] memory tokens = new address[](4);
        uint256[] memory values = new uint256[](4);
        tokens[0] = iOOKI;
        tokens[1] = OOKI_ETH_LP;
        tokens[2] = vBZRX;
        tokens[3] = OOKI;
        values[0] = type(uint256).max;
        values[1] = type(uint256).max;
        values[2] = type(uint256).max;
        values[3] = type(uint256).max;
        
        unstake(tokens, values); // calls updateRewards
        _claim(false);
    }

    
}
