/**
 * Copyright 2017-2022, OokiDao. All Rights Reserved.
 * Licensed under the Apache License, Version 2.0.
 */

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

import './LoanTokenLogicStandard.sol';

contract LoanTokenLogicWeth is LoanTokenLogicStandard {
  constructor(
    address arbCaller,
    address bzxcontract,
    address wethtoken
  ) LoanTokenLogicStandard(arbCaller, bzxcontract, wethtoken) {}

  function redeemToEther(
    uint256 assets,
    address payable receiver,
    address owner
  ) external payable nonReentrant returns (uint256 shares) {
    shares = _redeemToken(assets, receiver, owner);

    if (shares != 0) {
      IWeth(wethToken).withdraw(assets);
      Address.sendValue(receiver, assets);
    }
  }

  function withdrawToEther(
    uint256 shares,
    address payable receiver,
    address owner
  ) external nonReentrant returns (uint256 assets) {
    assets = _withdrawToken(shares, receiver, owner);

    if (assets != 0) {
      IWeth(wethToken).withdraw(assets);
      Address.sendValue(receiver, assets);
    }
  }

  /* Internal functions */

  // sentAddresses[0]: lender
  // sentAddresses[1]: borrower
  // sentAddresses[2]: receiver
  // sentAddresses[3]: manager
  // sentAmounts[0]: interestRate
  // sentAmounts[1]: newPrincipal
  // sentAmounts[2]: interestInitialAmount
  // sentAmounts[3]: loanTokenSent
  // sentAmounts[4]: collateralTokenSent
  function _verifyTransfers(
    address collateralTokenAddress,
    address[4] memory sentAddresses,
    uint256[5] memory sentAmounts,
    uint256 withdrawalAmount,
    bytes memory loanDataBytes
  ) internal override returns (uint256 msgValue, bytes memory) {
    address _wethToken = wethToken;
    address _loanTokenAddress = _wethToken;
    address receiver = sentAddresses[2];
    uint256 newPrincipal = sentAmounts[1];
    uint256 loanTokenSent = sentAmounts[3];
    uint256 collateralTokenSent = sentAmounts[4];

    require(_loanTokenAddress != collateralTokenAddress, '26');

    msgValue = msg.value;

    if (withdrawalAmount != 0) {
      // withdrawOnOpen == true
      IWeth(_wethToken).withdraw(withdrawalAmount);
      Address.sendValue(payable(address(uint160(receiver))), withdrawalAmount);
      if (newPrincipal > withdrawalAmount) {
        _safeTransfer(
          _loanTokenAddress,
          bZxContract,
          newPrincipal - withdrawalAmount,
          '27'
        );
      }
    } else {
      _safeTransfer(_loanTokenAddress, bZxContract, newPrincipal, '27');
    }

    if (collateralTokenSent != 0) {
      loanDataBytes = _checkPermit(collateralTokenAddress, loanDataBytes);
      _safeTransferFrom(
        collateralTokenAddress,
        msg.sender,
        bZxContract,
        collateralTokenSent,
        '28'
      );
    }

    if (loanTokenSent != 0) {
      if (msgValue != 0 && msgValue >= loanTokenSent) {
        IWeth(_wethToken).deposit{ value: loanTokenSent }();
        _safeTransfer(_loanTokenAddress, bZxContract, loanTokenSent, '29');
        msgValue -= loanTokenSent;
      } else {
        loanDataBytes = _checkPermit(_loanTokenAddress, loanDataBytes);
        _safeTransferFrom(
          _loanTokenAddress,
          msg.sender,
          bZxContract,
          loanTokenSent,
          '29'
        );
      }
    }
    return (msgValue, loanDataBytes);
  }
}
