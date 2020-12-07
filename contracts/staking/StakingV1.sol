/**
 * Copyright 2017-2020, bZeroX, LLC <https://bzx.network/>. All Rights Reserved.
 * Licensed under the Apache License, Version 2.0.
 */

pragma solidity 0.5.17;
pragma experimental ABIEncoderV2;

import "./StakingState.sol";
import "./StakingConstants.sol";
import "../interfaces/IVestingToken.sol";
import "../interfaces/ILoanPool.sol";
import "../feeds/IPriceFeeds.sol";


contract StakingV1 is StakingState, StakingConstants {

    modifier onlyEOA() {
        require(msg.sender == tx.origin, "unauthorized");
        _;
    }

    modifier checkPause() {
        require(!isPaused, "paused");
        _;
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
        checkPause
        updateRewards(msg.sender)
    {
        require(tokens.length == values.length, "count mismatch");

        address currentDelegate = _changeDelegate(delegateToSet);

        address token;
        uint256 stakeAmount;
        uint256 tokenBalance;
        for (uint256 i = 0; i < tokens.length; i++) {
            token = tokens[i];
            require(token == BZRX || token == vBZRX || token == iBZRX || token == LPToken, "invalid token");

            stakeAmount = values[i];
            if (stakeAmount == 0) {
                continue;
            }

            tokenBalance = _balancesPerToken[token][msg.sender];

            _balancesPerToken[token][msg.sender] = tokenBalance.add(stakeAmount);
            _totalSupplyPerToken[token] = _totalSupplyPerToken[token].add(stakeAmount);

            repStakedPerToken[currentDelegate][token] = repStakedPerToken[currentDelegate][token]
                .add(stakeAmount);

            IERC20(token).safeTransferFrom(msg.sender, address(this), stakeAmount);

            // the below comes after the transfer of vBZRX, which settles vested BZRX locally for previously held amount
            if (token == vBZRX) {
                if (tokenBalance != 0) {
                    uint256 vested = _vestedBalance(
                        tokenBalance,
                        _vBZRXLastUpdate[msg.sender]
                    );

                    if (vested != 0) {
                        // auto-stake vested BZRX
                        _balancesPerToken[BZRX][msg.sender] = _balancesPerToken[BZRX][msg.sender].add(vested);
                        _totalSupplyPerToken[BZRX] = _totalSupplyPerToken[BZRX].add(vested);

                        repStakedPerToken[currentDelegate][BZRX] = repStakedPerToken[currentDelegate][BZRX]
                            .add(vested);

                        emit Staked(
                            msg.sender,
                            BZRX,
                            currentDelegate,
                            vested
                        );
                    }
                }

                _vBZRXLastUpdate[msg.sender] = block.timestamp;
            }

            emit Staked(
                msg.sender,
                token,
                currentDelegate,
                stakeAmount
            );
        }
    }

    function vestedBalance(
        address account)
        external
        view
        returns (uint256 vested)
    {
        uint256 balance = _balancesPerToken[vBZRX][account];
        if (balance != 0) {
            vested = _vestedBalance(
                _balancesPerToken[vBZRX][account],
                _vBZRXLastUpdate[account]
            );
        }
    }

    function _vestedBalance(
        uint256 tokenBalance,
        uint256 lastUpdateTime)
        internal
        view
        returns (uint256 vested)
    {
        uint256 timestamp = block.timestamp;
        if (lastUpdateTime < timestamp) {
            if (timestamp <= vestingCliffTimestamp ||
                lastUpdateTime >= vestingEndTimestamp) {
                // time cannot be before vesting starts
                // OR all vested token has already been claimed
                return 0;
            }
            if (lastUpdateTime < vestingCliffTimestamp) {
                // vesting starts at the cliff timestamp
                lastUpdateTime = vestingCliffTimestamp;
            }
            if (timestamp > vestingEndTimestamp) {
                // vesting ends at the end timestamp
                timestamp = vestingEndTimestamp;
            }

            uint256 timeSinceClaim = timestamp.sub(lastUpdateTime);
            vested = tokenBalance.mul(timeSinceClaim) / vestingDurationAfterCliff; // will never divide by 0
        }
    }

    function unStake(
        address[] memory tokens,
        uint256[] memory values)
        public
        updateRewards(msg.sender)
    {
        require(tokens.length == values.length, "count mismatch");

        address currentDelegate = delegate[msg.sender];

        address token;
        uint256 unstakeAmount;
        uint256 stakedAmount;
        for (uint256 i = 0; i < tokens.length; i++) {
            token = tokens[i];
            require(token == BZRX || token == vBZRX || token == iBZRX || token == LPToken, "invalid token");

            unstakeAmount = values[i];
            stakedAmount = _balancesPerToken[token][msg.sender];
            if (unstakeAmount == 0 || stakedAmount == 0) {
                continue;
            }
            if (unstakeAmount > stakedAmount) {
                unstakeAmount = stakedAmount;
            }

            _balancesPerToken[token][msg.sender] = stakedAmount - unstakeAmount; // will not overflow
            _totalSupplyPerToken[token] = _totalSupplyPerToken[token] - unstakeAmount; // will not overflow

            repStakedPerToken[currentDelegate][token] = repStakedPerToken[currentDelegate][token]
                .sub(unstakeAmount);

            IERC20(token).safeTransfer(msg.sender, unstakeAmount);

           // the below comes after the transfer of vBZRX, which settles vested BZRX locally for previously held amount
            if (token == vBZRX && unstakeAmount != 0) {
                uint256 vested = _vestedBalance(
                    unstakeAmount,
                    _vBZRXLastUpdate[msg.sender]
                );

                _vBZRXLastUpdate[msg.sender] = block.timestamp;

                if (vested != 0) {
                    // withdraw vested amount
                    IERC20(BZRX).transfer(msg.sender, vested);
                }
            }

            emit Unstaked(
                msg.sender,
                token,
                currentDelegate,
                unstakeAmount
            );
        }
    }

    function changeDelegate(
        address delegateToSet)
        external
    {
        _changeDelegate(delegateToSet);
    }

    function claim()
        public
        returns (uint256 bzrxRewardsEarned, uint256 stableCoinRewardsEarned)
    {
        return _claim(false);
    }

    function claimAndRestake()
        public
        returns (uint256 bzrxRewardsEarned, uint256 stableCoinRewardsEarned)
    {
        return _claim(true);
    }

    function claimWithUpdate()
        external
        returns (uint256 bzrxRewardsEarned, uint256 stableCoinRewardsEarned)
    {
        sweepFees();
        return _claim(false);
    }

    function claimAndRestakeWithUpdate()
        external
        returns (uint256 bzrxRewardsEarned, uint256 stableCoinRewardsEarned)
    {
        sweepFees();
        return _claim(true);
    }

    function _claim(
        bool restake)
        internal
        updateRewards(msg.sender)
        returns (uint256 bzrxRewardsEarned, uint256 stableCoinRewardsEarned)
    {
        (bzrxRewardsEarned, stableCoinRewardsEarned) = earned(msg.sender);
        if (bzrxRewardsEarned != 0) {
            bzrxRewards[msg.sender] = 0;
            if (restake) {
                address currentDelegate = delegate[msg.sender];
                _balancesPerToken[BZRX][msg.sender] = _balancesPerToken[BZRX][msg.sender].add(bzrxRewardsEarned);
                _totalSupplyPerToken[BZRX] = _totalSupplyPerToken[BZRX].add(bzrxRewardsEarned);

                repStakedPerToken[currentDelegate][BZRX] = repStakedPerToken[currentDelegate][BZRX]
                    .add(bzrxRewardsEarned);

                emit Staked(
                    msg.sender,
                    BZRX,
                    currentDelegate,
                    bzrxRewardsEarned
                );
            } else {
                IERC20(BZRX).transfer(msg.sender, bzrxRewardsEarned);
            }
        }
        if (stableCoinRewardsEarned != 0) {
            stableCoinRewards[msg.sender] = 0;
            curve3Crv.transfer(msg.sender, stableCoinRewardsEarned);
        }

        emit RewardPaid(
            msg.sender,
            bzrxRewardsEarned,
            stableCoinRewardsEarned
        );
    }

    function exit()
        public
    {
        address[] memory tokens = new address[](4);
        uint256[] memory values = new uint256[](4);
        tokens[0] = BZRX;
        tokens[1] = vBZRX;
        tokens[2] = iBZRX;
        tokens[3] = LPToken;
        values[0] = uint256(-1);
        values[1] = uint256(-1);
        values[2] = uint256(-1);
        values[3] = uint256(-1);
        
        unStake(tokens, values);
        claim();
    }

    function exitWithUpdate()
        external
    {
        sweepFees();
        exit();
    }

    function setRepActive(
        bool _isActive)
        public
    {
        reps[msg.sender] = _isActive;
        if (_isActive) {
            _repStakedSet.addAddress(msg.sender);
        }
    }

    function getRepVotes(
        uint256 start,
        uint256 count)
        external
        view
        returns (RepStakedTokens[] memory repStakedArr)
    {
        uint256 end = start.add(count).min256(_repStakedSet.length());
        if (start >= end) {
            return repStakedArr;
        }
        count = end-start;

        uint256 idx = count;
        address user;
        repStakedArr = new RepStakedTokens[](idx);
        for (uint256 i = --end; i >= start; i--) {
            user = _repStakedSet.getAddress(i);
            repStakedArr[count-(idx--)] = RepStakedTokens({
                user: user,
                isActive: reps[user],
                BZRX: repStakedPerToken[user][BZRX],
                vBZRX: repStakedPerToken[user][vBZRX],
                iBZRX: repStakedPerToken[user][iBZRX],
                LPToken: repStakedPerToken[user][LPToken]
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

    modifier updateRewards(address account) {
        (uint256 _bzrxPerToken, uint256 _stableCoinPerToken) = rewardsPerToken();
        bzrxPerTokenStored = _bzrxPerToken;
        stableCoinPerTokenStored = _stableCoinPerToken;

        lastUpdateTime = block.timestamp;

        if (account != address(0)) {
            (bzrxRewards[account], stableCoinRewards[account]) = _earned(account, _bzrxPerToken, _stableCoinPerToken);
            bzrxRewardsPerTokenPaid[account] = _bzrxPerToken;
            stableCoinRewardsPerTokenPaid[account] = _stableCoinPerToken;
        }

        _;
    }

    function rewardsPerToken()
        public
        view
        returns (uint256, uint256)
    {
        uint256 totalTokens = totalSupply();
        if (totalTokens == 0) {
            return (bzrxPerTokenStored, stableCoinPerTokenStored);
        }

        uint256 timestamp = block.timestamp;
        uint256 _lastRewardsUpdateTime = lastRewardsUpdateTime;

        uint256 totalDuration = timestamp
            .sub(_lastRewardsUpdateTime);
        if (totalDuration == 0 || _lastRewardsUpdateTime == 0) {
            return (bzrxPerTokenStored, stableCoinPerTokenStored);
        }

        uint256 applicableDuration = timestamp
            .sub(lastUpdateTime);

        return (
            bzrxPerTokenStored.add(
                bzrxRewardSet
                    .mul(applicableDuration)
                    .mul(1e18)
                    .div(totalDuration)
                    .div(totalTokens)),
            stableCoinPerTokenStored.add(
                stableCoinRewardSet
                    .mul(applicableDuration)
                    .mul(1e18)
                    .div(totalDuration)
                    .div(totalTokens))
        );
    }

    function earned(
        address account)
        public
        view
        returns (uint256, uint256) // bzrxRewardsEarned, stableCoinRewardsEarned
    {
        (uint256 _bzrxPerToken, uint256 _stableCoinPerToken) = rewardsPerToken();
        return _earned(
            account,
            _bzrxPerToken,
            _stableCoinPerToken
        );
    }

    function earnedWithUpdate(
        address account)
        external
        returns (uint256, uint256) // bzrxRewardsEarned, stableCoinRewardsEarned
    {
        sweepFees();
        return earned(account);
    }

    function _earned(
        address account,
        uint256 _bzrxPerToken,
        uint256 _stableCoinPerToken)
        internal
        view
        returns (uint256, uint256) // bzrxRewardsEarned, stableCoinRewardsEarned
    {
        uint256 totalTokens = balanceOf(account);
        return (
            totalTokens
                .mul(_bzrxPerToken.sub(bzrxRewardsPerTokenPaid[account]))
                .div(1e18)
                .add(bzrxRewards[account]),
            totalTokens
                .mul(_stableCoinPerToken.sub(stableCoinRewardsPerTokenPaid[account]))
                .div(1e18)
                .add(stableCoinRewards[account])
        );
    }

    // note: anyone can contribute rewards to the contract
    function addRewards(
        uint256 newBZRX,
        uint256 newStableCoin)
        external
    {
        if (newBZRX != 0 || newStableCoin != 0) {
            _addRewards(newBZRX, newStableCoin);
            if (newBZRX != 0) {
                IERC20(BZRX).transferFrom(msg.sender, address(this), newBZRX);
            }
            if (newStableCoin != 0) {
                curve3Crv.transferFrom(msg.sender, address(this), newStableCoin);
            }
        }
    }

    function _addRewards(
        uint256 newBZRX,
        uint256 newStableCoin)
        internal
        updateRewards(address(0))
    {
        bzrxRewardSet = newBZRX;
        stableCoinRewardSet = newStableCoin;
        lastRewardsUpdateTime = block.timestamp;

        emit RewardAdded(
            msg.sender,
            newBZRX,
            newStableCoin
        );
    }

    function balanceOf(
        address account)
        public
        view
        returns (uint256)
    {
        return balanceOfByAssetNormed(BZRX, account)
            .add(balanceOfByAssetNormed(vBZRX, account))
            .add(balanceOfByAssetNormed(iBZRX, account))
            .add(balanceOfByAssetNormed(LPToken, account));
    }

    function balanceOfByAsset(
        address token,
        address account)
        public
        view
        returns (uint256)
    {
        return _balancesPerToken[token][account];
    }

    function balanceOfByAssetNormed(
        address token,
        address account)
        public
        view
        returns (uint256 balance)
    {
        if (token == LPToken) {
            balance = totalSupplyByAsset(LPToken);
            if (balance != 0) {
                balance = totalSupplyByAssetNormed(LPToken)
                    .mul(balanceOfByAsset(LPToken, account))
                    .div(balance);
            }
        } else if (token == vBZRX) {
            balance = balanceOfByAsset(vBZRX, account);
            if (balance != 0) {
                balance = balance
                    .mul(startingVBZRXBalance_ - _vestedBalance(startingVBZRXBalance_, 0)) // overflow not possible
                    .div(startingVBZRXBalance_);
            }
        } else if (token == iBZRX) {
            balance = balanceOfByAsset(iBZRX, account);
            if (balance != 0) {
                balance = balance
                    .mul(ILoanPool(iBZRX).tokenPrice())
                    .div(10**18);
            }
        } else if (token == BZRX) {
            balance = balanceOfByAsset(token, account) + _vestedBalance(balanceOfByAsset(vBZRX, account), _vBZRXLastUpdate[account]);
        }
    }

    function totalSupply()
        public
        view
        returns (uint256)
    {
        return totalSupplyByAssetNormed(BZRX)
            .add(totalSupplyByAssetNormed(vBZRX))
            .add(totalSupplyByAssetNormed(iBZRX))
            .add(totalSupplyByAssetNormed(LPToken));
    }

    function totalSupplyByAsset(
        address token)
        public
        view
        returns (uint256)
    {
        return _totalSupplyPerToken[token];
    }

    function totalSupplyByAssetNormed(
        address token)
        public
        view
        returns (uint256 supply)
    {
        if (token == LPToken) {
            uint256 circulatingSupply = initialCirculatingSupply + _vestedBalance(startingVBZRXBalance_, 0);
            
            // staked LP tokens are assumed to represent the total unstaked supply (circulated supply - staked BZRX - staked iBZRX)
            supply = totalSupplyByAsset(LPToken) != 0 ?
                circulatingSupply - totalSupplyByAsset(BZRX) - totalSupplyByAsset(iBZRX) :
                0;
        } else if (token == vBZRX) {
            supply = totalSupplyByAsset(vBZRX);
            if (supply != 0) {
                supply = initialCirculatingSupply
                    .mul(startingVBZRXBalance_ - _vestedBalance(startingVBZRXBalance_, 0)) // overflow not possible
                    .div(startingVBZRXBalance_);
            }
        } else if (token == iBZRX) {
            supply = totalSupplyByAsset(iBZRX);
            if (supply != 0) {
                supply = supply
                    .mul(ILoanPool(iBZRX).tokenPrice())
                    .div(10**18);
            }
        } else if (token == BZRX) {
            return totalSupplyByAsset(BZRX) + IVestingToken(vBZRX).vestedBalanceOf(address(this));
        }
    }

    function _changeDelegate(
        address delegateToSet)
        internal
        returns (address currentDelegate)
    {
        currentDelegate = delegate[msg.sender];
        if (delegateToSet == ZERO_ADDRESS) {
            require(currentDelegate != ZERO_ADDRESS, "invalid delegate");
            delegateToSet = currentDelegate;
        }

        if (delegateToSet != currentDelegate) {
            if (currentDelegate != ZERO_ADDRESS) {
                uint256 balance = _balancesPerToken[BZRX][msg.sender];
                if (balance != 0) {
                    repStakedPerToken[currentDelegate][BZRX] = repStakedPerToken[currentDelegate][BZRX]
                        .sub(balance);
                    repStakedPerToken[delegateToSet][BZRX] = repStakedPerToken[delegateToSet][BZRX]
                        .add(balance);
                }

                balance = _balancesPerToken[vBZRX][msg.sender];
                if (balance != 0) {
                    repStakedPerToken[currentDelegate][vBZRX] = repStakedPerToken[currentDelegate][vBZRX]
                        .sub(balance);
                    repStakedPerToken[delegateToSet][vBZRX] = repStakedPerToken[delegateToSet][vBZRX]
                        .add(balance);
                }

                balance = _balancesPerToken[iBZRX][msg.sender];
                if (balance != 0) {
                    repStakedPerToken[currentDelegate][iBZRX] = repStakedPerToken[currentDelegate][iBZRX]
                        .sub(balance);
                    repStakedPerToken[delegateToSet][iBZRX] = repStakedPerToken[delegateToSet][iBZRX]
                        .add(balance);
                }

                balance = _balancesPerToken[LPToken][msg.sender];
                if (balance != 0) {
                    repStakedPerToken[currentDelegate][LPToken] = repStakedPerToken[currentDelegate][LPToken]
                        .sub(balance);
                    repStakedPerToken[delegateToSet][LPToken] = repStakedPerToken[delegateToSet][LPToken]
                        .add(balance);
                }
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

    // Fee Conversion Logic //

    function sweepFees()
        public
        returns (uint256 bzrxRewards, uint256 crv3Rewards)
    {
        sweepFeesByAsset(currentFeeTokens);
    }

    function sweepFeesByAsset(
        address[] memory assets)
        public
        onlyEOA
        returns (uint256 bzrxRewards, uint256 crv3Rewards)
    {
        uint256[] memory amounts = _withdrawFees(assets);
        _convertFees(assets, amounts);
        (bzrxRewards, crv3Rewards) = _distributeFees();
    }

    function _withdrawFees(
        address[] memory assets)
        internal
        returns (uint256[] memory)
    {
        uint256 rewardAmount;
        address _fundsWallet = fundsWallet;
        uint256[] memory amounts = bZx.withdrawFees(assets, address(this), IBZxPartial.FeeClaimType.All);
        for (uint256 i = 0; i < assets.length; i++) {
            if (amounts[i] == 0) {
                continue;
            }

            rewardAmount = amounts[i]
                .mul(rewardPercent)
                .div(1e20);

            stakingRewards[assets[i]] = stakingRewards[assets[i]]
                .add(rewardAmount);

            IERC20(assets[i]).safeTransfer(
                _fundsWallet,
                amounts[i] - rewardAmount
            );
        }

        emit WithdrawFees(
            msg.sender
        );

        return amounts;
    }

    function _convertFees(
        address[] memory assets,
        uint256[] memory amounts)
        internal
        returns (uint256 bzrxOutput, uint256 crv3Output)
    {
        require(assets.length == amounts.length, "count mismatch");
 
        IPriceFeeds priceFeeds = IPriceFeeds(bZx.priceFeeds());
        (uint256 bzrxRate,) = priceFeeds.queryRate(
            BZRX,
            WETH
        );
        uint256 maxDisagreement = maxAllowedDisagreement;

        address asset;
        uint256 daiAmount;
        uint256 usdcAmount;
        uint256 usdtAmount;
        for (uint256 i = 0; i < assets.length; i++) {
            asset = assets[i];
            if (asset == BZRX) {
                continue;
            } else if (asset == DAI) {
                daiAmount = amounts[i];
                continue;
            } else if (asset == USDC) {
                usdcAmount = amounts[i];
                continue;
            } else if (asset == USDT) {
                usdtAmount = amounts[i];
                continue;
            }

            if (amounts[i] != 0) {
                bzrxOutput += _convertFeeWithUniswap(asset, amounts[i], priceFeeds, bzrxRate, maxDisagreement);
            }
        }
        if (bzrxOutput != 0) {
            stakingRewards[BZRX] += bzrxOutput;
        }

        if (daiAmount != 0 || usdcAmount != 0 || usdtAmount != 0) {
            crv3Output = _convertFeesWithCurve(
                daiAmount,
                usdcAmount,
                usdtAmount
            );
            stakingRewards[address(curve3Crv)] += crv3Output;
        }

        emit ConvertFees(
            msg.sender,
            bzrxOutput,
            crv3Output
        );
    }

    function _distributeFees()
        internal
        returns (uint256 bzrxRewards, uint256 crv3Rewards)
    {
        bzrxRewards = stakingRewards[BZRX];
        crv3Rewards = stakingRewards[address(curve3Crv)];
        if (bzrxRewards != 0 || crv3Rewards != 0) {
            uint256 callerReward;
            if (bzrxRewards != 0) {
                stakingRewards[BZRX] = 0;

                callerReward = bzrxRewards / 100;
                bzrxRewards = bzrxRewards
                    .sub(callerReward);

                IERC20(BZRX).transfer(msg.sender, callerReward);
            }
            if (crv3Rewards != 0) {
                stakingRewards[address(curve3Crv)] = 0;

                callerReward = crv3Rewards / 100;
                crv3Rewards = crv3Rewards
                    .sub(callerReward);

                curve3Crv.transfer(msg.sender, callerReward);
            }

            _addRewards(bzrxRewards, crv3Rewards);
        }

        emit DistributeFees(
            msg.sender,
            bzrxRewards,
            crv3Rewards
        );
    }

    function _convertFeeWithUniswap(
        address asset,
        uint256 amount,
        IPriceFeeds priceFeeds,
        uint256 bzrxRate,
        uint256 maxDisagreement)
        internal
        returns (uint256 returnAmount)
    {
        uint256 stakingReward = stakingRewards[asset];
        if (stakingReward != 0) {
            if (amount > stakingReward) {
                amount = stakingReward;
            }
            stakingRewards[asset] = stakingReward
                .sub(amount);

            uint256[] memory amounts = uniswapRouter.swapExactTokensForTokens(
                amount,
                1, // amountOutMin
                swapPaths[asset],
                address(this),
                block.timestamp
            );

            returnAmount = amounts[amounts.length - 1];

            // will revert if disagreement found
            _checkUniDisagreement(
                asset,
                amount,
                returnAmount,
                priceFeeds,
                bzrxRate,
                maxDisagreement
            );
        }
    }

    // TODO: Do we need to prevent excessive curve slippage?
    function _convertFeesWithCurve(
        uint256 daiAmount,
        uint256 usdcAmount,
        uint256 usdtAmount)
        internal
        returns (uint256 returnAmount)
    {
        uint256[3] memory curveAmounts;
        uint256 stakingReward;
        
        if (daiAmount != 0) {
            stakingReward = stakingRewards[DAI];
            if (stakingReward != 0) {
                if (daiAmount > stakingReward) {
                    daiAmount = stakingReward;
                }
                stakingRewards[DAI] = stakingReward
                    .sub(daiAmount);
                curveAmounts[0] = daiAmount;
            }
        }
        if (usdcAmount != 0) {
            stakingReward = stakingRewards[USDC];
            if (stakingReward != 0) {
                if (usdcAmount > stakingReward) {
                    usdcAmount = stakingReward;
                }
                stakingRewards[USDC] = stakingReward
                    .sub(usdcAmount);
                curveAmounts[1] = usdcAmount;
            }
        }
        if (usdtAmount != 0) {
            if (stakingReward != 0) {
                stakingReward = stakingRewards[USDT];
                if (usdtAmount > stakingReward) {
                    usdtAmount = stakingReward;
                }
                stakingRewards[USDT] = stakingReward
                    .sub(usdtAmount);
                curveAmounts[2] = usdtAmount;
            }
        }

        uint256 beforeBalance = curve3Crv.balanceOf(address(this));
        curve3pool.add_liquidity(curveAmounts, 0);
        returnAmount = curve3Crv.balanceOf(address(this)) - beforeBalance;
    }    

    
    /*event CheckUniDisagreement(
        uint256 rate,
        uint256 sourceToDestSwapRate,
        uint256 spreadValue,
        uint256 maxDisagreement
    );*/

    function _checkUniDisagreement(
        address asset,
        uint256 assetAmount,
        uint256 bzrxAmount,
        IPriceFeeds priceFeeds,
        uint256 bzrxRate,
        uint256 maxDisagreement)
        internal
    {
        (uint256 rate, uint256 precision) = priceFeeds.queryRate(
            asset,
            WETH
        );

        rate = rate
            .mul(WEI_PRECISION * WEI_PRECISION)
            .div(precision)
            .div(bzrxRate);

        uint256 sourceToDestSwapRate = bzrxAmount
            .mul(WEI_PRECISION)
            .div(assetAmount);

        uint256 spreadValue = sourceToDestSwapRate > rate ?
            sourceToDestSwapRate - rate :
            rate - sourceToDestSwapRate;

        /*emit CheckUniDisagreement(
            rate,
            sourceToDestSwapRate,
            spreadValue,
            maxDisagreement
        );*/

        if (spreadValue != 0) {
            spreadValue = spreadValue
                .mul(WEI_PERCENT_PRECISION)
                .div(sourceToDestSwapRate);

            require(
                spreadValue <= maxDisagreement,
                "price disagreement"
            );
        }
    }



    // OnlyOwner functions

    function pause()
        external
        onlyOwner
    {
        isPaused = true;
    }

    function unPause()
        external
        onlyOwner
    {
        isPaused = false;
    }

    function setFundsWallet(
        address _fundsWallet)
        external
        onlyOwner
    {
        fundsWallet = _fundsWallet;
    }

    function setFeeTokens(
        address[] calldata tokens)
        external
        onlyOwner
    {
        currentFeeTokens = tokens;
    }

    // path should start with the asset to swap and end with BZRX
    // only one path allowed per asset
    // ex: asset -> WETH -> BZRX
    function setPaths(
        address[][] calldata paths)
        external
        onlyOwner
    {
        address[] memory path;
        for (uint256 i = 0; i < paths.length; i++) {
            path = paths[i];
            require(path.length >= 2 &&
                path[0] != path[path.length - 1] &&
                path[path.length - 1] == BZRX,
                "invalid path"
            );
            
            // check that the path exists
            uint256[] memory amountsOut = uniswapRouter.getAmountsOut(10**10, path);
            require(amountsOut[amountsOut.length - 1] != 0, "path does not exist");
            
            swapPaths[path[0]] = path;
            setUniswapApproval(IERC20(path[0]));
        }
    }

    function setUniswapApproval(
        IERC20 asset)
        public
        onlyOwner
    {
        asset.safeApprove(address(uniswapRouter), 0);
        asset.safeApprove(address(uniswapRouter), uint256(-1));
    }

    function setCurveApproval()
        external
        onlyOwner
    {
        IERC20(DAI).safeApprove(address(curve3pool), 0);
        IERC20(DAI).safeApprove(address(curve3pool), uint256(-1));
        IERC20(USDC).safeApprove(address(curve3pool), 0);
        IERC20(USDC).safeApprove(address(curve3pool), uint256(-1));
        IERC20(USDT).safeApprove(address(curve3pool), 0);
        IERC20(USDT).safeApprove(address(curve3pool), uint256(-1));
    }
}
