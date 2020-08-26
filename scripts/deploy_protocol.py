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
            '''
                print("Calling setDecimals.")
                feeds.setDecimals(
                    [
                        "0xd0A1E359811322d97991E03f863a0C30C2cF029C", # WETH
                        "0xC4375B7De8af5a38a93548eb8453a498222C4fF2", # SAI
                        "0x4F96Fe3b7A6Cf9725f59d353F723c1bDb64CA6Aa", # DAI
                        "0xad67cB4d63C9da94AcA37fDF2761AaDF780ff4a2", # KNC
                        "0xB54Fc2F2ea17d798Ad5C7Aba2491055BCeb7C6b2", # BZRX
                        "0x6F8304039f34fd6A6acDd511988DCf5f62128a32"  # vBZRX
                    ]
                )

                print("Calling setPriceFeed.")
                feeds.setPriceFeed(
                    [
                        "0xC4375B7De8af5a38a93548eb8453a498222C4fF2", # SAI
                        "0x4F96Fe3b7A6Cf9725f59d353F723c1bDb64CA6Aa", # DAI
                        "0xad67cB4d63C9da94AcA37fDF2761AaDF780ff4a2"  # KNC
                    ],
                    [
                        "0x6F47077D3B6645Cb6fb7A29D280277EC1e5fFD90", # SAI - (sharing DAI feed)
                        "0x6F47077D3B6645Cb6fb7A29D280277EC1e5fFD90", # DAI
                        "0x0893AaF58f62279909F9F6FF2E5642f53342e77F"  # KNC
                    ],
                )
            '''
                print("Calling setDecimals.")
                feeds.setDecimals(
                    [
                        "0xE65D99a06D0Ded0D318E31dB3AE5D77629c625fc", # WETH
                        "0x20BdF254Ca63883c3a83424753BB40185AF29cE4", # USDC
                        "0x7143e05608C4BC7E83a3B72a28De2497f62B7e59", # SAI
                        "0xc4B7A70c3694cB1d37A18e6c6bD9271828C382A4", # WBTC
                        "0x4893919982648FFeFE4324538D54402387C20198", # MKR
                        "0x02357164ba33F299F7654cBB29da29dB38aE1f44", # KNC
                        "0x39AC2818e08D285aBE548F77a0819651b8B5d213", # REP
                        "0xAc091Ccf1b0c601182f3CCF3EB20F291ABA39029", # BAT
                        "0x629B28c5aA5c953Df2511d2E48d316A07eAFb3e3", # ZRX
                        "0xFB9325e5f4fC9629525427A1c92c0f4D723500Cf", # LINK
                        "0xFCfA14dBc71beE2a2188431Fa15E1f8D57d93c62", # SUSD
                        "0x8f746eC7ed5Cc265b90e7AF0f5B07b4406C9dDA8", # DAI
                        "0x4C4462C6bca4c92BF41C40f9a4047F35Fd296996", # USDT (Tether)
                        "0xB54Fc2F2ea17d798Ad5C7Aba2491055BCeb7C6b2", # BZRX
                        "0x6F8304039f34fd6A6acDd511988DCf5f62128a32"  # vBZRX
                    ]
                )
                print("Calling setPriceFeed.")
                feeds.setPriceFeed(
                    [
                        "0xE65D99a06D0Ded0D318E31dB3AE5D77629c625fc", # fWETH
                        "0x20BdF254Ca63883c3a83424753BB40185AF29cE4", # USDC
                        "0x7143e05608C4BC7E83a3B72a28De2497f62B7e59", # SAI
                        "0xc4B7A70c3694cB1d37A18e6c6bD9271828C382A4", # WBTC
                        "0x4893919982648FFeFE4324538D54402387C20198", # MKR
                        "0x02357164ba33F299F7654cBB29da29dB38aE1f44", # KNC
                        "0x39AC2818e08D285aBE548F77a0819651b8B5d213", # REP
                        "0xAc091Ccf1b0c601182f3CCF3EB20F291ABA39029", # BAT
                        "0x629B28c5aA5c953Df2511d2E48d316A07eAFb3e3", # ZRX
                        "0xFB9325e5f4fC9629525427A1c92c0f4D723500Cf", # LINK
                        "0xFCfA14dBc71beE2a2188431Fa15E1f8D57d93c62", # SUSD
                        "0x8f746eC7ed5Cc265b90e7AF0f5B07b4406C9dDA8", # DAI
                        "0x4C4462C6bca4c92BF41C40f9a4047F35Fd296996", # USDT (Tether)
                        "0xB54Fc2F2ea17d798Ad5C7Aba2491055BCeb7C6b2", # BZRX
                        "0x0000000000000000000000000000000000000001"  # Fast Gas / Gwei
                    ],
                    [
                        "0x775E76cca1B5bc903c9a8C6f77416A35E5744664", # SNX (stand-in for fWETH)
                        "0x672c1C0d1130912D83664011E7960a42E8cA05D5", # USDC
                        "0x6F47077D3B6645Cb6fb7A29D280277EC1e5fFD90", # SAI - (sharing DAI feed)
                        "0x33E5085E92f5b53E9A193E28ad2f76bF210550BB", # WBTC
                        "0x14D7714eC44F44ECD0098B39e642b246fB2c38D0", # MKR
                        "0x0893AaF58f62279909F9F6FF2E5642f53342e77F", # KNC
                        "0x09F4A94F44c29d4967C761bBdB89f5bD3E2c09E6", # REP
                        "0x2c8d01771CCDca47c103194C5860dbEA2fE61626", # BAT
                        "0x2636cfdDB457a6C7A7D60A439F1E5a5a0C3d9c65", # ZRX
                        "0xf1e71Afd1459C05A2F898502C4025be755aa844A", # LINK
                        "0xa353F8b083F7575cfec443b5ad585D42f652E9F7", # SUSD
                        "0x6F47077D3B6645Cb6fb7A29D280277EC1e5fFD90", # DAI
                        "0xCC833A6522721B3252e7578c5BCAF65738B75Fc3", # USDT (Tether)
                        "0x9aa9da35DC44F93D90436BfE256f465f720c3Ae5", # BZRX
                        "0x07435f5182AAebBB176E58078451Fdd7FCD4EaC7"  # Fast Gas / Gwei
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
                        "0xdac17f958d2ee523a2206206994597c13d831ec7", # USDT (Tether)
                        "0x56d811088235F11C8920698a204A5010a788f4b3", # BZRX
                        "0xB72B31907C1C95F3650b64b2469e08EdACeE5e8F"  # vBZRX
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
                        "0xdac17f958d2ee523a2206206994597c13d831ec7", # USDT (Tether)
                        "0x56d811088235F11C8920698a204A5010a788f4b3", # BZRX
                        "0x0000000000000000000000000000000000000001"  # Fast Gas / Gwei
                    ],
                    [
                        "0x986b5E1e1755e3C2440e960477f25201B0a8bbD4", # USDC
                        "0x773616E4d11A78F511299002da57A0a94577F1f4", # SAI - (sharing DAI feed)
                        "0xdeb288F737066589598e9214E782fa5A8eD689e8", # WBTC
                        "0x24551a8Fb2A7211A25a17B1481f043A8a8adC7f2", # MKR
                        "0x656c0544eF4C98A6a98491833A89204Abb045d6b", # KNC
                        "0xD4CE430C3b67b3E2F7026D86E7128588629e2455", # REP
                        "0x0d16d4528239e9ee52fa531af613AcdB23D88c94", # BAT
                        "0x2Da4983a622a8498bb1a21FaE9D8F6C664939962", # ZRX
                        "0xDC530D9457755926550b59e8ECcdaE7624181557", # LINK
                        "0x8e0b7e6062272B5eF4524250bFFF8e5Bd3497757", # SUSD
                        "0x773616E4d11A78F511299002da57A0a94577F1f4", # DAI
                        "0xEe9F2375b4bdF6387aa8265dD4FB8F16512A1d46"  # USDT (Tether)
                        "0x8f7C7181Ed1a2BA41cfC3f5d064eF91b67daef66", # BZRX
                        "0x169E633A2D1E6c10dD91238Ba11c4A708dfEF37C"  # Fast Gas / Gwei
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
            swaps = acct.deploy(SwapsImplTestnets)
        elif thisNetwork == "kovan":
            swaps = acct.deploy(SwapsImplTestnets)
        else:
            swaps = acct.deploy(SwapsImplKyber)

    else:
        if "SwapsImpl" in addresses[thisNetwork]:
            swaps = Contract.from_abi("swaps", address=addresses[thisNetwork].SwapsImpl, abi=SwapsImplKyber.abi, owner=acct)
        else:
            raise ValueError('SwapsImpl deployment missing!')


    '''
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
    '''

    ## ProtocolSettings
    if deploys.ProtocolSettings is True:
        print("Deploying ProtocolSettings.")
        settings = acct.deploy(ProtocolSettings)
        print("Calling replaceContract.")
        bzx.replaceContract(settings.address)

        print("Calling setPriceFeedContract.")
        bzx.setPriceFeedContract(
            feeds.address # priceFeeds
        )

        print("Calling setSwapsImplContract.")
        bzx.setSwapsImplContract(
            swaps.address  # swapsImpl
        )

        if thisNetwork == "kovan":
            print("Calling setLoanPool.")
            '''bzx.setLoanPool(
                [
                    "0x0afBFCe9DB35FFd1dFdF144A788fa196FD08EFe9", # iETH
                    "0xA1e58F3B1927743393b25f261471E1f2D3D9f0F6", # iSAI
                    "0xd40C0e7230c5bde65B61B5EDDc3E973f76Aff252", # iDAI
                    "0x988F40e4B07aC9b5e78533282Ba14a57440827e8"  # iKNC
                ],
                [
                    "0xd0A1E359811322d97991E03f863a0C30C2cF029C", # WETH
                    "0xC4375B7De8af5a38a93548eb8453a498222C4fF2", # SAI
                    "0x4F96Fe3b7A6Cf9725f59d353F723c1bDb64CA6Aa", # DAI
                    "0xad67cB4d63C9da94AcA37fDF2761AaDF780ff4a2"  # KNC
                ]
            )

            print("Calling setSupportedTokens.")
            bzx.setSupportedTokens(
                [
                    "0xd0A1E359811322d97991E03f863a0C30C2cF029C", # WETH
                    "0xC4375B7De8af5a38a93548eb8453a498222C4fF2", # SAI
                    "0x4F96Fe3b7A6Cf9725f59d353F723c1bDb64CA6Aa", # DAI
                    "0xad67cB4d63C9da94AcA37fDF2761AaDF780ff4a2", # KNC
                    "0xB54Fc2F2ea17d798Ad5C7Aba2491055BCeb7C6b2", # BZRX
                    "0x6F8304039f34fd6A6acDd511988DCf5f62128a32"  # vBZRX
                ],
                [
                    True,
                    True,
                    True,
                    True,
                    True,
                    True
                ]
            )'''
            bzx.setLoanPool(
                [
                    "0x9D2015Dd5306C08bDd8530605137d26c04DEDBD8", # fiWETH
                    "0xaaC9822F31e5Aefb32bC228DcF259F23B49B9855", # iUSDC
                    "0x8D18c5b71348f69733C34Fd32eC8315BdC8222FB", # iSAI
                    "0x73D4b4AB88Eab2A1e6cE495dE85C2B04c2918B69", # iWBTC
                    "0x3e72500122C3afD64AfE0306D7fbc7b8bd82b7d2", # iMKR
                    "0xdE7a60c3581F0D8C8723a71c28579131984A410c", # iKNC
                    "0x8638B468BF02BDB8fc8C5b33dCA8c2D16c3fD67B", # iREP
                    "0xb59659564012fA337BB8b9E626b7964b5349f047", # iBAT
                    "0xbac711d9963F0DB23613F3C338A7a1aF151C0696", # iZRX
                    "0x76754C763A23e9202CC721584Fbaf6012ecd8FbA", # iLINK
                    "0x1CAc31ECC90912EEa18cCAdfab15fD9c0e77cbab", # iSUSD
                    "0x73d0B4834Ba4ADa053d8282c02305eCdAC2304f0", # iDAI
                    "0x6b9F03e05423cC8D00617497890C0872FF33d4E8", # iUSDT (Tether)
                ],
                [
                    "0xE65D99a06D0Ded0D318E31dB3AE5D77629c625fc", # WETH
                    "0x20BdF254Ca63883c3a83424753BB40185AF29cE4", # USDC
                    "0x7143e05608C4BC7E83a3B72a28De2497f62B7e59", # SAI
                    "0xc4B7A70c3694cB1d37A18e6c6bD9271828C382A4", # WBTC
                    "0x4893919982648FFeFE4324538D54402387C20198", # MKR
                    "0x02357164ba33F299F7654cBB29da29dB38aE1f44", # KNC
                    "0x39AC2818e08D285aBE548F77a0819651b8B5d213", # REP
                    "0xAc091Ccf1b0c601182f3CCF3EB20F291ABA39029", # BAT
                    "0x629B28c5aA5c953Df2511d2E48d316A07eAFb3e3", # ZRX
                    "0xFB9325e5f4fC9629525427A1c92c0f4D723500Cf", # LINK
                    "0xFCfA14dBc71beE2a2188431Fa15E1f8D57d93c62", # SUSD
                    "0x8f746eC7ed5Cc265b90e7AF0f5B07b4406C9dDA8", # DAI
                    "0x4C4462C6bca4c92BF41C40f9a4047F35Fd296996", # USDT (Tether)
                ]
            )

            print("Calling setSupportedTokens.")
            bzx.setSupportedTokens(
                [
                    "0xE65D99a06D0Ded0D318E31dB3AE5D77629c625fc", # WETH
                    "0x20BdF254Ca63883c3a83424753BB40185AF29cE4", # USDC
                    "0x7143e05608C4BC7E83a3B72a28De2497f62B7e59", # SAI
                    "0xc4B7A70c3694cB1d37A18e6c6bD9271828C382A4", # WBTC
                    "0x4893919982648FFeFE4324538D54402387C20198", # MKR
                    "0x02357164ba33F299F7654cBB29da29dB38aE1f44", # KNC
                    "0x39AC2818e08D285aBE548F77a0819651b8B5d213", # REP
                    "0xAc091Ccf1b0c601182f3CCF3EB20F291ABA39029", # BAT
                    "0x629B28c5aA5c953Df2511d2E48d316A07eAFb3e3", # ZRX
                    "0xFB9325e5f4fC9629525427A1c92c0f4D723500Cf", # LINK
                    "0xFCfA14dBc71beE2a2188431Fa15E1f8D57d93c62", # SUSD
                    "0x8f746eC7ed5Cc265b90e7AF0f5B07b4406C9dDA8", # DAI
                    "0x4C4462C6bca4c92BF41C40f9a4047F35Fd296996", # USDT (Tether)
                    "0xB54Fc2F2ea17d798Ad5C7Aba2491055BCeb7C6b2", # BZRX
                    "0x6F8304039f34fd6A6acDd511988DCf5f62128a32"  # vBZRX
                ],
                [
                    True,
                    True,
                    True,
                    True,
                    True,
                    True,
                    True,
                    True,
                    True,
                    True,
                    True,
                    True,
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
                    "0xdac17f958d2ee523a2206206994597c13d831ec7", # USDT (Tether)
                    "0x56d811088235F11C8920698a204A5010a788f4b3", # BZRX
                    "0xB72B31907C1C95F3650b64b2469e08EdACeE5e8F"  # vBZRX
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
                    True, # USDT (Tether)
                    True, # BZRX
                    True  # vBZRX
                ]
            )

        bzx.setFeesController(acct.address)

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

        print("Deploying LoanClosingsWithGasToken.")
        LoanClosingsWithGasToken = acct.deploy(LoanClosingsWithGasToken)
        print("Calling replaceContract.")
        bzx.replaceContract(LoanClosingsWithGasToken.address)
