
from brownie.network import account
import pytest
import time
from brownie import *
from brownie import Contract, network
from brownie.network.contract import InterfaceContainer
from brownie.network.state import _add_contract, _remove_contract
from munch import Munch

acct = accounts[0] #accounts.load('deployer1')

bzxProtocol = '0xfe4F0eb0A1Ad109185c9AaDE64C48ff8e928e54B'
tokens = Munch()
itokens = Munch()
bzx = Contract.from_abi("bzx", address=bzxProtocol, abi=interface.IBZx.abi, owner=acct)

MATIC = Contract.from_abi("MATIC", address="0x0d500B1d8E8eF31E21C99d1Db9A6444d3ADf1270", abi=TestToken.abi, owner=acct)
ETH = Contract.from_abi("ETH", address="0x7ceB23fD6bC0adD59E62ac25578270cFf1b9f619", abi=TestToken.abi, owner=acct)
WBTC = Contract.from_abi("WBTC", address="0x1BFD67037B42Cf73acF2047067bd4F2C47D9BfD6", abi=TestToken.abi, owner=acct)
LINK = Contract.from_abi("LINK", address="0xb0897686c545045afc77cf20ec7a532e3120e0f1", abi=TestToken.abi, owner=acct)
USDC = Contract.from_abi("USDC", address="0x2791Bca1f2de4661ED88A30C99A7a9449Aa84174", abi=TestToken.abi, owner=acct)
USDT = Contract.from_abi("USDT", address="0xc2132D05D31c914a87C6611C10748AEb04B58e8F", abi=TestToken.abi, owner=acct)
AAVE = Contract.from_abi("AAVE", address="0xD6DF932A45C0f255f85145f286eA0b292B21C90B", abi=TestToken.abi, owner=acct)
BZRX = Contract.from_abi("BZRX", address="0x97dfbEF4eD5a7f63781472Dbc69Ab8e5d7357cB9", abi=TestToken.abi, owner=acct)


iMATIC = Contract.from_abi("iMATIC", address=MATIC.address, abi=LoanTokenLogicWeth.abi, owner=acct)
iETH = Contract.from_abi("iETH", address=ETH.address, abi=LoanTokenLogicStandard.abi, owner=acct)
iWBTC = Contract.from_abi("iWBTC", address=WBTC.address, abi=LoanTokenLogicStandard.abi, owner=acct)
iLINK = Contract.from_abi("iLINK", address=LINK.address, abi=LoanTokenLogicStandard.abi, owner=acct)
iUSDC = Contract.from_abi("iUSDC", address=USDC.address, abi=LoanTokenLogicStandard.abi, owner=acct)
iUSDT = Contract.from_abi("iUSDT", address=USDT.address, abi=LoanTokenLogicStandard.abi, owner=acct)
iAAVE = Contract.from_abi("iAAVE", address=AAVE.address, abi=LoanTokenLogicStandard.abi, owner=acct)
iBZRX = Contract.from_abi("iBZRX", address=AAVE.address, abi=LoanTokenLogicStandard.abi, owner=acct)

QUICKROUTER = Contract.from_abi("router", "0xa5E0829CaCEd8fFDD4De3c43696c57F7D7A678ff", interface.IPancakeRouter02.abi)


# two sided
USDT_WMATIC = Contract.from_abi("USDT_WMATIC", "0x604229c960e5cacf2aaeac8be68ac07ba9df81c3", interface.IPancakePair.abi)

pgovToken = acct.deploy(PGovToken)

# TODO @Tom farm configuration
devAccount = acct  # @Tom this account will receive small fees check updatePool() func
pgovPerBlock = 25*10**18
bonusEndBlock = chain.height + 400000
startBlock = chain.height

masterChefImpl = acct.deploy(MasterChef_POLYGON)
masterChefProxy = acct.deploy(Proxy, masterChefImpl)
masterChef = Contract.from_abi("masterChef", address=masterChefProxy, abi=MasterChef_POLYGON.abi, owner=acct)

masterChef.initialize(pgovToken, devAccount, pgovPerBlock, startBlock, bonusEndBlock)

#PGOV_wBNB = Contract.from_abi("PGOV_wMATIC", "0xEcd0aa12A453AE356Aba41f62483EDc35f2290ed", interface.IPancakePair.abi)

# from chef: // Total allocation poitns. Must be the sum of all allocation points in all pools.
# aloso allocation points should consider price difference. depositing 1 iWBTC should be approximately equal to depositing 55k iBUSD

# adding allocation points according to what was disscussed

# Here are the params and initial pool weights for our starting farms:
# _PGOVPerBlock: 25000000000000000000
# _startBlock: TBD (early next week)
# _bonusEndBlock: _startBlock + 400000

# allocPoints per pool:
# 12500 - iBNB, iBUSD, iBTC, iUSDT, iETH  
# 87500 - iBZRX
# 100000 - PGOV/BNB

masterChef.add(12500, ETH, 1)
masterChef.add(12500, WBTC, 1)
masterChef.add(12500, USDT, 1)
masterChef.add(12500, USDC, 1)
masterChef.add(12500, LINK, 1)
masterChef.add(87500, MATIC, 1)

masterChef.add(87500, pgovToken, 1)

print("masterChef: ", masterChef.address)

# two sided
masterChef.add(100000, USDT_WMATIC, 1)

exec(open("./scripts/set-env-polygon.py").read())