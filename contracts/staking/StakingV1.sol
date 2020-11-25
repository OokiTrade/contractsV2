/**
 * Copyright 2017-2020, bZeroX, LLC <https://bzx.network/>. All Rights Reserved.
 * Licensed under the Apache License, Version 2.0.
 */

pragma solidity 0.5.17;
pragma experimental ABIEncoderV2;

import "./StakingState.sol";
import "../interfaces/IVestingToken.sol";
import "../interfaces/ILoanPool.sol";
import "../feeds/IPriceFeeds.sol";
import "./interfaces/IUniswapV2Router.sol";
import "./interfaces/ICurve3Pool.sol";
import "./interfaces/IBZxPartial.sol";


contract StakingV1 is StakingState {

    address public constant BZRX = 0x56d811088235F11C8920698a204A5010a788f4b3;
    address public constant vBZRX = 0xB72B31907C1C95F3650b64b2469e08EdACeE5e8F;
    address public constant iBZRX = 0x18240BD9C07fA6156Ce3F3f61921cC82b2619157;
    IERC20 public constant curve3Crv = IERC20(0x6c3F90f043a72FA612cbac8115EE7e52BDe6E490);

    address public constant WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    address public constant DAI = 0x6B175474E89094C44Da98b954EedeAC495271d0F;
    address public constant USDC = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
    address public constant USDT = 0xdAC17F958D2ee523a2206206994597C13D831ec7;

    IUniswapV2Router public constant uniswapRouter = IUniswapV2Router(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
    ICurve3Pool public constant curve3pool = ICurve3Pool(0xbEbc44782C7dB0a1A60Cb6fe97d0b483032FF1C7);
    IBZxPartial public constant bZx = IBZxPartial(0xD8Ee69652E4e4838f2531732a46d1f7F584F0b7f);

    uint256 public constant cliffDuration =                15768000; // 86400 * 365 * 0.5
    uint256 public constant vestingDuration =              126144000; // 86400 * 365 * 4
    uint256 internal constant vestingDurationAfterCliff =  110376000; // 86400 * 365 * 3.5
    uint256 internal constant vestingStartTimestamp =      1594648800; // start_time
    uint256 internal constant vestingCliffTimestamp =      vestingStartTimestamp + cliffDuration;
    uint256 internal constant vestingEndTimestamp =        vestingStartTimestamp + vestingDuration;

    modifier onlyEOA() {
        require(msg.sender == tx.origin, "unauthorized");
        _;
    }

    struct RepStakedTokens {
        address user;
        bool isActive;
        uint256 BZRX;
        uint256 vBZRX;
        uint256 iBZRX;
        uint256 LPToken;
    }

    event Staked(
        address indexed user,
        address indexed token,
        address indexed delegate,
        uint256 amount
    );

    event Unstaked(
        address indexed user,
        address indexed token,
        address indexed delegate,
        uint256 amount
    );

    event RewardAdded(
        address indexed sender,
        uint256 bzrxAmount,
        uint256 stableCoinAmount
    );

    event RewardPaid(
        address indexed user,
        uint256 bzrxAmount,
        uint256 stableCoinAmount
    );

    event DelegateChanged(
        address indexed user,
        address indexed oldDelegate,
        address indexed newDelegate
    );

    modifier checkPause() {
        require(isPaused, "paused");
        _;
    }

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

        address currentDelegate = _setDelegate(delegateToSet);

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

            // the below comes after the transfer of vBZRX, which settles vested BZRX locally
            if (token == vBZRX && tokenBalance != 0) {
                (uint256 vested, uint256 timestamp) = _vestedBalance(
                    tokenBalance,
                    _vBZRXDepositTime[msg.sender]
                );

                _vBZRXDepositTime[msg.sender] = timestamp;

                if (vested != 0) {
                    IERC20(BZRX).transfer(msg.sender, vested);
                }
            }

            emit Staked(
                msg.sender,
                token,
                currentDelegate,
                stakeAmount
            );
        }
    }

    function _vestedBalance(
        uint256 tokenBalance,
        uint256 lastDepositTime)
        internal
        view
        returns (uint256 vested, uint256 timestamp)
    {
        timestamp = _getTimestamp();
        if (lastDepositTime < timestamp) {
            if (timestamp <= vestingCliffTimestamp ||
                lastDepositTime >= vestingEndTimestamp) {
                // time cannot be before vesting starts
                // OR all vested token has already been claimed
                return (0, timestamp);
            }
            if (lastDepositTime < vestingCliffTimestamp) {
                // vesting starts at the cliff timestamp
                lastDepositTime = vestingCliffTimestamp;
            }
            if (timestamp > vestingEndTimestamp) {
                // vesting ends at the end timestamp
                timestamp = vestingEndTimestamp;
            }

            uint256 timeSinceClaim = timestamp.sub(lastDepositTime);
            vested = tokenBalance.mul(timeSinceClaim) / vestingDurationAfterCliff; // will never divide by 0
        }
    }

    // TODO: handle removing delegated votes from current rep
    function unStake(
        address[] memory tokens,
        uint256[] memory values)
        public
        updateRewards(msg.sender)
    {
        require(tokens.length == values.length, "count mismatch");

        //address currentDelegate = _setDelegate(delegateToSet);
        address currentDelegate = msg.sender;

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

            IERC20(token).safeTransfer(msg.sender, unstakeAmount);

           // the below comes after the transfer of vBZRX, which settles vested BZRX locally
            if (token == vBZRX && unstakeAmount != 0) {
                (uint256 vested, uint256 timestamp) = _vestedBalance(
                    unstakeAmount,
                    _vBZRXDepositTime[msg.sender]
                );

                _vBZRXDepositTime[msg.sender] = timestamp;

                if (vested != 0) {
                    IERC20(BZRX).transfer(msg.sender, vested);
                }
            }

            emit Unstaked(
                msg.sender,
                token,
                currentDelegate,
                unstakeAmount
            );

            //repStakedPerToken[currentDelegate][token] = repStakedPerToken[currentDelegate][token]
            //    .add(stakeAmount);
        }
    }

    function claim()
        public
    {
        return _claim(false);
    }

    function claimAndRestake()
        public
    {
        return _claim(true);
    }

    function _claim(
        bool restake)
        internal
        updateRewards(msg.sender)
    {
        (uint256 bzrxRewardsEarned, uint256 stableCoinRewardsEarned) = earned(msg.sender);
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
        external
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

    function lastTimeRewardApplicable()
        public
        view
        returns (uint256)
    {
        return periodFinish
            .min256(_getTimestamp());
    }

    modifier updateRewards(address account) {
        (uint256 _bzrxPerToken, uint256 _stableCoinPerToken) = rewardsPerToken();
        bzrxPerTokenStored = _bzrxPerToken;
        stableCoinPerTokenStored = _stableCoinPerToken;

        lastUpdateTime = lastTimeRewardApplicable();

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
        uint256 totalSupplyBZRX = totalSupplyByAssetNormed(BZRX);
        uint256 totalSupplyVBZRX = totalSupplyByAssetNormed(vBZRX);
        uint256 totalSupplyIBZRX = totalSupplyByAssetNormed(iBZRX);
        uint256 totalSupplyLPToken = totalSupplyByAssetNormed(LPToken);

        uint256 totalTokens = totalSupplyBZRX
            .add(totalSupplyVBZRX)
            .add(totalSupplyIBZRX)
            .add(totalSupplyLPToken);

        if (totalTokens == 0) {
            return (bzrxPerTokenStored, stableCoinPerTokenStored);
        }

        uint256 duration = lastTimeRewardApplicable()
            .sub(lastUpdateTime);

        return (
            bzrxPerTokenStored.add(
                duration
                    .mul(bzrxRewardRate)
                    .mul(1e18)
                    .div(totalTokens)),
            stableCoinPerTokenStored.add(
                duration
                    .mul(stableCoinRewardRate)
                    .mul(1e18)
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
        uint256 _periodFinish = periodFinish;
        uint256 _timestamp = _getTimestamp();

        if (newBZRX != 0) {
            if (_timestamp >= _periodFinish) {
                bzrxRewardRate = newBZRX;
            } else {
                bzrxRewardRate = bzrxRewardRate
                    .add(newBZRX);
            }
        }
        if (newStableCoin != 0) {
            if (_timestamp >= _periodFinish) {
                stableCoinRewardRate = newStableCoin;
            } else {
                stableCoinRewardRate = stableCoinRewardRate
                    .add(newStableCoin);
            }
        }
        
        lastUpdateTime = _timestamp;
        periodFinish = _timestamp + 1;

        emit RewardAdded(
            msg.sender,
            newBZRX,
            newStableCoin
        );
    }

    // TODO: account for BZRX vesting from vBZRX (vBZRX discounted and BZRX credited as vesting occurs)
    function balanceOf(
        address account)
        public
        view
        returns (uint256)
    {
        uint256 BZRXBalance = balanceOfByAssetNormed(BZRX, account);
        uint256 vBZRXBalance = balanceOfByAssetNormed(vBZRX, account);

        /*if (vBZRXBalance) {
            (uint256 vested, uint256 timestamp) = _vestedBalance(
                vBZRXBalance,
                _vBZRXDepositTime[msg.sender]
            );
        }*/

        return BZRXBalance
            .add(vBZRXBalance)
            .add(balanceOfByAssetNormed(iBZRX, account))
            .add(balanceOfByAssetNormed(LPToken, account));
    }

    function balanceOfByAsset(
        address token,
        address account)
        public
        view
        returns (uint256 balance)
    {
        balance = _balancesPerToken[token][account];
        if (token == iBZRX && balance != 0) {
            balance = balance
                .mul(ILoanPool(iBZRX).tokenPrice())
                .div(10**18);
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
            .add(totalSupplyByAsset(iBZRX))
            .add(totalSupplyByAsset(LPToken));
    }

    function totalSupplyNormed()
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
        returns (uint256 supply)
    {
        supply = _totalSupplyPerToken[token];
        if (token == iBZRX && supply != 0) {
            supply = supply
                .mul(ILoanPool(iBZRX).tokenPrice())
                .div(10**18);
        }
    }

    function totalSupplyByAssetNormed(
        address token)
        public
        view
        returns (uint256)
    {
        if (token == LPToken) {
            uint256 circulatingSupply = initialCirculatingSupply + IVestingToken(vBZRX).totalVested();
            
            // staked LP tokens are assumed to represent the total unstaked supply (circulated supply - staked BZRX - staked iBZRX)
            return totalSupplyByAsset(LPToken) != 0 ?
                circulatingSupply - totalSupplyByAsset(BZRX) - totalSupplyByAsset(iBZRX) :
                0;
        } else {
            return totalSupplyByAsset(token);
        }
    }

    // TODO: allow changing of existing delegate (transfer old votes)
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


    // Fee Conversion Logic //

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

    function sweepFees(
        address[] calldata assets)
        external
        onlyEOA
        returns (uint256 bzrxRewards, uint256 crv3Rewards)
    {
        uint256[] memory amounts = _withdrawFees(assets);
        _convertFees(assets, amounts);
        (bzrxRewards, crv3Rewards) = _distributeFees();
    }

    function withdrawFees(
        address[] calldata assets)
        external
        onlyOwner
        returns (uint256[] memory)
    {
        return _withdrawFees(assets);
    }

    function convertFees(
        address[] calldata assets,
        uint256[] calldata amounts)
        external
        onlyOwner
        returns (uint256 bzrxOuput, uint256 crv3Output)
    {
        return _convertFees(assets, amounts);
    }

    function distributeFees()
        external
        onlyOwner
        returns (uint256 bzrxRewards, uint256 crv3Rewards)
    {
        return _distributeFees();
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

            IERC20(assets[i]).transfer(
                _fundsWallet,
                amounts[i] - rewardAmount
            );
        }
        return amounts;
    }

    function _convertFees(
        address[] memory assets,
        uint256[] memory amounts)
        internal
        returns (uint256 bzrxOuput, uint256 crv3Output)
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
                bzrxOuput += _convertFeeWithUniswap(asset, amounts[i], priceFeeds, bzrxRate, maxDisagreement);
            }
        }
        if (bzrxOuput != 0) {
            stakingRewards[BZRX] += bzrxOuput;
        }

        if (daiAmount != 0 || usdcAmount != 0 || usdtAmount != 0) {
            crv3Output = _convertFeesWithCurve(
                daiAmount,
                usdcAmount,
                usdtAmount
            );
            stakingRewards[address(curve3Crv)] += crv3Output;
        }
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

    
    // TODO: for debugging, remove later
    event CheckUniDisagreement(
        uint256 rate,
        uint256 sourceToDestSwapRate,
        uint256 spreadValue,
        uint256 maxDisagreement
    );

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

        emit CheckUniDisagreement(
            rate,
            sourceToDestSwapRate,
            spreadValue,
            maxDisagreement
        );

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

}
