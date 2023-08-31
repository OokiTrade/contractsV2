/**
 * Copyright 2017-2023, OokiDao. All Rights Reserved.
 * Licensed under the Apache License, Version 2.0.
 */

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

import "contracts/connectors/loantoken/LoanTokenLogicStandard.sol";
import "interfaces/ILoanTokenFactory.sol";
import "interfaces/IBZx.sol";
import "@openzeppelin-4.9.3/token/ERC20/utils/SafeERC20.sol";

contract ITokenFactory {
  using SafeERC20 for IERC20;
  modifier onlyFactory() {
    // require(msg.sender == _getFactory(), "not factory");
    _;
  }

  // constructor(
  //   address arbCaller,
  //   address bzxcontract,
  //   address wethtoken
  // ) LoanTokenLogicStandard(arbCaller, bzxcontract, wethtoken) {}

  // function initialize(
  //   address _loanTokenAddress,
  //   string memory _name,
  //   string memory _symbol
  // ) public override onlyFactory {
  //   loanTokenAddress = _loanTokenAddress;

  //   name = _name;
  //   symbol = _symbol;
  //   decimals = IERC20Metadata(loanTokenAddress).decimals();

  //   initialPrice = WEI_PRECISION; // starting price of 1

  //   IERC20(_loanTokenAddress).safeApprove(bZxContract, type(uint256).max);
  // }

  // function setDemandCurve(ICurvedInterestRate _rateHelper) public {} //overrides LoanTokenLogicStandard

  // function updateFlashBorrowFeePercent(uint256 newFeePercent) public {} //overrides LoanTokenLogicStandard

  // function _getRateHelper() internal view override returns (ICurvedInterestRate) {
  //   return ICurvedInterestRate(ILoanTokenFactory(_getFactory()).getRateHelper());
  // }

  // function _getFactory() internal view returns (address) {
  //   return IBZx(bZxContract).factory();
  // }

  // function _getFlashLoanFee() internal view override returns (uint256) {
  //   ILoanTokenFactory(_getFactory()).getFlashLoanFeePercent();
  // }
}
