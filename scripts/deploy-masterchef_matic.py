
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

tokens.weth = Contract.from_abi("WETH", "0x7ceB23fD6bC0adD59E62ac25578270cFf1b9f619", TestWeth.abi)
tokens.wbtc = Contract.from_abi("WBTC", "0x1BFD67037B42Cf73acF2047067bd4F2C47D9BfD6", TestToken.abi)
tokens.usdc = Contract.from_abi("USDC", "0x2791Bca1f2de4661ED88A30C99A7a9449Aa84174", TestToken.abi)
tokens.usdt = Contract.from_abi("USDT", "0xc2132D05D31c914a87C6611C10748AEb04B58e8F", TestToken.abi)
tokens.dai = Contract.from_abi("DAI", "0x8f3Cf7ad23Cd3CaDbD9735AFf958023239c6A063", TestToken.abi)
tokens.wmatic = Contract.from_abi("WMATIC", "0x0d500B1d8E8eF31E21C99d1Db9A6444d3ADf1270", TestToken.abi)
tokens.link = Contract.from_abi("LINK", "0xb0897686c545045afc77cf20ec7a532e3120e0f1", TestToken.abi)


itokens.weth = Contract.from_abi("iWETH", bzx.underlyingToLoanPool(tokens.weth), TestWeth.abi)
itokens.wbtc = Contract.from_abi("iWBTC", bzx.underlyingToLoanPool(tokens.wbtc), TestToken.abi)
itokens.usdc = Contract.from_abi("iUSDC", bzx.underlyingToLoanPool(tokens.usdc), TestToken.abi)
itokens.usdt = Contract.from_abi("iUSDT", bzx.underlyingToLoanPool(tokens.usdt), TestToken.abi)
itokens.dai = Contract.from_abi("iDAI", bzx.underlyingToLoanPool(tokens.dai), TestToken.abi)
itokens.wmatic = Contract.from_abi("iWMATIC", bzx.underlyingToLoanPool(tokens.wmatic), TestToken.abi)
itokens.link = Contract.from_abi("iLINK", bzx.underlyingToLoanPool(tokens.link), TestToken.abi)

# two sided
#PGOV_WMATIC = Contract.from_abi("PGOV_WMATIC", "", interface.IPancakePair.abi)

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

masterChef.add(12500, itokens.weth, 1)
masterChef.add(12500, itokens.wbtc, 1)
masterChef.add(12500, itokens.usdt, 1)
masterChef.add(12500, itokens.usdc, 1)
masterChef.add(12500, itokens.dai, 1)
masterChef.add(87500, itokens.wmatic, 1)
masterChef.add(87500, itokens.link, 1)

print("masterChef: ", masterChef.address)

# two sided
#masterChef.add(100000, PGOV_wMATIC, 1)