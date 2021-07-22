#!/usr/bin/python3

import pytest
from brownie import reverts


tokens = [
   "0xD6DF932A45C0f255f85145f286eA0b292B21C90B", # AAVE
   "0x54cFe73f2c7d0c4b62Ab869B473F5512Dc0944D2", # BZRX
   "0x7ceB23fD6bC0adD59E62ac25578270cFf1b9f619", # ETH
   "0x53E0bca35eC356BD5ddDFebbD1Fc0fD03FaBad39", # LINK
   "0x0d500B1d8E8eF31E21C99d1Db9A6444d3ADf1270", # MATIC
   "0x2791Bca1f2de4661ED88A30C99A7a9449Aa84174", # USDC
   "0xc2132D05D31c914a87C6611C10748AEb04B58e8F", # USDT
   "0x1BFD67037B42Cf73acF2047067bd4F2C47D9BfD6", # WBTC
   #"0x1af3f329e8be154074d8769d1ffa4ee058b1dbc3", # DAI
]


def test_main_flow(requireFork, accounts, GOV, BZX, FEE_EXTRACTOR_MATIC):

   govPoolAddress = "0x0000000000000000000000000000000000000001";
   bgovBalance = GOV.balanceOf(govPoolAddress)
   BZX.transferOwnership(accounts[0], {'from': "0xB7F72028D9b502Dc871C444363a7aC5A52546608"})
   FEE_EXTRACTOR_MATIC.togglePause(True)

   FEE_EXTRACTOR_MATIC.setFundsWallet(accounts[1],  {'from':accounts[0]})


   FEE_EXTRACTOR_MATIC.setFeeTokens(tokens,  {'from':accounts[0]})
   BZX.setFeesController(FEE_EXTRACTOR_MATIC, {'from':accounts[0]})

   balanceBefore = accounts[0].balance()
   assert (balanceBefore/1e18 == 100)
   assert (accounts[1].balance()/1e18 == 100)
   tx1 = FEE_EXTRACTOR_MATIC.sweepFees({'from': accounts[0]})
   # manually checked tx.info() contains Transfer to zero address


def test_negative(requireFork, accounts, BZX, FEE_EXTRACTOR_MATIC, GOV):
   FEE_EXTRACTOR_MATIC.togglePause(True)
   FEE_EXTRACTOR_MATIC.setFundsWallet(accounts[0],  {'from':accounts[0]})
   FEE_EXTRACTOR_MATIC.setFeeTokens(tokens,  {'from':accounts[0]})
   BZX.setFeesController(FEE_EXTRACTOR_MATIC, {'from':accounts[0]})

   with reverts("asset not supported"):
      FEE_EXTRACTOR_MATIC.sweepFeesByAsset([GOV], {'from': accounts[0]})

   if(BZX.owner() != accounts[0]):
      BZX.transferOwnership(accounts[0], {'from': "0xB7F72028D9b502Dc871C444363a7aC5A52546608"})

   FEE_EXTRACTOR_MATIC.togglePause(True)
   with reverts("paused"):
      FEE_EXTRACTOR_MATIC.sweepFeesByAsset([GOV], {'from': accounts[1]})

   FEE_EXTRACTOR_MATIC.togglePause(False)

   with reverts("Ownable: caller is not the owner"):
      FEE_EXTRACTOR_MATIC.setFundsWallet(accounts[1],  {'from':accounts[1]})


   with reverts("Ownable: caller is not the owner"):
      FEE_EXTRACTOR_MATIC.setFeeTokens(tokens,  {'from':accounts[1]})

   with reverts("unauthorized"):
      BZX.setFeesController(FEE_EXTRACTOR_MATIC,  {'from':accounts[1]})

   with reverts("unauthorized"):
      BZX.withdrawFees(tokens, accounts[1], 0, {'from':accounts[1]})



