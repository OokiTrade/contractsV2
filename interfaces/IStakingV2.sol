/**
 * Copyright 2017-2022, OokiDao. All Rights Reserved.
 * Licensed under the Apache License, Version 2.0.
 */

pragma solidity >=0.5.0 <=0.8.4;
pragma experimental ABIEncoderV2;

interface IStakingV2 {
    struct ProposalState {
        uint256 proposalTime;
        uint256 iOOKIWeight;
        uint256 lpOOKIBalance;
        uint256 lpTotalSupply;
    }

    struct AltRewardsUserInfo {
        uint256 rewardsPerShare;
        uint256 pendingRewards;
    }

    function getCurrentFeeTokens() external view returns (address[] memory);

    function maxUniswapDisagreement() external view returns (uint256);

    function fundsWallet() external view returns (address);

    function callerRewardDivisor() external view returns (uint256);

    function maxCurveDisagreement() external view returns (uint256);

    function rewardPercent() external view returns (uint256);

    function addRewards(uint256 newOOKI, uint256 newStableCoin) external;

    function stake(address[] calldata tokens, uint256[] calldata values) external;

    function unstake(address[] calldata tokens, uint256[] calldata values) external;

    function earned(address account)
        external
        view
        returns (
            uint256 bzrxRewardsEarned,
            uint256 stableCoinRewardsEarned,
            uint256 bzrxRewardsVesting,
            uint256 stableCoinRewardsVesting,
            uint256 sushiRewardsEarned
        );

    function pendingCrvRewards(address account)
        external
        view
        returns (
            uint256 bzrxRewardsEarned,
            uint256 stableCoinRewardsEarned,
            uint256 bzrxRewardsVesting,
            uint256 stableCoinRewardsVesting,
            uint256 sushiRewardsEarned
        );

    function getVariableWeights()
        external
        view
        returns (
            uint256 vBZRXWeight,
            uint256 iOOKIWeight,
            uint256 LPTokenWeight
        );

    function balanceOfByAsset(address token, address account) external view returns (uint256 balance);

    function balanceOfByAssets(address account)
        external
        view
        returns (
            uint256 bzrxBalance,
            uint256 iOOKIBalance,
            uint256 vBZRXBalance,
            uint256 LPTokenBalance
        );

    function balanceOfStored(address account) external view returns (uint256 vestedBalance, uint256 vestingBalance);

    function totalSupplyStored() external view returns (uint256 supply);

    function vestedBalanceForAmount(
        uint256 tokenBalance,
        uint256 lastUpdate,
        uint256 vestingEndTime
    ) external view returns (uint256 vested);

    function votingBalanceOf(address account, uint256 proposalId) external view returns (uint256 totalVotes);

    function votingBalanceOfNow(address account) external view returns (uint256 totalVotes);

    function votingFromStakedBalanceOf(address account) external view returns (uint256 totalVotes);

    function _setProposalVals(address account, uint256 proposalId) external returns (uint256);

    function exit() external;

    function addAltRewards(address token, uint256 amount) external;

    function governor() external view returns (address);

    function owner() external view returns (address);

    function transferOwnership(address newOwner) external;

    function claim(bool restake) external;

    function claimAltRewards() external;

    function _totalSupplyPerToken(address) external view returns(uint256);
    

    /// Guardian Interface

    function _isPaused(bytes4 sig) external view returns (bool isPaused);

    function toggleFunctionPause(bytes4 sig) external;

    function toggleFunctionUnPause(bytes4 sig) external;

    function changeGuardian(address newGuardian) external;

    function getGuardian() external view returns (address guardian);

    // Admin functions

    // Withdraw all from sushi masterchef
    function exitSushi() external;

    function setGovernor(address _governor) external;

    function setApprovals(
        address _token,
        address _spender,
        uint256 _value
    ) external;

    function setVoteDelegator(address stakingGovernance) external;

    function updateSettings(address settingsTarget, bytes calldata callData) external;

    function claimSushi() external returns (uint256 sushiRewardsEarned);

    function totalSupplyByAsset(address token)
        external
        view
        returns (uint256);

    function vestingLastSync(address user) external view returns(uint256);
}
