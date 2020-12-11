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
        address[] calldata tokens,
        uint256[] calldata values,
        address delegateToSet
    ) external checkPause updateRewards(msg.sender) {
        require(tokens.length == values.length, "count mismatch");

        address currentDelegate = _changeDelegate(delegateToSet);

        address token;
        uint256 stakeAmount;

        for (uint256 i = 0; i < tokens.length; i++) {
            token = tokens[i];
            require(
                token == BZRX ||
                    token == vBZRX ||
                    token == iBZRX ||
                    token == LPToken,
                "invalid token"
            );

            stakeAmount = values[i];
            if (stakeAmount == 0) {
                continue;
            }

            _balancesPerToken[token][msg.sender] = _balancesPerToken[token][msg
                .sender]
                .add(stakeAmount);
            _totalSupplyPerToken[token] = _totalSupplyPerToken[token].add(
                stakeAmount
            );

            repStakedPerToken[currentDelegate][token] = repStakedPerToken[currentDelegate][token]
                .add(stakeAmount);

            IERC20(token).safeTransferFrom(
                msg.sender,
                address(this),
                stakeAmount
            );

            if (token == vBZRX) {
                // used for settling vesting BZRX
                _vBZRXLastUpdate[msg.sender] = block.timestamp;
            }

            emit Staked(msg.sender, token, currentDelegate, stakeAmount);
        }
    }

    function unStake(address[] memory tokens, uint256[] memory values)
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
            require(
                token == BZRX ||
                    token == vBZRX ||
                    token == iBZRX ||
                    token == LPToken,
                "invalid token"
            );

            unstakeAmount = values[i];
            stakedAmount = _balancesPerToken[token][msg.sender];
            if (unstakeAmount == 0 || stakedAmount == 0) {
                continue;
            }
            if (unstakeAmount > stakedAmount) {
                unstakeAmount = stakedAmount;
            }

            _balancesPerToken[token][msg.sender] = stakedAmount - unstakeAmount; // will not overflow
            _totalSupplyPerToken[token] =
                _totalSupplyPerToken[token] -
                unstakeAmount; // will not overflow

            repStakedPerToken[currentDelegate][token] = repStakedPerToken[currentDelegate][token]
                .sub(unstakeAmount);

            IERC20(token).safeTransfer(msg.sender, unstakeAmount);

            if (token == vBZRX) {
                // used for settling vesting BZRX
                _vBZRXLastUpdate[msg.sender] = block.timestamp;
            }

            emit Unstaked(msg.sender, token, currentDelegate, unstakeAmount);
        }
    }

    function changeDelegate(address delegateToSet) external {
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

    function _claim(bool restake)
        internal
        updateRewards(msg.sender)
        returns (uint256 bzrxRewardsEarned, uint256 stableCoinRewardsEarned)
    {
        (bzrxRewardsEarned, stableCoinRewardsEarned, , ) = _earned(
            msg.sender,
            bzrxPerTokenStored,
            stableCoinPerTokenStored
        );

        lastClaimTime[msg.sender] = block.timestamp;

        if (bzrxRewardsEarned != 0) {
            bzrxRewards[msg.sender] = 0;
            if (restake) {
                _restakeBZRX(msg.sender, bzrxRewardsEarned);
            } else {
                IERC20(BZRX).transfer(msg.sender, bzrxRewardsEarned);
            }
        }
        if (stableCoinRewardsEarned != 0) {
            stableCoinRewards[msg.sender] = 0;
            curve3Crv.transfer(msg.sender, stableCoinRewardsEarned);
        }

        emit RewardPaid(msg.sender, bzrxRewardsEarned, stableCoinRewardsEarned);
    }

    function _restakeBZRX(address account, uint256 amount) internal {
        address currentDelegate = delegate[account];
        _balancesPerToken[BZRX][account] = _balancesPerToken[BZRX][account].add(
            amount
        );

        _totalSupplyPerToken[BZRX] = _totalSupplyPerToken[BZRX].add(amount);

        repStakedPerToken[currentDelegate][BZRX] = repStakedPerToken[currentDelegate][BZRX]
            .add(amount);

        emit Staked(account, BZRX, currentDelegate, amount);
    }

    function exit() public {
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

    function exitWithUpdate() external {
        sweepFees();
        exit();
    }

    function setRepActive(bool _isActive) public {
        reps[msg.sender] = _isActive;
        if (_isActive) {
            _repStakedSet.addAddress(msg.sender);
        }
    }

    function getRepVotes(uint256 start, uint256 count)
        external
        view
        returns (RepStakedTokens[] memory repStakedArr)
    {
        uint256 end = start.add(count).min256(_repStakedSet.length());
        if (start >= end) {
            return repStakedArr;
        }
        count = end - start;

        uint256 idx = count;
        address user;
        repStakedArr = new RepStakedTokens[](idx);
        for (uint256 i = --end; i >= start; i--) {
            user = _repStakedSet.getAddress(i);
            repStakedArr[count - (idx--)] = RepStakedTokens({
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
        uint256 _bzrxPerTokenStored = bzrxPerTokenStored;
        uint256 _stableCoinPerTokenStored = stableCoinPerTokenStored;

        (
            bzrxRewards[account],
            stableCoinRewards[account],
            bzrxVesting[account],
            stableCoinVesting[account]
        ) = _earned(account, _bzrxPerTokenStored, _stableCoinPerTokenStored);
        bzrxRewardsPerTokenPaid[account] = _bzrxPerTokenStored;
        stableCoinRewardsPerTokenPaid[account] = _stableCoinPerTokenStored;

        // The below handles vested BZRX settlement
        uint256 vBZRXBalance = _balancesPerToken[vBZRX][account];
        if (vBZRXBalance != 0) {
            uint256 vested = _vestedBalance(
                vBZRXBalance,
                _vBZRXLastUpdate[account],
                block.timestamp
            );
            if (vested != 0) {
                // automatically stake vested amount
                _restakeBZRX(account, vested);
            }
            _vBZRXLastUpdate[account] = block.timestamp;

            // make sure claim is up to date
            IVestingToken(vBZRX).claim();
        }

        _;
    }

    function earned(address account)
        public
        view
        returns (
            uint256 bzrxRewardsEarned,
            uint256 stableCoinRewardsEarned,
            uint256 bzrxRewardsVesting,
            uint256 stableCoinRewardsVesting
        )
    {
        (
            bzrxRewardsEarned,
            stableCoinRewardsEarned,
            bzrxRewardsVesting,
            stableCoinRewardsVesting
        ) = _earned(account, bzrxPerTokenStored, stableCoinPerTokenStored);
    }

    function earnedWithUpdate(address account)
        external
        returns (
            uint256,
            uint256,
            uint256,
            uint256 // bzrxRewardsEarned, stableCoinRewardsEarned, bzrxRewardsVesting, stableCoinRewardsVesting
        )
    {
        sweepFees();
        return earned(account);
    }

    function _earned(
        address account,
        uint256 _bzrxPerToken,
        uint256 _stableCoinPerToken
    )
        internal
        view
        returns (
            uint256 bzrxRewardsEarned,
            uint256 stableCoinRewardsEarned,
            uint256 bzrxRewardsVesting,
            uint256 stableCoinRewardsVesting
        )
    {
        (uint256 vestedBalance, uint256 vestingBalance) = balanceOfStored(
            account
        );

        uint256 bzrxPerTokenUnpaid = _bzrxPerToken.sub(
            bzrxRewardsPerTokenPaid[account]
        );
        uint256 stableCoinPerTokenUnpaid = _stableCoinPerToken.sub(
            stableCoinRewardsPerTokenPaid[account]
        );

        bzrxRewardsEarned = vestedBalance.mul(bzrxPerTokenUnpaid).div(1e18).add(
            bzrxRewards[account]
        );

        stableCoinRewardsEarned = vestedBalance
            .mul(stableCoinPerTokenUnpaid)
            .div(1e18)
            .add(stableCoinRewards[account]);

        bzrxRewardsVesting = vestingBalance
            .mul(bzrxPerTokenUnpaid)
            .div(1e18)
            .add(bzrxVesting[account]);

        stableCoinRewardsVesting = vestingBalance
            .mul(stableCoinPerTokenUnpaid)
            .div(1e18)
            .add(stableCoinVesting[account]);

        // add vested fees to rewards balances
        uint256 _lastClaimTime = lastClaimTime[account];

        uint256 rewardsVested = _vestedBalance(
            bzrxRewardsVesting,
            _lastClaimTime,
            block.timestamp
        );
        bzrxRewardsVesting -= rewardsVested;
        bzrxRewardsEarned += rewardsVested;

        rewardsVested = _vestedBalance(
            stableCoinRewardsVesting,
            _lastClaimTime,
            block.timestamp
        );
        stableCoinRewardsVesting -= rewardsVested;
        stableCoinRewardsEarned += rewardsVested;
    }

    // note: anyone can contribute rewards to the contract
    function addDirectRewards(
        address[] calldata accounts,
        uint256[] calldata bzrxAmounts,
        uint256[] calldata stableCoinAmounts
    ) external returns (uint256 bzrxTotal, uint256 stableCoinTotal) {
        require(
            accounts.length == bzrxAmounts.length &&
                accounts.length == stableCoinAmounts.length,
            "count mismatch"
        );

        for (uint256 i = 0; i < accounts.length; i++) {
            bzrxRewards[accounts[i]] = bzrxRewards[accounts[i]].add(
                bzrxAmounts[i]
            );
            bzrxTotal = bzrxTotal.add(bzrxAmounts[i]);
            stableCoinRewards[accounts[i]] = stableCoinRewards[accounts[i]].add(
                stableCoinAmounts[i]
            );
            stableCoinTotal = stableCoinTotal.add(stableCoinAmounts[i]);
        }
        if (bzrxTotal != 0) {
            IERC20(BZRX).transferFrom(msg.sender, address(this), bzrxTotal);
        }
        if (stableCoinTotal != 0) {
            curve3Crv.transferFrom(msg.sender, address(this), stableCoinTotal);
        }
    }

    // note: anyone can contribute rewards to the contract
    function addRewards(uint256 newBZRX, uint256 newStableCoin) external {
        if (newBZRX != 0 || newStableCoin != 0) {
            _addRewards(newBZRX, newStableCoin);
            if (newBZRX != 0) {
                IERC20(BZRX).transferFrom(msg.sender, address(this), newBZRX);
            }
            if (newStableCoin != 0) {
                curve3Crv.transferFrom(
                    msg.sender,
                    address(this),
                    newStableCoin
                );
            }
        }
    }

    function _addRewards(uint256 newBZRX, uint256 newStableCoin) internal {
        (
            vBZRXWeightStored,
            iBZRXWeightStored,
            LPTokenWeightStored
        ) = getVariableWeights();

        uint256 totalTokens = totalSupplyStored();
        require(totalTokens != 0, "nothing staked");

        bzrxPerTokenStored = bzrxPerTokenStored.add(
            newBZRX.mul(1e18).div(totalTokens)
        );
        stableCoinPerTokenStored = stableCoinPerTokenStored.add(
            newStableCoin.mul(1e18).div(totalTokens)
        );

        lastRewardsAddTime = block.timestamp;

        emit RewardAdded(msg.sender, newBZRX, newStableCoin);
    }

    function getVariableWeights()
        public
        view
        returns (
            uint256 vBZRXWeight,
            uint256 iBZRXWeight,
            uint256 LPTokenWeight
        )
    {
        uint256 totalVested = _vestedBalance(
            startingVBZRXBalance_,
            0,
            block.timestamp
        );

        vBZRXWeight = SafeMath
            .mul(startingVBZRXBalance_ - totalVested, 10**18) // overflow not possible
            .div(startingVBZRXBalance_);

        iBZRXWeight = ILoanPool(iBZRX).tokenPrice();

        uint256 lpTokenSupply = _totalSupplyPerToken[LPToken];
        if (lpTokenSupply != 0) {
            // staked LP tokens are assumed to represent the total unstaked supply (circulated supply - staked BZRX)
            uint256 normalizedLPTokenSupply = initialCirculatingSupply +
                totalVested -
                _totalSupplyPerToken[BZRX];

            LPTokenWeight = normalizedLPTokenSupply.mul(10**18).div(
                lpTokenSupply
            );
        }
    }

    function balanceOfByAsset(address token, address account)
        external
        view
        returns (uint256 balance)
    {
        balance = _balancesPerToken[token][account];
        if (token == BZRX) {
            _vestedBalance(
                _balancesPerToken[vBZRX][account],
                _vBZRXLastUpdate[account],
                block
                    .timestamp
            )
                .add(balance);
        }
    }

    function balanceOfStored(address account)
        public
        view
        returns (uint256 vestedBalance, uint256 vestingBalance)
    {
        uint256 vBZRXBalance = _balancesPerToken[vBZRX][account];
        if (vBZRXBalance != 0) {
            vestingBalance = vBZRXBalance.mul(vBZRXWeightStored).div(10**18);

            uint256 _lastRewardsAddTime = lastRewardsAddTime;
            if (_lastRewardsAddTime != 0) {
                // user is attributed to a staked balance of vested BZRX up to the time rewards were last added
                vestedBalance = _vestedBalance(
                    vBZRXBalance,
                    _vBZRXLastUpdate[account],
                    lastRewardsAddTime
                );
            }
        }

        vestedBalance = _balancesPerToken[BZRX][account].add(vestedBalance);

        vestedBalance = _balancesPerToken[iBZRX][account]
            .mul(iBZRXWeightStored)
            .div(10**18)
            .add(vestedBalance);

        vestedBalance = _balancesPerToken[LPToken][account]
            .mul(LPTokenWeightStored)
            .div(10**18)
            .add(vestedBalance);
    }

    function totalSupplyByAsset(address token) external view returns (uint256) {
        return _totalSupplyPerToken[token];
    }

    function totalSupplyStored() public view returns (uint256 supply) {
        uint256 vBZRXSupply = _totalSupplyPerToken[vBZRX];
        if (vBZRXSupply != 0) {
            supply = vBZRXSupply.mul(vBZRXWeightStored).div(10**18);

            uint256 _lastRewardsAddTime = lastRewardsAddTime;
            if (_lastRewardsAddTime != 0) {
                // treat vested BZRX as part of the staked BZRX supply
                supply = _vestedBalance(
                    vBZRXSupply,
                    lastRewardsAddTime,
                    block
                        .timestamp
                )
                    .add(supply);
            }
        }

        supply = _totalSupplyPerToken[BZRX].add(supply);

        supply = _totalSupplyPerToken[iBZRX]
            .mul(iBZRXWeightStored)
            .div(10**18)
            .add(supply);

        supply = _totalSupplyPerToken[LPToken]
            .mul(LPTokenWeightStored)
            .div(10**18)
            .add(supply);
    }

    function _vestedBalance(
        uint256 tokenBalance,
        uint256 lastUpdate,
        uint256 vestingTimeNow
    ) internal view returns (uint256 vested) {
        uint256 vestingTimeNow = vestingTimeNow.min256(block.timestamp);
        if (vestingTimeNow > lastUpdate) {
            if (
                vestingTimeNow <= vestingCliffTimestamp ||
                lastUpdate >= vestingEndTimestamp
            ) {
                // time cannot be before vesting starts
                // OR all vested token has already been claimed
                return 0;
            }
            if (lastUpdate < vestingCliffTimestamp) {
                // vesting starts at the cliff timestamp
                lastUpdate = vestingCliffTimestamp;
            }
            if (vestingTimeNow > vestingEndTimestamp) {
                // vesting ends at the end timestamp
                vestingTimeNow = vestingEndTimestamp;
            }

            uint256 timeSinceClaim = vestingTimeNow.sub(lastUpdate);
            vested =
                tokenBalance.mul(timeSinceClaim) /
                vestingDurationAfterCliff; // will never divide by 0
        }
    }

    function _changeDelegate(address delegateToSet)
        internal
        returns (address currentDelegate)
    {
        currentDelegate = delegate[msg.sender];
        if (delegateToSet == ZERO_ADDRESS) {
            require(currentDelegate != ZERO_ADDRESS, "delegate not specified");
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

            emit DelegateChanged(msg.sender, currentDelegate, delegateToSet);

            currentDelegate = delegateToSet;
        }
    }

    // Fee Conversion Logic //

    function sweepFees()
        public
        returns (uint256 bzrxRewards, uint256 crv3Rewards)
    {
        return sweepFeesByAsset(currentFeeTokens);
    }

    function sweepFeesByAsset(address[] memory assets)
        public
        onlyEOA
        returns (uint256 bzrxRewards, uint256 crv3Rewards)
    {
        uint256[] memory amounts = _withdrawFees(assets);
        _convertFees(assets, amounts);
        (bzrxRewards, crv3Rewards) = _distributeFees();
    }

    function _withdrawFees(address[] memory assets)
        internal
        returns (uint256[] memory)
    {
        uint256 rewardAmount;
        address _fundsWallet = fundsWallet;
        uint256[] memory amounts = bZx.withdrawFees(
            assets,
            address(this),
            IBZxPartial.FeeClaimType.All
        );
        for (uint256 i = 0; i < assets.length; i++) {
            if (amounts[i] == 0) {
                continue;
            }

            rewardAmount = amounts[i].mul(rewardPercent).div(1e20);

            stakingRewards[assets[i]] = stakingRewards[assets[i]].add(
                rewardAmount
            );

            IERC20(assets[i]).safeTransfer(
                _fundsWallet,
                amounts[i] - rewardAmount
            );
        }

        emit WithdrawFees(msg.sender);

        return amounts;
    }

    function _convertFees(address[] memory assets, uint256[] memory amounts)
        internal
        returns (uint256 bzrxOutput, uint256 crv3Output)
    {
        require(assets.length == amounts.length, "count mismatch");

        IPriceFeeds priceFeeds = IPriceFeeds(bZx.priceFeeds());
        (uint256 bzrxRate, ) = priceFeeds.queryRate(BZRX, WETH);
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
                bzrxOutput += _convertFeeWithUniswap(
                    asset,
                    amounts[i],
                    priceFeeds,
                    bzrxRate,
                    maxDisagreement
                );
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

        emit ConvertFees(msg.sender, bzrxOutput, crv3Output);
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
                bzrxRewards = bzrxRewards.sub(callerReward);

                IERC20(BZRX).transfer(msg.sender, callerReward);
            }
            if (crv3Rewards != 0) {
                stakingRewards[address(curve3Crv)] = 0;

                callerReward = crv3Rewards / 100;
                crv3Rewards = crv3Rewards.sub(callerReward);

                curve3Crv.transfer(msg.sender, callerReward);
            }

            _addRewards(bzrxRewards, crv3Rewards);
        }

        emit DistributeFees(msg.sender, bzrxRewards, crv3Rewards);
    }

    function _convertFeeWithUniswap(
        address asset,
        uint256 amount,
        IPriceFeeds priceFeeds,
        uint256 bzrxRate,
        uint256 maxDisagreement
    ) internal returns (uint256 returnAmount) {
        uint256 stakingReward = stakingRewards[asset];
        if (stakingReward != 0) {
            if (amount > stakingReward) {
                amount = stakingReward;
            }
            stakingRewards[asset] = stakingReward.sub(amount);

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

    function _convertFeesWithCurve(
        uint256 daiAmount,
        uint256 usdcAmount,
        uint256 usdtAmount
    ) internal returns (uint256 returnAmount) {
        uint256[3] memory curveAmounts;
        uint256 stakingReward;

        if (daiAmount != 0) {
            stakingReward = stakingRewards[DAI];
            if (stakingReward != 0) {
                if (daiAmount > stakingReward) {
                    daiAmount = stakingReward;
                }
                stakingRewards[DAI] = stakingReward.sub(daiAmount);
                curveAmounts[0] = daiAmount;
            }
        }
        if (usdcAmount != 0) {
            stakingReward = stakingRewards[USDC];
            if (stakingReward != 0) {
                if (usdcAmount > stakingReward) {
                    usdcAmount = stakingReward;
                }
                stakingRewards[USDC] = stakingReward.sub(usdcAmount);
                curveAmounts[1] = usdcAmount;
            }
        }
        if (usdtAmount != 0) {
            if (stakingReward != 0) {
                stakingReward = stakingRewards[USDT];
                if (usdtAmount > stakingReward) {
                    usdtAmount = stakingReward;
                }
                stakingRewards[USDT] = stakingReward.sub(usdtAmount);
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
        uint256 maxDisagreement
    ) internal view {
        (uint256 rate, uint256 precision) = priceFeeds.queryRate(asset, WETH);

        rate = rate.mul(WEI_PRECISION * WEI_PRECISION).div(precision).div(
            bzrxRate
        );

        uint256 sourceToDestSwapRate = bzrxAmount.mul(WEI_PRECISION).div(
            assetAmount
        );

        uint256 spreadValue = sourceToDestSwapRate > rate
            ? sourceToDestSwapRate - rate
            : rate - sourceToDestSwapRate;

        /*emit CheckUniDisagreement(
            rate,
            sourceToDestSwapRate,
            spreadValue,
            maxDisagreement
        );*/

        if (spreadValue != 0) {
            spreadValue = spreadValue.mul(WEI_PERCENT_PRECISION).div(
                sourceToDestSwapRate
            );

            require(spreadValue <= maxDisagreement, "price disagreement");
        }
    }

    // OnlyOwner functions

    function pause() external onlyOwner {
        isPaused = true;
    }

    function unPause() external onlyOwner {
        isPaused = false;
    }

    function setFundsWallet(address _fundsWallet) external onlyOwner {
        fundsWallet = _fundsWallet;
    }

    function setFeeTokens(address[] calldata tokens) external onlyOwner {
        currentFeeTokens = tokens;
    }

    // path should start with the asset to swap and end with BZRX
    // only one path allowed per asset
    // ex: asset -> WETH -> BZRX
    function setPaths(address[][] calldata paths) external onlyOwner {
        address[] memory path;
        for (uint256 i = 0; i < paths.length; i++) {
            path = paths[i];
            require(
                path.length >= 2 &&
                    path[0] != path[path.length - 1] &&
                    path[path.length - 1] == BZRX,
                "invalid path"
            );

            // check that the path exists
            uint256[] memory amountsOut = uniswapRouter.getAmountsOut(
                10**10,
                path
            );
            require(
                amountsOut[amountsOut.length - 1] != 0,
                "path does not exist"
            );

            swapPaths[path[0]] = path;
            setUniswapApproval(IERC20(path[0]));
        }
    }

    function setUniswapApproval(IERC20 asset) public onlyOwner {
        asset.safeApprove(address(uniswapRouter), 0);
        asset.safeApprove(address(uniswapRouter), uint256(-1));
    }

    function setCurveApproval() external onlyOwner {
        IERC20(DAI).safeApprove(address(curve3pool), 0);
        IERC20(DAI).safeApprove(address(curve3pool), uint256(-1));
        IERC20(USDC).safeApprove(address(curve3pool), 0);
        IERC20(USDC).safeApprove(address(curve3pool), uint256(-1));
        IERC20(USDT).safeApprove(address(curve3pool), 0);
        IERC20(USDT).safeApprove(address(curve3pool), uint256(-1));
    }
}
