/**
 * Copyright 2017-2020, bZeroX, LLC <https://bzx.network/>. All Rights Reserved.
 * Licensed under the Apache License, Version 2.0.
 */

pragma solidity 0.5.17;
pragma experimental ABIEncoderV2;

import "./StakingState.sol";
import "./StakingConstants.sol";
import "../farm/interfaces/IMasterChefSushi.sol";
import "../governance/PausableGuardian.sol";

contract StakingAdminSettings is StakingState, StakingConstants, PausableGuardian {


    // Withdraw all from sushi masterchef
    function exitSushi()
        external
        onlyOwner
    {
        IMasterChefSushi chef = IMasterChefSushi(SUSHI_MASTERCHEF);
        uint256 balance = chef.userInfo(BZRX_ETH_SUSHI_MASTERCHEF_PID, address(this)).amount;
        chef.withdraw(
            BZRX_ETH_SUSHI_MASTERCHEF_PID,
            balance
        );
    }



    // OnlyOwner functions

    function togglePause(
        bool _isPaused)
        external
        onlyOwner
    {
        isPaused = _isPaused;
    }

    function setFundsWallet(
        address _fundsWallet)
        external
        onlyOwner
    {
        fundsWallet = _fundsWallet;
    }

    function setGovernor(
        address _governor)
        external
        onlyOwner
    {
        governor = _governor;
    }

    function setFeeTokens(
        address[] calldata tokens)
        external
        onlyOwner
    {
        currentFeeTokens = tokens;
    }

    function setRewardPercent(
        uint256 _rewardPercent)
        external
        onlyOwner
    {
        require(_rewardPercent <= 1e20, "value too high");
        rewardPercent = _rewardPercent;
    }

    function setMaxUniswapDisagreement(
        uint256 _maxUniswapDisagreement)
        external
        onlyOwner
    {
        require(_maxUniswapDisagreement != 0, "invalid param");
        maxUniswapDisagreement = _maxUniswapDisagreement;
    }

    function setMaxCurveDisagreement(
        uint256 _maxCurveDisagreement)
        external
        onlyOwner
    {
        require(_maxCurveDisagreement != 0, "invalid param");
        maxCurveDisagreement = _maxCurveDisagreement;
    }

    function setCallerRewardDivisor(
        uint256 _callerRewardDivisor)
        external
        onlyOwner
    {
        require(_callerRewardDivisor != 0, "invalid param");
        callerRewardDivisor = _callerRewardDivisor;
    }

    function setInitialAltRewardsPerShare()
        external
        onlyOwner
    {
        uint256 index = altRewardsRounds[SUSHI].length;
        if(index == 0) {
            return;
        }

        altRewardsPerShare[SUSHI] = altRewardsRounds[SUSHI][index - 1];
    }

    function setApprovals(address _token, address _spender, uint _value)
        external
        onlyOwner
    {
        IERC20(_token).approve(_spender, _value);
    }
}
