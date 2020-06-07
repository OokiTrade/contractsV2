#!/usr/bin/python3

from brownie import *
from brownie.network.contract import InterfaceContainer
from brownie.network.state import _add_contract, _remove_contract

import shared
from munch import Munch

deploys = Munch.fromDict({
    "bZxProtocol": True,
    "PriceFeeds": True,
    "SwapsImpl": True,
    "ProtocolMigration": True,
    "ProtocolSettings": True,
    "LoanSettings": True,
    "LoanOpenings": True,
    "LoanMaintenance": True,
    "LoanClosings": True,
})

def main():
    deployProtocol()

def deployProtocol():
    global deploys, bzx, tokens, constants, addresses, thisNetwork, acct

    thisNetwork = network.show_active()

    if thisNetwork == "development":
        acct = accounts[0]
    elif thisNetwork == "sandbox":
        acct = accounts.load('mainnet_deployer')
    else:
        acct = accounts.load('testnet_deployer')
    print("Loaded account",acct)

    constants = shared.Constants()
    addresses = shared.Addresses()

    tokens = Munch()
    if thisNetwork == "development":
        print("Deploying Tokens.")
        tokens.weth = acct.deploy(TestWeth) ## 0x3194cBDC3dbcd3E11a07892e7bA5c3394048Cc87
        tokens.dai = acct.deploy(TestToken, "DAI", "DAI", 18, 1e50)
        tokens.link = acct.deploy(TestToken, "LINK", "LINK", 18, 1e50)
    '''elif thisNetwork == "kovan":
        tokens.weth = Contract.from_abi("WETH", address=addresses.kovan.WETHTokenAddress, abi=IWethERC20.abi, owner=acct)
        tokens.dai = Contract.from_abi("DAI", address=addresses.kovan.DAITokenAddress, abi=IWethERC20.abi, owner=acct)
        tokens.link = Contract.from_abi("LINK", address=addresses.kovan.LINKTokenAddress, abi=IWethERC20.abi, owner=acct)'''

    ### DEPLOYMENT START ###

    if deploys.bZxProtocol is True:
        print("Deploying bZxProtocol.")
        bzxproxy = acct.deploy(bZxProtocol)
        bzx = Contract.from_abi("bzx", address=bzxproxy.address, abi=interface.IBZx.abi, owner=acct)
        _add_contract(bzx)
    else:
        if "bZxProtocol" in addresses[thisNetwork]:
            bzx = Contract.from_abi("bzx", address=addresses[thisNetwork].bZxProtocol, abi=interface.IBZx.abi, owner=acct)
            _add_contract(bzx)
        else:
            raise ValueError('bZxProtocol deployment missing!')

    ## PriceFeeds
    if deploys.PriceFeeds is True:
        print("Deploying PriceFeeds.")
        if thisNetwork == "development":        
            feeds = acct.deploy(PriceFeedsLocal)

            print("Calling setRates x3.")
            feeds.setRates(
                tokens.weth.address,
                tokens.link.address,
                54.52e18
            )
            feeds.setRates(
                tokens.weth.address,
                tokens.dai.address,
                200e18
            )
            feeds.setRates(
                tokens.link.address,
                tokens.dai.address,
                3.692e18
            )
        else:
            if thisNetwork == "kovan":
                feeds = acct.deploy(PriceFeedsTestnets)
                
                print("Calling setRateToKyber.")
                feeds.setRateToKyber(
                    "0xd0A1E359811322d97991E03f863a0C30C2cF029C", # WETH
                    "0xC4375B7De8af5a38a93548eb8453a498222C4fF2"  # SAI
                )
                feeds.setRateToKyber(
                    "0xd0A1E359811322d97991E03f863a0C30C2cF029C", # WETH
                    "0x4F96Fe3b7A6Cf9725f59d353F723c1bDb64CA6Aa"  # DAI
                )
                feeds.setRateToKyber(
                    "0xC4375B7De8af5a38a93548eb8453a498222C4fF2", # SAI
                    "0x4F96Fe3b7A6Cf9725f59d353F723c1bDb64CA6Aa"  # DAI
                )

                print("Calling setDecimals.")
                feeds.setDecimals(
                    [
                        "0xd0A1E359811322d97991E03f863a0C30C2cF029C", # WETH
                        "0xC4375B7De8af5a38a93548eb8453a498222C4fF2", # SAI
                        "0x4F96Fe3b7A6Cf9725f59d353F723c1bDb64CA6Aa", # DAI
                    ]
                )

                print("Calling setPriceFeed.")
                feeds.setPriceFeed(
                    [
                        "0xC4375B7De8af5a38a93548eb8453a498222C4fF2", # SAI
                        "0x4F96Fe3b7A6Cf9725f59d353F723c1bDb64CA6Aa", # DAI
                    ],
                    [
                        "0x6F47077D3B6645Cb6fb7A29D280277EC1e5fFD90", # SAI - (sharing DAI feed)
                        "0x6F47077D3B6645Cb6fb7A29D280277EC1e5fFD90", # DAI
                    ],
                )

                print("Calling setLoanPool.")
                feeds.setLoanPool(
                    [
                        "0x54BE07007C680bA087B3fcD8e675d1c929B6aAF5", # iETH
                        "0xA1e58F3B1927743393b25f261471E1f2D3D9f0F6", # iSAI
                        "0x6c1E2B0f67e00c06c8e2BE7Dc681Ab785163fF4D", # iDAI
                    ],
                    [
                        "0xd0A1E359811322d97991E03f863a0C30C2cF029C", # WETH
                        "0xC4375B7De8af5a38a93548eb8453a498222C4fF2", # SAI
                        "0x4F96Fe3b7A6Cf9725f59d353F723c1bDb64CA6Aa", # DAI
                    ]
                )
            elif thisNetwork == "sandbox":
                feeds = acct.deploy(PriceFeeds)
                
                print("Calling setDecimals.")
                feeds.setDecimals(
                    [
                        "0xc02aaa39b223fe8d0a0e5c4f27ead9083c756cc2", # WETH
                        "0xa0b86991c6218b36c1d19d4a2e9eb0ce3606eb48", # USDC
                        "0x89d24a6b4ccb1b6faa2625fe562bdd9a23260359", # SAI
                        "0x2260fac5e5542a773aa44fbcfedf7c193bc2c599", # WBTC
                        "0x9f8f72aa9304c8b593d555f12ef6589cc3a579a2", # MKR
                        "0xdd974d5c2e2928dea5f71b9825b8b646686bd200", # KNC
                        "0x1985365e9f78359a9b6ad760e32412f4a445e862", # REP
                        "0x0d8775f648430679a709e98d2b0cb6250d2887ef", # BAT
                        "0xe41d2489571d322189246dafa5ebde1f4699f498", # ZRX
                        "0x514910771af9ca656af840dff83e8264ecf986ca", # LINK
                        "0x57ab1ec28d129707052df4df418d58a2d46d5f51", # SUSD
                        "0x6b175474e89094c44da98b954eedeac495271d0f", # DAI
                        "0xdac17f958d2ee523a2206206994597c13d831ec7"  # USDT (Tether)
                    ]
                )

                print("Calling setPriceFeed.")
                feeds.setPriceFeed(
                    [
                        "0xa0b86991c6218b36c1d19d4a2e9eb0ce3606eb48", # USDC
                        "0x89d24a6b4ccb1b6faa2625fe562bdd9a23260359", # SAI
                        "0x2260fac5e5542a773aa44fbcfedf7c193bc2c599", # WBTC
                        "0x9f8f72aa9304c8b593d555f12ef6589cc3a579a2", # MKR
                        "0xdd974d5c2e2928dea5f71b9825b8b646686bd200", # KNC
                        "0x1985365e9f78359a9b6ad760e32412f4a445e862", # REP
                        "0x0d8775f648430679a709e98d2b0cb6250d2887ef", # BAT
                        "0xe41d2489571d322189246dafa5ebde1f4699f498", # ZRX
                        "0x514910771af9ca656af840dff83e8264ecf986ca", # LINK
                        "0x57ab1ec28d129707052df4df418d58a2d46d5f51", # SUSD
                        "0x6b175474e89094c44da98b954eedeac495271d0f", # DAI
                        "0xdac17f958d2ee523a2206206994597c13d831ec7"  # USDT (Tether)
                    ],
                    [
                        "0xdE54467873c3BCAA76421061036053e371721708", # USDC
                        "0x037E8F2125bF532F3e228991e051c8A7253B642c", # SAI - (sharing DAI feed)
                        "0x0133Aa47B6197D0BA090Bf2CD96626Eb71fFd13c", # WBTC
                        "0xda3d675d50ff6c555973c4f0424964e1f6a4e7d3", # MKR
                        "0xd0e785973390fF8E77a83961efDb4F271E6B8152", # KNC
                        "0xb8b513d9cf440C1b6f5C7142120d611C94fC220c", # REP
                        "0x9b4e2579895efa2b4765063310Dc4109a7641129", # BAT
                        "0xA0F9D94f060836756FFC84Db4C78d097cA8C23E8", # ZRX
                        "0xeCfA53A8bdA4F0c4dd39c55CC8deF3757aCFDD07", # LINK
                        "0x6d626Ff97f0E89F6f983dE425dc5B24A18DE26Ea", # SUSD
                        "0x037E8F2125bF532F3e228991e051c8A7253B642c", # DAI
                        "0xa874fe207DF445ff19E7482C746C4D3fD0CB9AcE"  # USDT (Tether)
                    ]
                )

                print("Calling setLoanPool.")
                feeds.setLoanPool(
                    [
                        "0x77f973FCaF871459aa58cd81881Ce453759281bC", # iETH
                        "0xF013406A0B1d544238083DF0B93ad0d2cBE0f65f", # iUSDC
                        "0x14094949152EDDBFcd073717200DA82fEd8dC960", # iSAI
                        "0xBA9262578EFef8b3aFf7F60Cd629d6CC8859C8b5", # iWBTC
                        "0x1cC9567EA2eB740824a45F8026cCF8e46973234D", # iKNC
                        "0xBd56E9477Fc6997609Cf45F84795eFbDAC642Ff1", # iREP
                        "0xA8b65249DE7f85494BC1fe75F525f568aa7dfa39", # iBAT
                        "0xA7Eb2bc82df18013ecC2A6C533fc29446442EDEe", # iZRX
                        "0x1D496da96caf6b518b133736beca85D5C4F9cBc5", # iLINK
                        "0x49f4592e641820e928f9919ef4abd92a719b4b49", # iSUSD
                        "0x493c57c4763932315a328269e1adad09653b9081", # iDAI
                        "0x8326645f3aa6de6420102fdb7da9e3a91855045b"  # iUSDT
                    ],
                    [
                        "0xc02aaa39b223fe8d0a0e5c4f27ead9083c756cc2", # WETH
                        "0xa0b86991c6218b36c1d19d4a2e9eb0ce3606eb48", # USDC
                        "0x89d24a6b4ccb1b6faa2625fe562bdd9a23260359", # SAI
                        "0x2260fac5e5542a773aa44fbcfedf7c193bc2c599", # WBTC
                        "0xdd974d5c2e2928dea5f71b9825b8b646686bd200", # KNC
                        "0x1985365e9f78359a9b6ad760e32412f4a445e862", # REP
                        "0x0d8775f648430679a709e98d2b0cb6250d2887ef", # BAT
                        "0xe41d2489571d322189246dafa5ebde1f4699f498", # ZRX
                        "0x514910771af9ca656af840dff83e8264ecf986ca", # LINK
                        "0x57ab1ec28d129707052df4df418d58a2d46d5f51", # SUSD
                        "0x6b175474e89094c44da98b954eedeac495271d0f", # DAI
                        "0xdac17f958d2ee523a2206206994597c13d831ec7"  # USDT (Tether)
                    ]
                )
    else:
        if "PriceFeeds" in addresses[thisNetwork]:
            feeds = Contract.from_abi("feeds", address=addresses[thisNetwork].PriceFeeds, abi=PriceFeeds.abi, owner=acct)
        else:
            raise ValueError('PriceFeeds deployment missing!')

    ## SwapImpl
    if deploys.SwapsImpl is True:
        print("Deploying Swaps.")
        if thisNetwork == "development":
            swaps = acct.deploy(SwapsImplLocal)
        else:
            swaps = acct.deploy(SwapsImplKyber)

    else:
        if "SwapsImpl" in addresses[thisNetwork]:
            swaps = Contract.from_abi("swaps", address=addresses[thisNetwork].SwapsImpl, abi=SwapsImplKyber.abi, owner=acct)
        else:
            raise ValueError('SwapsImpl deployment missing!')


    ## ProtocolMigration
    if deploys.ProtocolMigration is True:
        print("Deploying ProtocolMigration.")
        migration = acct.deploy(ProtocolMigration)
        print("Calling replaceContract.")
        bzx.replaceContract(migration.address)

        migration = Contract.from_abi("migration", address=bzx.address, abi=migration.abi, owner=acct)
        if thisNetwork == "kovan":
            print("Calling setLegacyOracles.")
            migration.setLegacyOracles(
                [
                    "0xa09dd6ff595041a85d406168a3ee2324e58cffa0",
                    "0x5d940c359165a8d4647cc8a237dcef8b0c6b60de",
                    "0x199bc31317a7d1505a5d13d4e4d4433c8644813b",
                ],
                [
                    "0xa09dd6ff595041a85d406168a3ee2324e58cffa0",
                    "0xa09dd6ff595041a85d406168a3ee2324e58cffa0",
                    "0xa09dd6ff595041a85d406168a3ee2324e58cffa0",
                ]
            )
        elif thisNetwork == "sandbox":
            print("Calling setLegacyOracles.")
            migration.setLegacyOracles(
                [
                    "0x7bc672a622620d531f9eb30de89daec31a4240fa",
                    "0xf257246627f7cb036ae40aa6cfe8d8ce5f0eba63",
                    "0x4c1974e5ff413c6e061ae217040795aaa1748e8b",
                    "0xc5c4554dc5ff2076206b5b3e1abdfb77ff74788b",
                    "0x53ef0Ad05972c348E352E0E22e734F616679Ce54",
                ],
                [
                    "0x7bc672a622620d531f9eb30de89daec31a4240fa",
                    "0x7bc672a622620d531f9eb30de89daec31a4240fa",
                    "0x7bc672a622620d531f9eb30de89daec31a4240fa",
                    "0x7bc672a622620d531f9eb30de89daec31a4240fa",
                    "0x7bc672a622620d531f9eb30de89daec31a4240fa",
                ]
            )

    ## ProtocolSettings
    if deploys.ProtocolSettings is True:
        print("Deploying ProtocolSettings.")
        settings = acct.deploy(ProtocolSettings)
        print("Calling replaceContract.")
        bzx.replaceContract(settings.address)

        print("Calling setCoreParams.")
        if thisNetwork == "sandbox":
            bzx.setCoreParams(
                "0x1c74cFF0376FB4031Cd7492cD6dB2D66c3f2c6B9", # protocolTokenAddress
                feeds.address, # priceFeeds
                swaps.address  # swapsImpl
            )
        else:
            bzx.setCoreParams(
                addresses[thisNetwork]["BZRXTokenAddress"], # protocolTokenAddress
                feeds.address, # priceFeeds
                swaps.address  # swapsImpl
            )

        if thisNetwork == "kovan":
            print("Calling setLoanPool.")
            bzx.setLoanPool(
                [
                    "0x54BE07007C680bA087B3fcD8e675d1c929B6aAF5", # iETH
                    "0xA1e58F3B1927743393b25f261471E1f2D3D9f0F6", # iSAI
                    "0x6c1E2B0f67e00c06c8e2BE7Dc681Ab785163fF4D", # iDAI
                ],
                [
                    "0xd0A1E359811322d97991E03f863a0C30C2cF029C", # WETH
                    "0xC4375B7De8af5a38a93548eb8453a498222C4fF2", # SAI
                    "0x4F96Fe3b7A6Cf9725f59d353F723c1bDb64CA6Aa", # DAI
                ]
            )

            print("Calling setSupportedTokens.")
            bzx.setSupportedTokens(
                [
                    "0xd0A1E359811322d97991E03f863a0C30C2cF029C", # WETH
                    "0xC4375B7De8af5a38a93548eb8453a498222C4fF2", # SAI
                    "0x4F96Fe3b7A6Cf9725f59d353F723c1bDb64CA6Aa", # DAI
                ],
                [
                    True,
                    True,
                    True
                ]
            )
        elif thisNetwork == "sandbox":
            print("Calling setLoanPool.")
            bzx.setLoanPool(
                [
                    "0x77f973FCaF871459aa58cd81881Ce453759281bC", # iETH
                    "0xF013406A0B1d544238083DF0B93ad0d2cBE0f65f", # iUSDC
                    "0x14094949152EDDBFcd073717200DA82fEd8dC960", # iSAI
                    "0xBA9262578EFef8b3aFf7F60Cd629d6CC8859C8b5", # iWBTC
                    "0x1cC9567EA2eB740824a45F8026cCF8e46973234D", # iKNC
                    "0xBd56E9477Fc6997609Cf45F84795eFbDAC642Ff1", # iREP
                    "0xA8b65249DE7f85494BC1fe75F525f568aa7dfa39", # iBAT
                    "0xA7Eb2bc82df18013ecC2A6C533fc29446442EDEe", # iZRX
                    "0x1D496da96caf6b518b133736beca85D5C4F9cBc5", # iLINK
                    "0x49f4592e641820e928f9919ef4abd92a719b4b49", # iSUSD
                    "0x493c57c4763932315a328269e1adad09653b9081", # iDAI
                    "0x8326645f3aa6de6420102fdb7da9e3a91855045b"  # iUSDT
                ],
                [
                    "0xc02aaa39b223fe8d0a0e5c4f27ead9083c756cc2", # WETH
                    "0xa0b86991c6218b36c1d19d4a2e9eb0ce3606eb48", # USDC
                    "0x89d24a6b4ccb1b6faa2625fe562bdd9a23260359", # SAI
                    "0x2260fac5e5542a773aa44fbcfedf7c193bc2c599", # WBTC
                    "0xdd974d5c2e2928dea5f71b9825b8b646686bd200", # KNC
                    "0x1985365e9f78359a9b6ad760e32412f4a445e862", # REP
                    "0x0d8775f648430679a709e98d2b0cb6250d2887ef", # BAT
                    "0xe41d2489571d322189246dafa5ebde1f4699f498", # ZRX
                    "0x514910771af9ca656af840dff83e8264ecf986ca", # LINK
                    "0x57ab1ec28d129707052df4df418d58a2d46d5f51", # SUSD
                    "0x6b175474e89094c44da98b954eedeac495271d0f", # DAI
                    "0xdac17f958d2ee523a2206206994597c13d831ec7"  # USDT (Tether)
                ]
            )

            print("Calling setSupportedTokens.")
            bzx.setSupportedTokens(
                [
                    "0xc02aaa39b223fe8d0a0e5c4f27ead9083c756cc2", # WETH
                    "0xa0b86991c6218b36c1d19d4a2e9eb0ce3606eb48", # USDC
                    "0x89d24a6b4ccb1b6faa2625fe562bdd9a23260359", # SAI
                    "0x2260fac5e5542a773aa44fbcfedf7c193bc2c599", # WBTC
                    "0x9f8f72aa9304c8b593d555f12ef6589cc3a579a2", # MKR
                    "0xdd974d5c2e2928dea5f71b9825b8b646686bd200", # KNC
                    "0x1985365e9f78359a9b6ad760e32412f4a445e862", # REP
                    "0x0d8775f648430679a709e98d2b0cb6250d2887ef", # BAT
                    "0xe41d2489571d322189246dafa5ebde1f4699f498", # ZRX
                    "0x514910771af9ca656af840dff83e8264ecf986ca", # LINK
                    "0x57ab1ec28d129707052df4df418d58a2d46d5f51", # SUSD
                    "0x6b175474e89094c44da98b954eedeac495271d0f", # DAI
                    "0xdac17f958d2ee523a2206206994597c13d831ec7"  # USDT (Tether)
                ],
                [
                    True, # WETH
                    True, # USDC
                    True, # SAI
                    True, # WBTC
                    True, # MKR
                    True, # KNC
                    True, # REP
                    True, # BAT
                    True, # ZRX
                    True, # LINK
                    True, # SUSD
                    True, # DAI
                    True  # USDT (Tether)
                ]
            )

    ## LoanSettings
    if deploys.LoanSettings is True:
        print("Deploying LoanSettings.")
        loanSettings = acct.deploy(LoanSettings)
        print("Calling replaceContract.")
        bzx.replaceContract(loanSettings.address)

    ## LoanOpenings
    if deploys.LoanOpenings is True:
        print("Deploying LoanOpenings.")
        loanOpenings = acct.deploy(LoanOpenings)
        print("Calling replaceContract.")
        bzx.replaceContract(loanOpenings.address)

    ## LoanMaintenance
    if deploys.LoanMaintenance is True:
        print("Deploying LoanMaintenance.")
        loanMaintenance = acct.deploy(LoanMaintenance)
        print("Calling replaceContract.")
        bzx.replaceContract(loanMaintenance.address)

    ## LoanClosings
    if deploys.LoanClosings is True:
        print("Deploying LoanClosings.")
        loanClosings = acct.deploy(LoanClosings)
        print("Calling replaceContract.")
        bzx.replaceContract(loanClosings.address)
