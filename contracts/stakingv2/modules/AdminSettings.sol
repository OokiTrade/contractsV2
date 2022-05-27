/**
 * Copyright 2017-2022, OokiDao. All Rights Reserved.
 * Licensed under the Apache License, Version 2.0.
 */

pragma solidity 0.5.17;
pragma experimental ABIEncoderV2;

import "../../farm/interfaces/IMasterChefSushi.sol";
import "../../farm/interfaces/IMasterChefSushi2.sol";
import "./StakingPausableGuardian.sol";
import "./Common.sol";

contract AdminSettings is Common {
    function initialize(address target) external onlyOwner {
        _setTarget(this.exitSushi.selector, target);
        _setTarget(this.setGovernor.selector, target);
        _setTarget(this.setApprovals.selector, target);
        _setTarget(this.setVoteDelegator.selector, target);
        _setTarget(this.migrateSushi.selector, target);
        _setTarget(this.altRewardsBlock.selector, target);
        _setTarget(this.altRewardsPerSharePerBlock.selector, target);
        _setTarget(this.userAltRewardsInfo.selector, target);
        _setTarget(this.setAltRewardsUserInfo.selector, target);
    }

    // Withdraw all from sushi masterchef
    function exitSushi() external onlyGuardian {
        IMasterChefSushi2 chef = IMasterChefSushi2(SUSHI_MASTERCHEF);
        uint256 balance = chef.userInfo(OOKI_ETH_SUSHI_MASTERCHEF_PID, address(this)).amount;
        chef.withdraw(OOKI_ETH_SUSHI_MASTERCHEF_PID, balance, address(this));
    }

    //Migrate from v1 pool to v2
    function migrateSushi(uint256 srcPoolPid, address srcMasterchef, uint256 dstPoolPid, address dstMasterchef)
        external
        onlyGuardian
    {
        require(altRewardsPerSharePerBlock[SUSHI] == 0 && altRewardsStartBlock[SUSHI] == 0, "Already migrated");
        altRewardsStartBlock[SUSHI] = 14183871; //20220201
        IMasterChefSushi src = IMasterChefSushi(srcMasterchef);
        IMasterChefSushi2 dst = IMasterChefSushi2(dstMasterchef);
        uint256 balance = src.userInfo(srcPoolPid, address(this)).amount;
        src.withdraw(srcPoolPid, balance);
        setApprovals(OOKI_ETH_LP, address(src), 0);
        setApprovals(OOKI_ETH_LP, address(dst), uint256(-1));
        dst.deposit(dstPoolPid, balance, address(this));

        uint256 totalSupply = _totalSupplyPerToken[OOKI_ETH_LP];
        require(totalSupply != 0, "no deposits");
        uint256 cliff = block.number - altRewardsStartBlock[SUSHI];
        altRewardsPerShare[SUSHI] = IERC20(SUSHI).balanceOf(address(this)).mul(1e12).div(totalSupply);
        altRewardsPerSharePerBlock[SUSHI] = altRewardsPerShare[SUSHI].div(cliff);
        altRewardsBlock[SUSHI] = block.number;
    }

    function setAltRewardsUserInfo(address[] calldata users, uint256[] calldata stakingStartBlock)
        external
        onlyGuardian
    {
        require(users.length == stakingStartBlock.length, "!length");
        for (uint256 i = 0; i < users.length; i++) {
            userAltRewardsInfo[users[i]][SUSHI].stakingStartBlock = stakingStartBlock[i];
            userAltRewardsInfo[users[i]][SUSHI].pending = 0;
        }
    }

    // OnlyOwner functions
    function setGovernor(address _governor) external onlyOwner {
        governor = _governor;
    }

    function setApprovals(
        address _token,
        address _spender,
        uint256 _value
    ) public onlyOwner {
        IERC20(_token).safeApprove(_spender, _value);
    }

    function setVoteDelegator(address stakingGovernance) external onlyOwner {
        voteDelegator = stakingGovernance;
    }

    // OnlyOwner functions
    function updateSettings(address settingsTarget, bytes memory callData) public onlyOwner returns (bytes memory) {
        (bool result, ) = settingsTarget.delegatecall(callData);
        assembly {
            let size := returndatasize
            let ptr := mload(0x40)
            returndatacopy(ptr, 0, size)
            if eq(result, 0) {
                revert(ptr, size)
            }
            return(ptr, size)
        }
    }
}
