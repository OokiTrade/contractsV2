// SPDX-License-Identifier: Apache-2.0
pragma solidity >=0.5.17 <0.9.0;


interface IBalancerHelpers {
  function queryJoin(
    bytes32 poolId,
    address sender,
    address recipient,
    JoinPoolRequest calldata request
  ) external returns (uint256 bptOut, uint256[] memory amountsIn);

  struct JoinPoolRequest {
    address[] assets;
    uint256[] maxAmountsIn;
    bytes userData;
    bool fromInternalBalance;
  }

  function queryExit(
    bytes32 poolId,
    address sender,
    address recipient,
    ExitPoolRequest calldata request
  ) external returns (uint256 bptIn, uint256[] memory amountsOut);

  struct ExitPoolRequest {
    address[] assets;
    uint256[] minAmountsOut;
    bytes userData;
    bool toInternalBalance;
  }
}
