/**
 * Copyright 2017-2023, OokiDao. All Rights Reserved.
 * Licensed under the Apache License, Version 2.0.
 */

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

import "@openzeppelin-4.9.3/security/ReentrancyGuard.sol";
import "@openzeppelin-4.9.3/access/Ownable.sol";
import "@openzeppelin-4.9.3/utils/Address.sol";
import "contracts/interfaces/IWeth.sol";
import "contracts/governance/PausableGuardian_0_8.sol";
import "@openzeppelin-4.9.3/token/ERC20/extensions/IERC20Metadata.sol";

abstract contract LoanTokenBase is ReentrancyGuard, Ownable, PausableGuardian_0_8 {
  uint256 internal constant WEI_PRECISION = 10**18;
  uint256 internal constant WEI_PERCENT_PRECISION = 10**20;

  string public name;
  string public symbol;
  uint8 public decimals;

  // uint88 for tight packing -> 8 + 88 + 160 = 256
  uint88 internal lastSettleTime_;

  address public loanTokenAddress;

    uint256 internal internalBalanceOf;
    uint256 internal rateMultiplier_UNUSED;
    uint256 internal lowUtilBaseRate_UNUSED;
    uint256 internal lowUtilRateMultiplier_UNUSED;
    uint256 internal targetLevel_UNUSED;
    uint256 internal kinkLevel_UNUSED;
    uint256 internal maxScaleRate_UNUSED;

  uint256 internal _flTotalAssetSupply;
  uint256 internal checkpointSupply_UNUSED;
  uint256 public initialPrice;

  mapping(uint256 => bytes32) public loanParamsIds_DEPRECATED; // mapping of keccak256(collateralToken, isTorqueLoan) to loanParamsId
  mapping(address => uint256) internal checkpointPrices_DEPRECATED; // price of token at last user checkpoint
}
