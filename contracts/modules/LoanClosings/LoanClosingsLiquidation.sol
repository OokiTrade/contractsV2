/**
 * Copyright 2017-2023, OokiDao. All Rights Reserved.
 * Licensed under the Apache License, Version 2.0.
 */

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

import "contracts/modules/LoanClosings/LoanClosingsShared.sol";
import "contracts/mixins/LiquidationHelper.sol";

contract LoanClosingsLiquidation is LoanClosingsShared {
  function initialize(address target) external onlyOwner {
    _setTarget(this.liquidate.selector, target);
  }

  function liquidate(
    bytes32 loanId,
    address receiver,
    uint256 closeAmount // denominated in loanToken
  )
    external
    payable
    nonReentrant
    returns (
      uint256 loanCloseAmount,
      uint256 seizedAmount,
      address seizedToken
    )
  {
    return _liquidate(loanId, receiver, closeAmount);
  }

  function _liquidate(
    bytes32 loanId,
    address receiver,
    uint256 closeAmount
  )
    internal
    pausable
    returns (
      uint256 loanCloseAmount,
      uint256 seizedAmount,
      address seizedToken
    )
  {
    Loan memory loanLocal = loans[loanId];
    require(loanLocal.active, "loan is closed");

    LoanParams memory loanParamsLocal = loanParams[loanLocal.loanParamsId];

    uint256 principalPlusInterest = _settleInterest(loanLocal.lender, loanId) + loanLocal.principal;

    (uint256 currentMargin, uint256 collateralToLoanRate) = _getCurrentMargin(
      loanParamsLocal.loanToken,
      loanParamsLocal.collateralToken,
      principalPlusInterest,
      loanLocal.collateral,
      false // silentFail
    );
    require(currentMargin <= loanParamsLocal.maintenanceMargin, "healthy position");

    if (receiver == address(0)) {
      receiver = msg.sender;
    }

    loanCloseAmount = closeAmount;

    (uint256 maxLiquidatable, uint256 maxSeizable) = LiquidationHelper.getLiquidationAmounts(
      principalPlusInterest,
      loanLocal.collateral,
      currentMargin,
      loanParamsLocal.maintenanceMargin,
      collateralToLoanRate,
      liquidationIncentivePercent[loanParamsLocal.loanToken][loanParamsLocal.collateralToken]
    );

    if (loanCloseAmount < maxLiquidatable) {
      seizedAmount = (maxSeizable * loanCloseAmount) / maxLiquidatable;
    } else {
      if (loanCloseAmount > maxLiquidatable) {
        // adjust down the close amount to the max
        loanCloseAmount = maxLiquidatable;
      }
      seizedAmount = maxSeizable;
    }

    require(loanCloseAmount != 0, "nothing to liquidate");

    // liquidator deposits the principal being closed
    _returnPrincipalWithDeposit(loanParamsLocal.loanToken, loanLocal.lender, loanCloseAmount);

    seizedToken = loanParamsLocal.collateralToken;

    if (seizedAmount != 0) {
      loanLocal.collateral -= seizedAmount;

      _withdrawAsset(seizedToken, receiver, seizedAmount);
    }

    _emitClosingEvents(
      loanParamsLocal,
      loanLocal,
      loanCloseAmount,
      seizedAmount,
      collateralToLoanRate,
      0, // collateralToLoanSwapRate
      currentMargin,
      CloseTypes.Liquidation
    );

    _closeLoan(loanLocal, loanParamsLocal.loanToken, loanCloseAmount);
  }
}
