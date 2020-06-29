/**
 * Copyright 2017-2020, bZeroX, LLC. All Rights Reserved.
 * Licensed under the Apache License, Version 2.0.
 */

pragma solidity 0.5.17;

import "../../openzeppelin/SafeMath.sol";
import "../../openzeppelin/ReentrancyGuard.sol";
import "../../openzeppelin/Ownable.sol";
import "../../openzeppelin/Address.sol";
import "../../interfaces/IWethERC20.sol";


contract LoanTokenBase is ReentrancyGuard, Ownable {

    string public name;
    string public symbol;
    uint8 public decimals;

    address public loanTokenAddress;

    uint256 public baseRate;
    uint256 public rateMultiplier;
    uint256 public lowUtilBaseRate;
    uint256 public lowUtilRateMultiplier;

    uint256 internal _flTotalAssetSupply;
    uint256 public checkpointSupply;
    uint256 public initialPrice;

    uint256 internal lastSettleTime_;

    mapping (uint256 => bytes32) public loanParamsIds; // mapping of keccak256(collateralToken, isTorqueLoan) to loanParamsId
    mapping (address => uint256) internal checkpointPrices_; // price of token at last user checkpoint
}