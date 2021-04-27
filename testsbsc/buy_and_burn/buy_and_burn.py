#!/usr/bin/python3

import pytest
from brownie import reverts


tokens = [
   "0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c", # BNB
   "0xe9e7CEA3DedcA5984780Bafc599bD69ADd087D56", # BUSD
   "0x2170ed0880ac9a755fd29b2688956bd959f933f8", # ETH
   "0x55d398326f99059ff775485246999027b3197955", # USDT
   "0x7130d2a12b9bcbfae4f2634d864a1ee1ce3ead9c", # BTC
   "0xf8a0bf9cf54bb92f17374d9e9a321e6a111a51bd", # LINK
   #"0x4b87642AEDF10b642BE4663Db842Ecc5A88bf5ba", # BZRX
   #"0x8ac76a51cc950d9822d68b83fe1ad97b32cd580d", # USDC
   #"0x1af3f329e8be154074d8769d1ffa4ee058b1dbc3", # DAI
]


def test_main_flow(requireBscFork, accounts, BGOV, BZX, FEE_EXTRACTOR_BSC):
   bgovPoolAddress = "0x0000000000000000000000000000000000000001";
   bgovBalance = BGOV.balanceOf(bgovPoolAddress)
   BZX.transferOwnership(accounts[0], {'from': "0xB7F72028D9b502Dc871C444363a7aC5A52546608"})
   FEE_EXTRACTOR_BSC.togglePause(True)

   FEE_EXTRACTOR_BSC.setFundsWallet(accounts[0],  {'from':accounts[0]})
   FEE_EXTRACTOR_BSC.setBurnPercent(80e18,  {'from':accounts[0]})

   FEE_EXTRACTOR_BSC.setFeeTokens(tokens,  {'from':accounts[0]})
   BZX.setFeesController(FEE_EXTRACTOR_BSC, {'from':accounts[0]})

   balanceBefore = accounts[0].balance();
   assert (balanceBefore/1e18 == 100)
   assert (accounts[1].balance()/1e18 == 100)

   tx1 = FEE_EXTRACTOR_BSC.sweepFees(50e18, {'from': accounts[0]})
   fees50 = accounts[0].balance() - balanceBefore
   tx1 = FEE_EXTRACTOR_BSC.sweepFees(100e18, {'from': accounts[0]})
   fees100 = (accounts[0].balance() - balanceBefore)
   assert (round(fees50/1e18) == round(fees100/1e18/2))
   assert (accounts[1].balance()/1e18 == 100)

   FEE_EXTRACTOR_BSC.togglePause(False)
   tx2 = FEE_EXTRACTOR_BSC.sweepFees(50e18, {'from': accounts[1]})
   assert (accounts[0].balance() > balanceBefore)
   assert (accounts[1].balance()/1e18 == 100)
   assert (BGOV.balanceOf(bgovPoolAddress) > bgovBalance)

def test_negative(requireBscFork, accounts, BZX, FEE_EXTRACTOR_BSC):
   FEE_EXTRACTOR_BSC.togglePause(True)
   FEE_EXTRACTOR_BSC.setFundsWallet(accounts[0],  {'from':accounts[0]})
   FEE_EXTRACTOR_BSC.setBurnPercent(80e18,  {'from':accounts[0]})
   FEE_EXTRACTOR_BSC.setFeeTokens(tokens,  {'from':accounts[0]})
   BZX.setFeesController(FEE_EXTRACTOR_BSC, {'from':accounts[0]})

   with reverts("BGOV not supported"):
      FEE_EXTRACTOR_BSC.sweepFeesByAsset(["0xf8E026dC4C0860771f691ECFFBbdfe2fa51c77Cf"], 0, {'from': accounts[0]})

   if(BZX.owner() != accounts[0]):
      BZX.transferOwnership(accounts[0], {'from': "0xB7F72028D9b502Dc871C444363a7aC5A52546608"})

   with reverts("value too high"):
      FEE_EXTRACTOR_BSC.setBurnPercent(2**256-1,  {'from':accounts[0]})

   FEE_EXTRACTOR_BSC.togglePause(True)
   with reverts("paused"):
      FEE_EXTRACTOR_BSC.sweepFeesByAsset(["0x1af3f329e8be154074d8769d1ffa4ee058b1dbc3"], 0, {'from': accounts[1]})

   FEE_EXTRACTOR_BSC.togglePause(False)

   with reverts("unauthorized"):
      FEE_EXTRACTOR_BSC.setFundsWallet(accounts[1],  {'from':accounts[1]})


   with reverts("unauthorized"):
      FEE_EXTRACTOR_BSC.setBurnPercent(80e18,  {'from':accounts[1]})


   with reverts("unauthorized"):
      FEE_EXTRACTOR_BSC.setFeeTokens(tokens,  {'from':accounts[1]})

   with reverts("unauthorized"):
      BZX.setFeesController(FEE_EXTRACTOR_BSC,  {'from':accounts[1]})

   with reverts("unauthorized"):
      BZX.withdrawFees(tokens, accounts[1], 0, {'from':accounts[1]})



