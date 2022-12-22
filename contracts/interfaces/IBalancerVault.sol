// SPDX-License-Identifier: Apache-2.0
pragma solidity >=0.5.17 <0.9.0;
pragma experimental ABIEncoderV2;

interface IBalancerVault {
  function joinPool(
    bytes32 poolId,
    address sender,
    address recipient,
    JoinPoolRequest calldata request
  ) external payable;

  struct JoinPoolRequest {
    address[] assets;
    uint256[] maxAmountsIn;
    bytes userData;
    bool fromInternalBalance;
  }

  function exitPool(
    bytes32 poolId,
    address sender,
    address payable recipient,
    ExitPoolRequest calldata request
  ) external;

  struct ExitPoolRequest {
    address[] assets;
    uint256[] minAmountsOut;
    bytes userData;
    bool toInternalBalance;
  }

  function swap(
    SingleSwap calldata singleSwap,
    FundManagement calldata funds,
    uint256 limit,
    uint256 deadline
  ) external payable returns (uint256);

  enum SwapKind {
    GIVEN_IN,
    GIVEN_OUT
  }

  struct SingleSwap {
    bytes32 poolId;
    SwapKind kind;
    address assetIn;
    address assetOut;
    uint256 amount;
    bytes userData;
  }

  struct BatchSwapStep {
    bytes32 poolId;
    uint256 assetInIndex;
    uint256 assetOutIndex;
    uint256 amount;
    bytes userData;
  }

  function batchSwap(
    SwapKind kind,
    BatchSwapStep[] calldata swaps,
    address[] calldata assets,
    FundManagement calldata funds,
    int256[] calldata limits,
    uint256 deadline
  ) external returns (int256[] memory assetDeltas);

  function queryBatchSwap(
    SwapKind kind,
    BatchSwapStep[] calldata swaps,
    address[] calldata assets,
    FundManagement calldata funds
  ) external returns (int256[] memory assetDeltas);

  struct FundManagement {
    address sender;
    bool fromInternalBalance;
    address payable recipient;
    bool toInternalBalance;
  }

  function getPoolTokens(
    bytes32 poolId
  )
    external
    view
    returns (
      address[] memory tokens,
      uint256[] memory balances,
      uint256 lastChangeBlock
    );

  function hasApprovedRelayer(
    address user,
    address relayer
  ) external view returns (bool);

  function getRate() external view returns (uint256);

  function getInternalBalance(
    address user,
    address[] calldata tokens
  ) external view returns (uint256[] memory);

  function manageUserBalance(UserBalanceOp[] calldata ops) external payable;

  struct UserBalanceOp {
    UserBalanceOpKind kind;
    address asset;
    uint256 amount;
    address sender;
    address payable recipient;
  }

  enum UserBalanceOpKind {
    DEPOSIT_INTERNAL,
    WITHDRAW_INTERNAL,
    TRANSFER_INTERNAL,
    TRANSFER_EXTERNAL
  }

  function getPool(
    bytes32 poolId
  ) external view returns (address, PoolSpecialization);

  enum PoolSpecialization {
    GENERAL,
    MINIMAL_SWAP_INFO,
    TWO_TOKEN
  }

  function getPoolTokenInfo(
    bytes32 poolId,
    address token
  )
    external
    view
    returns (
      uint256 cash,
      uint256 managed,
      uint256 lastChangeBlock,
      address assetManager
    );
}
