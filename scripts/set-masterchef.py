
import pytest
import time
from brownie import *
from brownie import Contract, network
from brownie.network.contract import InterfaceContainer
from brownie.network.state import _add_contract, _remove_contract


# bgovToken = myAccount.deploy(BGovToken)

if(bgovToken.owner() != masterChef.owner()):
    bgovToken.transferOwnership(masterChef, {'from': '0x1FDCA2422668B961E162A8849dc0C2feaDb58915'})


# # TODO @Tom farm configuration
# devAccount = myAccount
# bgovPerBlock = 100*10**18
# bonusEndBlock = chain.height + 1*10**6
# startBlock = chain.height

# masterChef = myAccount.deploy(MasterChef, bgovToken, devAccount, bgovPerBlock, startBlock, bonusEndBlock)
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

arr = [
    "0x736C4B5F62e4A9504D43900A5c4ddB0075eA6F45",
    "0xf4361E664fC26f1c5E1dEfcA4811c396c0C30017",
    "0x1F9b46f3D89FEc66c09511d14bf1A813bCc96200",
    "0x9B5dFE7965C4A30eAB764ff7abf81b3fa96847Fe"
]
# -u 0x736C4B5F62e4A9504D43900A5c4ddB0075eA6F45 -u 0xf4361E664fC26f1c5E1dEfcA4811c396c0C30017 -u 0x1F9b46f3D89FEc66c09511d14bf1A813bCc96200 -u 0xf508fcd89b8bd15579dc79a6827cb4686a3592c8 -u 0x9B5dFE7965C4A30eAB764ff7abf81b3fa96847Fe     -u 0x7c9e73d4c71dae564d41f78d56439bb4ba87592f -u 0x7c9e73d4c71dae564d41f78d56439bb4ba87592f -u 0x882c173bc7ff3b7786ca16dfed3dfffb9ee7847b -u 0xfd5840cd36d94d7229439859c0112a4185bc0255 -u 0x631Fc1EA2270e98fbD9D92658eCe0F5a269Aa161 -u 0x05fF2B0DB69458A0750badebc4f9e13aDd608C7F -u 0xb1256d6b31e4ae87da1d56e5890c66be7f1c038e -u 0x631fc1ea2270e98fbd9d92658ece0f5a269aa161 -u 0x631fc1ea2270e98fbd9d92658ece0f5a269aa161

for address in arr:
    print("Setup account: "+address)
    myAccount = address

    print("mint iWBNB")
    amount = 10*10**18
    accounts[1].transfer(to=myAccount, amount=Wei('10 ether'))
    accounts[2].transfer(to=myAccount, amount=Wei('10 ether'))
    accounts[3].transfer(to=myAccount, amount=Wei('10 ether'))
    iWBNB.mintWithEther(myAccount, {'from': myAccount, 'value': Wei('5 ether')})
    # iWBNB.approve(masterChef, 2**256-1, {'from': myAccount})
    # masterChef.deposit(0, 4*10**18, {'from': myAccount})

    print("mint ETH and iETH")
    amount = 10*10**18
    ETH.transfer(myAccount, amount, {'from': "0xf508fcd89b8bd15579dc79a6827cb4686a3592c8"})
    ETH.approve(iETH, 2**256-1, {'from': myAccount})
    iETH.mint(myAccount, 5*10**18, {'from': myAccount})
    # iETH.approve(masterChef, 2**256-1, {'from': myAccount})
    # masterChef.deposit(1, 4*10**18, {'from': myAccount})

    print("mint BUSD and iBUSD")
    amount = 10*10**18
    BUSD.transfer(myAccount, amount, {'from': "0x7c9e73d4c71dae564d41f78d56439bb4ba87592f"})
    BUSD.approve(iBUSD, 2**256-1, {'from': myAccount})
    iBUSD.mint(myAccount, 5*10**18, {'from': myAccount})
    # iBUSD.approve(masterChef, 2**256-1, {'from': myAccount})
    # masterChef.deposit(2, 4*10**18, {'from': myAccount})

    print("mint WBTC and iWBTC")
    amount = 10*10**18
    WBTC.transfer(myAccount, amount, {'from': "0x631fc1ea2270e98fbd9d92658ece0f5a269aa161"})
    WBTC.approve(iWBTC, 2**256-1, {'from': myAccount})
    iWBTC.mint(myAccount, 5*10**18, {'from': myAccount})
    # iWBTC.approve(masterChef, 2**256-1, {'from': myAccount})
    # masterChef.deposit(3, 4*10**18, {'from': myAccount})

    print("mint WBTC and iWBTC")
    amount = 10*10**18
    USDT.transfer(myAccount, amount, {'from': "0x631fc1ea2270e98fbd9d92658ece0f5a269aa161"})
    USDT.approve(iUSDT, 2**256-1, {'from': myAccount})
    iUSDT.mint(myAccount, 5*10**18, {'from': myAccount})
    # # iUSDT.approve(masterChef, 2**256-1, {'from': myAccount})
    # # masterChef.deposit(4, 4*10**18, {'from': myAccount})

    print("mint BZRX and iBZRX")
    amount = 10000*10**18
    BZRX.transfer(myAccount, amount, {'from': "0x631Fc1EA2270e98fbD9D92658eCe0F5a269Aa161"})
    BZRX.approve(iBZRX, 2**256-1, {'from': myAccount})
    iBZRX.mint(myAccount, 10000*10**18, {'from': myAccount})
    # iBZRX.approve(masterChef, 2**256-1, {'from': myAccount})
    # masterChef.deposit(5, 4*10**18, {'from': myAccount})

    print("mint WBNB")
    WBNB.deposit({'from': myAccount, 'value': Wei('5 ether')})

    ROUTER = Contract.from_abi("router", "0x05fF2B0DB69458A0750badebc4f9e13aDd608C7F", interface.IPancakeRouter02.abi)

    BZRX.approve(ROUTER, 2**256-1, {'from': myAccount})
    WBNB.approve(ROUTER, 2**256-1, {'from': myAccount})
    bgovToken.approve(ROUTER, 2**256-1, {'from': myAccount})

    quote = ROUTER.quote(1000*10**18, BZRX.address, WBNB.address)
    quote1 = ROUTER.quote(10*10**18, WBNB.address, BZRX.address)

    # ROUTER.addLiquidity(BZRX, WBNB, quote1, 10*10**18, 0, 0,  myAccount, 10000000000000000000000000, {'from': myAccount})
    # ROUTER.addLiquidity(BZRX, WBNB,4032502992322709085, 10*10**18, quote, 0,  accounts[0], 10000000000000000000000000, {'from': myAccount})

    #BZRX_wBNB.approve(masterChef, 2**256-1, {'from': myAccount})
    #masterChef.deposit(6, BZRX_wBNB.balanceOf(myAccount)/2, {'from': myAccount})

    print("mint BGOV_wBNB")
    bgovToken.mint(myAccount, 100*10**18, {'from':masterChef})
    ROUTER.addLiquidity(bgovToken, WBNB, quote1, bgovToken.balanceOf(myAccount), 0, 0,
                        myAccount, 10000000000000000000000000, {'from': myAccount})

    BGOV_wBNB.approve(masterChef, 2**256-1, {'from': myAccount})
    masterChef.deposit(6, BGOV_wBNB.balanceOf(myAccount)/2, {'from': myAccount})
