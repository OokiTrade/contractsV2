/**
 * Copyright 2017-2021, bZeroX, LLC <https://bzx.network/>. All Rights Reserved.
 * Licensed under the Apache License, Version 2.0.
 */

pragma solidity 0.5.17;
pragma experimental ABIEncoderV2;

import "./StakingInterimState.sol";
import "../../interfaces/ILoanPool.sol";


contract StakingInterim is StakingInterimState {

    ILoanPool public constant iBZRX = ILoanPool(0x18240BD9C07fA6156Ce3F3f61921cC82b2619157);

    struct RepStakedTokens {
        address wallet;
        bool isActive;
        uint256 BZRX;
        uint256 vBZRX;
        uint256 LPToken;
    }

    event Staked(
        address indexed user,
        address indexed token,
        address indexed delegate,
        uint256 amount
    );

    event DelegateChanged(
        address indexed user,
        address indexed oldDelegate,
        address indexed newDelegate
    );

    event RewardAdded(
        uint256 indexed reward,
        uint256 duration
    );

    modifier checkActive() {
        require(isActive, "not active");
        _;
    }
 
    function init(
        address _BZRX,
        address _vBZRX,
        address _LPToken,
        bool _isActive)
        external
        onlyOwner
    {
        require(!isInit, "already init");
        
        BZRX = _BZRX;
        vBZRX = _vBZRX;
        LPToken = _LPToken;

        isActive = _isActive;

        isInit = true;
    }

    function setActive(
        bool _isActive)
        public
        onlyOwner
    {
        require(isInit, "not init");
        isActive = _isActive;
    }

    function rescueToken(
        IERC20 token,
        address receiver,
        uint256 amount)
        external
        onlyOwner
        returns (uint256 withdrawAmount)
    {
        withdrawAmount = token.balanceOf(address(this));
        if (withdrawAmount > amount) {
            withdrawAmount = amount;
        }
        if (withdrawAmount != 0) {
            token.safeTransfer(
                receiver,
                withdrawAmount
            );
        }
    }

    function stake(
        address[] memory tokens,
        uint256[] memory values)
        public
    {
        stakeWithDelegate(
            tokens,
            values,
            ZERO_ADDRESS
        );
    }

    function stakeWithDelegate(
        address[] memory tokens,
        uint256[] memory values,
        address delegateToSet)
        public
        checkActive
        updateReward(msg.sender)
    {
        require(tokens.length == values.length, "count mismatch");

        address currentDelegate = _setDelegate(delegateToSet);

        address token;
        uint256 stakeAmount;
        uint256 stakeable;
        for (uint256 i = 0; i < tokens.length; i++) {
            token = tokens[i];
            require(token == BZRX || token == vBZRX || token == LPToken, "invalid token");

            stakeAmount = values[i];
            stakeable = stakeableByAsset(token, msg.sender);

            if (stakeAmount == 0 || stakeable == 0) {
                continue;
            }
            if (stakeAmount > stakeable) {
                stakeAmount = stakeable;
            }

            _balancesPerToken[token][msg.sender] = _balancesPerToken[token][msg.sender].add(stakeAmount);
            _totalSupplyPerToken[token] = _totalSupplyPerToken[token].add(stakeAmount);

            emit Staked(
                msg.sender,
                token,
                currentDelegate,
                stakeAmount
            );

            repStakedPerToken[currentDelegate][token] = repStakedPerToken[currentDelegate][token]
                .add(stakeAmount);
        }
    }

    function setRepActive(
        bool _isActive)
        public
    {
        reps[msg.sender] = _isActive;
        if (_isActive) {
            repStakedSet.addAddress(msg.sender);
        }
    }

    function getRepVotes(
        uint256 start,
        uint256 count)
        external
        view
        returns (RepStakedTokens[] memory repStakedArr)
    {
        uint256 end = start.add(count).min256(repStakedSet.length());
        if (start >= end) {
            return repStakedArr;
        }
        count = end-start;

        uint256 idx = count;
        address wallet;
        repStakedArr = new RepStakedTokens[](idx);
        for (uint256 i = --end; i >= start; i--) {
            wallet = repStakedSet.getAddress(i);
            repStakedArr[count-(idx--)] = RepStakedTokens({
                wallet: wallet,
                isActive: reps[wallet],
                BZRX: repStakedPerToken[wallet][BZRX],
                vBZRX: repStakedPerToken[wallet][vBZRX],
                LPToken: repStakedPerToken[wallet][LPToken]
            });

            if (i == 0) {
                break;
            }
        }

        if (idx != 0) {
            count -= idx;
            assembly {
                mstore(repStakedArr, count)
            }
        }
    }

    function lastTimeRewardApplicable()
        public
        view
        returns (uint256)
    {
        return periodFinish
            .min256(_getTimestamp());
    }

    modifier updateReward(address account) {
        uint256 _rewardsPerToken = rewardsPerToken();
        rewardPerTokenStored = _rewardsPerToken;

        lastUpdateTime = lastTimeRewardApplicable();

        if (account != address(0)) {
            rewards[account] = _earned(account, _rewardsPerToken);
            userRewardPerTokenPaid[account] = _rewardsPerToken;
        }

        _;
    }

    function rewardsPerToken()
        public
        view
        returns (uint256)
    {
        uint256 totalSupplyBZRX = totalSupplyByAssetNormed(BZRX);
        uint256 totalSupplyVBZRX = totalSupplyByAssetNormed(vBZRX);
        uint256 totalSupplyLPToken = totalSupplyByAssetNormed(LPToken);

        uint256 totalTokens = totalSupplyBZRX
            .add(totalSupplyVBZRX)
            .add(totalSupplyLPToken);

        if (totalTokens == 0) {
            return rewardPerTokenStored;
        }

        return rewardPerTokenStored.add(
            lastTimeRewardApplicable()
                .sub(lastUpdateTime)
                .mul(rewardRate)
                .mul(1e18)
                .div(totalTokens)
        );
    }

    function earned(
        address account)
        public
        view
        returns (uint256)
    {
        return _earned(
            account,
            rewardsPerToken()
        );
    }

    function _earned(
        address account,
        uint256 _rewardsPerToken)
        internal
        view
        returns (uint256)
    {
        uint256 bzrxBalance = balanceOfByAssetNormed(BZRX, account);
        uint256 vbzrxBalance = balanceOfByAssetNormed(vBZRX, account);
        uint256 lptokenBalance = balanceOfByAssetNormed(LPToken, account);

        uint256 totalTokens = bzrxBalance
            .add(vbzrxBalance)
            .add(lptokenBalance);

        return totalTokens
            .mul(_rewardsPerToken.sub(userRewardPerTokenPaid[account]))
            .div(1e18)
            .add(rewards[account]);
    }

    function notifyRewardAmount(
        uint256 reward,
        uint256 duration)
        external
        onlyOwner
        updateReward(address(0))
    {
        require(isInit, "not init");

        if (periodFinish != 0) {
            if (_getTimestamp() >= periodFinish) {
                rewardRate = reward
                    .div(duration);
            } else {
                uint256 remaining = periodFinish
                    .sub(_getTimestamp());
                uint256 leftover = remaining
                    .mul(rewardRate);
                rewardRate = reward
                    .add(leftover)
                    .div(duration);
            }

            lastUpdateTime = _getTimestamp();
            periodFinish = _getTimestamp()
                .add(duration);
        } else {
            rewardRate = reward
                .div(duration);
            lastUpdateTime = _getTimestamp();
            periodFinish = _getTimestamp()
                .add(duration);
        }

        emit RewardAdded(
            reward,
            duration
        );
    }

    function stakeableByAsset(
        address token,
        address account)
        public
        view
        returns (uint256)
    {
        uint256 walletBalance = IERC20(token).balanceOf(account);

        // excludes staking by way of iBZRX
        uint256 stakedBalance = _balancesPerToken[token][account];

        return walletBalance > stakedBalance ?
            walletBalance - stakedBalance :
            0;
    }

    function balanceOfByAssetWalletAware(
        address token,
        address account)
        public
        view
        returns (uint256 balance)
    {
        uint256 walletBalance = IERC20(token).balanceOf(account);

        balance = _balancesPerToken[token][account]
            .min256(walletBalance);

        if (token == BZRX) {
            balance = balance
                .add(iBZRX.assetBalanceOf(account));
        }
    }

    function balanceOfByAsset(
        address token,
        address account)
        public
        view
        returns (uint256 balance)
    {
        balance = _balancesPerToken[token][account];
        if (token == BZRX) {
            balance = balance
                .add(iBZRX.assetBalanceOf(account));
        }
    }

    function balanceOfByAssetNormed(
        address token,
        address account)
        public
        view
        returns (uint256)
    {
        if (token == LPToken) {
            // normalizes the LPToken balance
            uint256 lptokenBalance = totalSupplyByAsset(LPToken);
            if (lptokenBalance != 0) {
                return totalSupplyByAssetNormed(LPToken)
                    .mul(balanceOfByAsset(LPToken, account))
                    .div(lptokenBalance);
            }
        } else {
            return balanceOfByAsset(token, account);
        }
    }

    function totalSupply()
        public
        view
        returns (uint256)
    {
        return totalSupplyByAsset(BZRX)
            .add(totalSupplyByAsset(vBZRX))
            .add(totalSupplyByAsset(LPToken));
    }

    function totalSupplyNormed()
        public
        view
        returns (uint256)
    {
        return totalSupplyByAssetNormed(BZRX)
            .add(totalSupplyByAssetNormed(vBZRX))
            .add(totalSupplyByAssetNormed(LPToken));
    }

    function totalSupplyByAsset(
        address token)
        public
        view
        returns (uint256 supply)
    {
        supply = _totalSupplyPerToken[token];
        if (token == BZRX) {
            supply = supply
                .add(iBZRX.totalAssetSupply());
        }
    }

    function totalSupplyByAssetNormed(
        address token)
        public
        view
        returns (uint256)
    {
        if (token == LPToken) {
            uint256 circulatingSupply = initialCirculatingSupply; // + VBZRX.totalVested();
            
            // staked LP tokens are assumed to represent the total unstaked supply (circulated supply - staked BZRX)
            return totalSupplyByAsset(LPToken) != 0 ?
                circulatingSupply - totalSupplyByAsset(BZRX) :
                0;
        } else {
            return totalSupplyByAsset(token);
        }
    }

    function _setDelegate(
        address delegateToSet)
        internal
        returns (address currentDelegate)
    {
        currentDelegate = delegate[msg.sender];
        if (currentDelegate != ZERO_ADDRESS) {
            require(delegateToSet == ZERO_ADDRESS || delegateToSet == currentDelegate, "delegate already set");
        } else {
            if (delegateToSet == ZERO_ADDRESS) {
                delegateToSet = msg.sender;
            }
            delegate[msg.sender] = delegateToSet;

            emit DelegateChanged(
                msg.sender,
                currentDelegate,
                delegateToSet
            );

            currentDelegate = delegateToSet;
        }
    }

    function _getTimestamp()
        internal
        view
        returns (uint256)
    {
        return block.timestamp;
    }
}
