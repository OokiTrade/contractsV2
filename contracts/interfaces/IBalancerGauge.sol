// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

interface IBalancerGauge {
  function claimable_reward_write(
    address user,
    address token
  ) external returns (uint256 amount);

  function claim_rewards() external;

  function deposit(uint256 amount) external;

  function withdraw(uint256 amount) external;
}
