Test are run with: `brownie test` command
Test coverage is run with: `brownie test --coverage` command

  contract: LoanClosings - 50.2%
    FeesHelper._getTradingFee - 100.0%
    InterestUser._payInterestTransfer - 100.0%
    LoanClosings.closeWithDeposit - 100.0%
    LoanClosings.closeWithSwap - 100.0%
    LoanClosings.initialize - 100.0%
    LoanClosings.liquidate - 100.0%
    SwapsUser._loanSwap - 100.0%
    SwapsUser._swapsCall_internal - 100.0%
    LoanClosingsBase._emitClosingEvents - 87.5%
    LoanClosingsBase._finalizeClose - 83.3%
    FeesHelper._payLendingFee - 75.0%
    FeesHelper._payTradingFee - 75.0%
    FeesHelper._settleFeeRewardForInterestExpense - 75.0%
    LoanClosings.rollover - 75.0%
    LoanClosingsBase._doCollateralSwap - 75.0%
    VaultController.vaultWithdraw - 75.0%
    LoanClosingsBase._closeWithSwap - 70.8%
    LoanClosingsBase._closeWithDeposit - 70.0%
    LoanClosingsBase._checkAuthorized - 66.7%
    LoanClosingsBase._settleInterest - 64.3%
    LoanClosingsBase._liquidate - 61.9%
    InterestUser._payInterest - 60.7%
    State._setTarget - 58.3%
    SwapsUser._checkSwapSize - 58.3%
    LoanClosingsBase._withdrawAsset - 50.0%
    VaultController.vaultTransfer - 50.0%
    SwapsUser._swapsCall - 49.9%
    LoanClosingsBase._coverPrincipalWithSwap - 43.8%
    LoanClosingsBase._settleInterestToPrincipal - 43.8%
    LoanClosingsBase._closeLoan - 40.0%
    LoanClosingsBase._returnPrincipalWithDeposit - 22.6%
    LiquidationHelper._getLiquidationAmounts - 20.6%
    FeesHelper._payFeeReward - 8.3%
    LoanClosingsBase._rollover - 8.3%
    LoanClosingsBase._getRebate - 0.0%
    LoanClosingsBase._rolloverEvent - 0.0%
    VaultController.vaultEtherWithdraw - 0.0%

  contract: LoanMaintenance - 45.1%
    InterestUser._payInterestTransfer - 100.0%
    LoanMaintenance.getLoan - 100.0%
    LoanMaintenance.initialize - 100.0%
    LoanMaintenance.withdrawAccruedInterest - 100.0%
    LoanMaintenance.withdrawCollateral - 77.5%
    FeesHelper._payLendingFee - 75.0%
    FeesHelper._settleFeeRewardForInterestExpense - 75.0%
    LoanMaintenance.getLoanInterestData - 75.0%
    VaultController.vaultWithdraw - 75.0%
    InterestUser._payInterest - 74.1%
    LoanMaintenance.reduceLoanDuration - 69.6%
    LoanMaintenance.getLenderInterestData - 58.3%
    State._setTarget - 58.3%
    LoanMaintenance.depositCollateral - 46.7%
    LoanMaintenance.getUserLoans - 45.0%
    LoanMaintenance.getActiveLoans - 43.8%
    LoanMaintenance.extendLoanDuration - 32.5%
    LoanMaintenance._getLoan - 30.4%
    FeesHelper._payFeeReward - 8.3%
    FeesHelper._getTradingFee - 0.0%
    FeesHelper._payTradingFee - 0.0%
    LoanMaintenance._doSwapWithCollateral - 0.0%
    LoanMaintenance.claimRewards - 0.0%
    LoanMaintenance.getActiveLoansCount - 0.0%
    LoanMaintenance.getUserLoansCount - 0.0%
    VaultController.vaultDeposit - 0.0%
    VaultController.vaultEtherDeposit - 0.0%
    VaultController.vaultEtherWithdraw - 0.0%

  contract: LoanOpenings - 68.7%
    FeesHelper._getBorrowingFee - 100.0%
    FeesHelper._getTradingFee - 100.0%
    InterestUser._payInterestTransfer - 100.0%
    LoanOpenings._emitOpeningEvents - 100.0%
    LoanOpenings._setDelegatedManager - 100.0%
    LoanOpenings.initialize - 100.0%
    LoanOpenings.setDelegatedManager - 100.0%
    SwapsUser._loanSwap - 100.0%
    SwapsUser._swapsCall_internal - 100.0%
    LoanOpenings._borrowOrTrade - 92.9%
    LoanOpenings._finalizeOpen - 87.5%
    LoanOpenings._getRequiredCollateral - 87.5%
    LoanOpenings._initializeLoan - 84.3%
    LoanOpenings._initializeInterest - 83.9%
    LoanOpenings.getRequiredCollateral - 81.2%
    FeesHelper._payBorrowingFee - 75.0%
    FeesHelper._payLendingFee - 75.0%
    FeesHelper._payTradingFee - 75.0%
    VaultController.vaultWithdraw - 75.0%
    InterestUser._payInterest - 74.1%
    LoanOpenings.borrowOrTradeFromPool - 65.7%
    LoanOpenings.getBorrowAmount - 62.5%
    State._setTarget - 58.3%
    SwapsUser._checkSwapSize - 58.3%
    SwapsUser._swapsCall - 41.9%
    FeesHelper._settleFeeRewardForInterestExpense - 41.7%
    LoanOpenings._isCollateralSatisfied - 37.5%
    FeesHelper._payFeeReward - 8.3%
    LoanOpenings.getBorrowAmountByParams - 0.0%
    LoanOpenings.getEstimatedMarginExposure - 0.0%
    LoanOpenings.getRequiredCollateralByParams - 0.0%
    SwapsUser._swapsExpectedReturn - 0.0%

  contract: LoanSettings - 85.8%
    LoanSettings._setupLoanParams - 100.0%
    LoanSettings.disableLoanParams - 100.0%
    LoanSettings.getTotalPrincipal - 100.0%
    LoanSettings.initialize - 100.0%
    LoanSettings.setupLoanParams - 100.0%
    LoanSettings.getLoanParams - 66.7%
    LoanSettings.getLoanParamsList - 58.3%
    State._setTarget - 58.3%

  contract: ProtocolSettings - 50.3%
    ProtocolSettings.initialize - 100.0%
    ProtocolSettings.isLoanPool - 100.0%
    ProtocolSettings.setAffiliateFeePercent - 100.0%
    ProtocolSettings.setBorrowingFeePercent - 100.0%
    ProtocolSettings.setFeesController - 100.0%
    ProtocolSettings.setLendingFeePercent - 100.0%
    ProtocolSettings.setMaxDisagreement - 100.0%
    ProtocolSettings.setMaxSwapSize - 100.0%
    ProtocolSettings.setPriceFeedContract - 100.0%
    ProtocolSettings.setSourceBufferPercent - 100.0%
    ProtocolSettings.setSupportedTokens - 100.0%
    ProtocolSettings.setSwapsImplContract - 100.0%
    ProtocolSettings.setTradingFeePercent - 100.0%
    ProtocolSettings.setLoanPool - 85.7%
    ProtocolSettings.setLiquidationIncentivePercent - 83.3%
    ProtocolSettings.getLoanPoolsList - 79.2%
    State._setTarget - 58.3%
    ProtocolSettings.withdrawFees - 4.8%
    ProtocolSettings.depositProtocolToken - 0.0%
    ProtocolSettings.grantRewards - 0.0%
    ProtocolSettings.queryFees - 0.0%
    ProtocolSettings.withdrawProtocolToken - 0.0%

  contract: SwapsImplTestnets - 62.8%
    SwapsImplTestnets.dexSwap - 70.0%
    SwapsImplTestnets.dexExpectedRate - 0.0%

  contract: TokenRegistry - 100.0%
    TokenRegistry.getTokens - 100.0%
