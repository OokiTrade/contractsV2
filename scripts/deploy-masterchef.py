
import pytest
import time
from brownie import *
from brownie import Contract, network
from brownie.network.contract import InterfaceContainer
from brownie.network.state import _add_contract, _remove_contract


WBNB = Contract.from_abi("USDT", "0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c", TestToken.abi)
ETH = Contract.from_abi("USDT", "0x2170ed0880ac9a755fd29b2688956bd959f933f8", TestToken.abi)
BUSD = Contract.from_abi("BUSD", "0xe9e7cea3dedca5984780bafc599bd69add087d56", TestToken.abi)
WBTC = Contract.from_abi("USDT", "0x7130d2a12b9bcbfae4f2634d864a1ee1ce3ead9c", TestToken.abi)
USDT = Contract.from_abi("USDT", "0x55d398326f99059ff775485246999027b3197955", TestToken.abi)


bzx = Contract.from_abi("bzx", address="0xc47812857a74425e2039b57891a3dfcf51602d5d",
                        abi=interface.IBZx.abi, owner=accounts[0])

iWBNBAddress = bzx.underlyingToLoanPool(WBNB)
iETHAddress = bzx.underlyingToLoanPool(ETH)
iBUSDAddress = bzx.underlyingToLoanPool(BUSD)
iWBTCAddress = bzx.underlyingToLoanPool(WBTC)
iUSDTAddress = bzx.underlyingToLoanPool(USDT)


iWBNB = Contract.from_abi("iWBNB", address=iWBNBAddress, abi=LoanTokenLogicWeth.abi, owner=accounts[0])
iETH = Contract.from_abi("iETH", address=iETHAddress, abi=LoanTokenLogicStandard.abi, owner=accounts[0])
iBUSD = Contract.from_abi("iBUSD", address=iBUSDAddress, abi=LoanTokenLogicStandard.abi, owner=accounts[0])
iWBTC = Contract.from_abi("iWBTC", address=iWBTCAddress, abi=LoanTokenLogicStandard.abi, owner=accounts[0])
iUSDT = Contract.from_abi("iUSDT", address=iUSDTAddress, abi=LoanTokenLogicStandard.abi, owner=accounts[0])


bgovToken = accounts[0].deploy(BGovToken)


# TODO @Tom farm configuration
devAccount = accounts[0]  # @Tom this account will receive small fees check updatePool() func
bgovPerBlock = 100*10**18
bonusEndBlock = chain.height + 1*10**6
startBlock = chain.height

masterChef = accounts[0].deploy(MasterChef, bgovToken, devAccount, bgovPerBlock, startBlock, bonusEndBlock)
bgovToken.transferOwnership(masterChef)
# TODO @Tom all pools equal allocation point right now
# from chef: // Total allocation poitns. Must be the sum of all allocation points in all pools.
# aloso allocation points should consider price difference. depositing 1 iWBTC should be approximately equal to depositing 55k iBUSD

allocPoint = 100
masterChef.add(allocPoint, iWBNB, 1)
masterChef.add(allocPoint, iETH, 1)
masterChef.add(allocPoint, iBUSD, 1)
masterChef.add(allocPoint, iWBTC, 1)
masterChef.add(allocPoint, iUSDT, 1)
