/**
 * Copyright 2017-2022, OokiDao. All Rights Reserved.
 * Licensed under the Apache License, Version 2.0.
 */

pragma solidity 0.5.17;
pragma experimental ABIEncoderV2;

import "../StakingStateV2.sol";
import "../../farm/interfaces/IMasterChefSushi.sol";

contract AdminSettings is StakingStateV2 {
    function initialize(address target) external onlyOwner {
        _setTarget(this.exitSushi.selector, target);
        _setTarget(this.setGovernor.selector, target);
        _setTarget(this.setApprovals.selector, target);
        _setTarget(this.setVoteDelegator.selector, target);
    }

    // Withdraw all from sushi masterchef
    function exitSushi() external onlyOwner {
        IMasterChefSushi chef = IMasterChefSushi(SUSHI_MASTERCHEF);
        uint256 balance = chef.userInfo(OOKI_ETH_SUSHI_MASTERCHEF_PID, address(this)).amount;
        chef.withdraw(OOKI_ETH_SUSHI_MASTERCHEF_PID, balance);
    }

    // OnlyOwner functions

    function setGovernor(address _governor) external onlyOwner {
        governor = _governor;
    }

    function setApprovals(
        address _token,
        address _spender,
        uint256 _value
    ) external onlyOwner {
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
