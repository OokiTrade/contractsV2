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

    uint256 internal baseRate_UNUSED;
    uint256 internal rateMultiplier_UNUSED;
    uint256 internal lowUtilBaseRate_UNUSED;
    uint256 internal lowUtilRateMultiplier_UNUSED;
    uint256 internal targetLevel_UNUSED;
    uint256 internal kinkLevel_UNUSED;
    uint256 internal maxScaleRate_UNUSED;

    uint256 internal _flTotalAssetSupply;
    uint256 public checkpointSupply;
    uint256 public initialPrice;

    mapping (uint256 => bytes32) public loanParamsIds; // mapping of keccak256(collateralToken, isTorqueLoan) to loanParamsId
    mapping (address => uint256) internal checkpointPrices_; // price of token at last user checkpoint

    bytes32 public DOMAIN_SEPARATOR;

    // keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)");
    bytes32 public constant PERMIT_TYPEHASH = 0x6e71edae12b1b97f4d1f60370fef10105fa2faae0126114a169c64845d6126c9;

    mapping(address => uint256) public nonces;

    uint256 chainId;
}