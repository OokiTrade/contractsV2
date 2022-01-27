/**
 * Copyright 2017-2022, OokiDao. All Rights Reserved.
 * Licensed under the Apache License, Version 2.0.
 */

pragma solidity 0.5.17;

import "@openzeppelin-2.5.0/math/SafeMath.sol";
import "../../utils/SignedSafeMath.sol";
import "../../utils/ReentrancyGuard.sol";
import "@openzeppelin-2.5.0/ownership/Ownable.sol";
import "@openzeppelin-2.5.0/utils/Address.sol";
import "../../interfaces/IWethERC20.sol";
import "../../governance/PausableGuardian.sol";
import "../../interfaces/ICurvedInterestRate.sol";

contract LoanTokenBase is ReentrancyGuard, Ownable, PausableGuardian {

    uint256 internal constant WEI_PRECISION = 10**18;
    uint256 internal constant WEI_PERCENT_PRECISION = 10**20;

    int256 internal constant sWEI_PRECISION = 10**18;

    string public name;
    string public symbol;
    uint8 public decimals;

    // uint88 for tight packing -> 8 + 88 + 160 = 256
    uint88 internal lastSettleTime_;

    address public loanTokenAddress;

    uint256 public NOT_USDE_baseRate;
    uint256 public IR2;
    uint256 public UR1;
    uint256 public UR2;

    ICurvedInterestRate rateHelper; // TODO uint256 replaced with address probably storage fucked up now
    uint256 public lastIR;
    uint256 public NOT_USDE_maxScaleRate;

    uint256 internal _flTotalAssetSupply;
    uint256 public checkpointSupply;
    uint256 public initialPrice;

    mapping (uint256 => bytes32) public loanParamsIds; // mapping of keccak256(collateralToken, isTorqueLoan) to loanParamsId
    mapping (address => uint256) internal checkpointPrices_; // price of token at last user checkpoint
}