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
import "@openzeppelin-2.5.0/token/ERC20/SafeERC20.sol";
import "../../interfaces/IBZRXv2Converter.sol";
import "../interfaces/IUniswapV2Router.sol";

contract StakingAdminSettings is StakingState, StakingConstants, PausableGuardian {
    using SafeERC20 for IERC20;

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
        IERC20(_token).safeApprove(_spender, _value);
    }

    function setVoteDelegator(address stakingGovernance)
        external
        onlyOwner
    {
        voteDelegator = stakingGovernance;
    }


    function migrateSLP() public onlyOwner {
        require(address(converter) != address(0), "no converter");

        IMasterChefSushi chef = IMasterChefSushi(SUSHI_MASTERCHEF);
        uint256 balance = chef.userInfo(188, address(this)).amount;
        
        chef.withdraw(188, balance);

        // migrating SLP
        IERC20(LPTokenBeforeMigration).approve(SUSHI_ROUTER, balance);
        (uint256 WETHBalance, uint256 BZRXBalance) = IUniswapV2Router(SUSHI_ROUTER).removeLiquidity(WETH, BZRX, balance, 1, 1, address(this), block.timestamp);

        uint256 totalBZRXBalance = IERC20(BZRX).balanceOf(address(this));


        IERC20(BZRX).approve(address(converter), 2**256 -1); // this max approval will be used to convert vested bzrx to ooki
        // this will convert and current BZRX on a contract as well
        IBZRXv2Converter(converter).convert(address(this), totalBZRXBalance);
        
        BZRXBalance = BZRXBalance * 10; // 10x split, this is ooki balance now
        IERC20(WETH).approve(SUSHI_ROUTER, WETHBalance);
        IERC20(OOKI).approve(SUSHI_ROUTER, BZRXBalance);

        (,,uint256 SLPAfter) = IUniswapV2Router(SUSHI_ROUTER).addLiquidity(WETH, OOKI, WETHBalance, BZRXBalance, 1, 1, address(this), block.timestamp);

        // migrating BZRX balances to OOKI
        _totalSupplyPerToken[OOKI] = _totalSupplyPerToken[BZRX] * 10;
        _totalSupplyPerToken[BZRX] = 0;
        

        // BIG TODO since these are not migrated 1:1
        _totalSupplyPerToken[LPToken] = SLPAfter;
        // _totalSupplyPerToken[LPTokenBeforeMigration] = 0; I don't zero out this so I can use to calc proportion when migrating user balance
        // TODO ? is this correct
        // bzrxPerTokenStored = bzrxPerTokenStored * 10;
        // stableCoinPerTokenStored = stableCoinPerTokenStored;
    }

    function setConverter(IBZRXv2Converter _converter) public onlyOwner {
        converter = _converter;
    }
}
