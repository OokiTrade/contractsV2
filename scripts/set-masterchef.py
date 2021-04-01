
import pytest
import time
from brownie import *
from brownie import Contract, network
from brownie.network.contract import InterfaceContainer
from brownie.network.state import _add_contract, _remove_contract


# bgovToken = myAccout.deploy(BGovToken)


# # TODO @Tom farm configuration
# devAccount = myAccout
# bgovPerBlock = 100*10**18
# bonusEndBlock = chain.height + 1*10**6
# startBlock = chain.height

# masterChef = myAccout.deploy(MasterChef, bgovToken, devAccount, bgovPerBlock, startBlock, bonusEndBlock)
# bgovToken.transferOwnership(masterChef)
# # TODO @Tom all pools equal allocation point right now
# # from chef: // Total allocation poitns. Must be the sum of all allocation points in all pools.
# # aloso allocation points should consider price difference. depositing 1 iWBTC should be approximately equal to depositing 55k iBUSD

# allocPoint = 100
# masterChef.add(allocPoint, iWBNB, 1)
# masterChef.add(allocPoint, iETH, 1)
# masterChef.add(allocPoint, iBUSD, 1)
# masterChef.add(allocPoint, iWBTC, 1)
# masterChef.add(allocPoint, iUSDT, 1)


myAccout = accounts[0]


# mint iWBNB
amount = 10000*10**18
accounts[1].transfer(to=myAccout, amount=Wei('100 ether'))
iWBNB.mintWithEther(myAccout, {'from': myAccout, 'value': Wei('90 ether')})
iWBNB.approve(masterChef, 2**256-1, {'from': myAccout})
masterChef.deposit(0, 10*10**18, {'from': myAccout})


# mint ETH and iETH
amount = 10000*10**18
ETH.transfer(myAccout, amount, {'from': "0xf508fcd89b8bd15579dc79a6827cb4686a3592c8"})
ETH.approve(iETH, 2**256-1, {'from': myAccout})
iETH.mint(myAccout, 100*10**18, {'from': myAccout})
# iETH.approve(masterChef, 2**256-1, {'from': myAccout})
# masterChef.deposit(1, 10*10**18, {'from': myAccout})


# mint BUSD and iBUSD
amount = 10000*10**18
BUSD.transfer(myAccout, amount, {'from': "0x7c9e73d4c71dae564d41f78d56439bb4ba87592f"})
BUSD.approve(iBUSD, 2**256-1, {'from': myAccout})
iBUSD.mint(myAccout, 100*10**18, {'from': myAccout})
# iBUSD.approve(masterChef, 2**256-1, {'from': myAccout})
# masterChef.deposit(2, 10*10**18, {'from': myAccout})


# mint WBTC and iWBTC
amount = 10000*10**18
WBTC.transfer(myAccout, amount, {'from': "0x882c173bc7ff3b7786ca16dfed3dfffb9ee7847b"})
WBTC.approve(iWBTC, 2**256-1, {'from': myAccout})
iWBTC.mint(myAccout, 100*10**18, {'from': myAccout})
# iWBTC.approve(masterChef, 2**256-1, {'from': myAccout})
# masterChef.deposit(3, 10*10**18, {'from': myAccout})


# mint WBTC and iWBTC
amount = 10000*10**18
USDT.transfer(myAccout, amount, {'from': "0xfd5840cd36d94d7229439859c0112a4185bc0255"})
USDT.approve(iUSDT, 2**256-1, {'from': myAccout})
iUSDT.mint(myAccout, 100*10**18, {'from': myAccout})
# iUSDT.approve(masterChef, 2**256-1, {'from': myAccout})
# masterChef.deposit(4, 10*10**18, {'from': myAccout})


# mint BZRX and iBZRX
amount = 10000*10**18
BZRX.transfer(myAccout, amount, {'from': "0x631Fc1EA2270e98fbD9D92658eCe0F5a269Aa161"})
BZRX.approve(iBZRX, 2**256-1, {'from': myAccout})
iBZRX.mint(myAccout, 100*10**18, {'from': myAccout})
# iBZRX.approve(masterChef, 2**256-1, {'from': myAccout})
# masterChef.deposit(5, 10*10**18, {'from': myAccout})


# mint WBNB
WBNB.deposit({'from': myAccout, 'value': Wei('50 ether')})


ROUTER = Contract.from_abi("router", "0x05fF2B0DB69458A0750badebc4f9e13aDd608C7F", interface.IPancakeRouter02.abi)

BZRX.approve(ROUTER, 2**256-1, {'from': myAccout})
WBNB.approve(ROUTER, 2**256-1, {'from': myAccout})

quote = ROUTER.quote(1000*10**18, BZRX.address, WBNB.address)
quote1 = ROUTER.quote(10*10**18, WBNB.address, BZRX.address)

ROUTER.addLiquidity(BZRX, WBNB, quote1, 10*10**18, 0, 0,  myAccout, 10000000000000000000000000, {'from': myAccout})
# ROUTER.addLiquidity(BZRX, WBNB,4032502992322709085, 10*10**18, quote, 0,  accounts[0], 10000000000000000000000000, {'from': myAccout})