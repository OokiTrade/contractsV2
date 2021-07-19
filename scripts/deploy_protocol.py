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
    pos = thisNetwork.find("-fork")
    if pos != -1:
        thisNetwork = thisNetwork[:thisNetwork.find("-fork")]

    if thisNetwork == "development":
        acct = accounts[0]
    elif thisNetwork == "mainnet":
        acct = accounts.load('deployer1')
    else:
        acct = accounts.load('testnet_admin')
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
                '''feeds = acct.deploy(PriceFeedsLocal)

                print("Calling setRates x3.")
                feeds.setRates(
                    "0xfBE16bA4e8029B759D3c5ef8844124893f3ae470", # WETH
                    "0xB443f30CDd6076b1A5269dbc08b774F222d4Db4e", # USDC
                    100e18
                )
                feeds.setRates(
                    "0xB54Fc2F2ea17d798Ad5C7Aba2491055BCeb7C6b2", # BZRX
                    "0xfBE16bA4e8029B759D3c5ef8844124893f3ae470", # WETH
                    0.000333738893662566e18
                )

                feeds.setRates(
                    "0x5aE55494Ccda82f1F7c653BC2b6EbB4aD3C77Dac", # WBTC
                    "0xfBE16bA4e8029B759D3c5ef8844124893f3ae470", # WETH
                    30.283297741653263000e18
                )
                '''

                feeds = acct.deploy(PriceFeedsLocal)

                feedsOld = Contract.from_abi("feeds", bzx.priceFeeds(), abi=PriceFeedsLocal.abi, owner=acct)
                print("Calling setRates x3.")
                feeds.setRates(
                    "0xfBE16bA4e8029B759D3c5ef8844124893f3ae470", # WETH
                    "0xB443f30CDd6076b1A5269dbc08b774F222d4Db4e", # USDC
                    feedsOld.rates("0xfBE16bA4e8029B759D3c5ef8844124893f3ae470", "0xB443f30CDd6076b1A5269dbc08b774F222d4Db4e")
                )
                feeds.setRates(
                    "0xB54Fc2F2ea17d798Ad5C7Aba2491055BCeb7C6b2", # BZRX
                    "0xfBE16bA4e8029B759D3c5ef8844124893f3ae470", # WETH
                    feedsOld.rates("0xB54Fc2F2ea17d798Ad5C7Aba2491055BCeb7C6b2", "0xfBE16bA4e8029B759D3c5ef8844124893f3ae470")
                )

                feeds.setRates(
                    "0x5aE55494Ccda82f1F7c653BC2b6EbB4aD3C77Dac", # WBTC
                    "0xfBE16bA4e8029B759D3c5ef8844124893f3ae470", # WETH
                    feedsOld.rates("0x5aE55494Ccda82f1F7c653BC2b6EbB4aD3C77Dac", "0xfBE16bA4e8029B759D3c5ef8844124893f3ae470")
                )

                print("Calling setDecimals.")
                feeds.setDecimals(
                    [
                        "0xfBE16bA4e8029B759D3c5ef8844124893f3ae470", # WETH
                        "0xB443f30CDd6076b1A5269dbc08b774F222d4Db4e", # USDC
                        "0x5aE55494Ccda82f1F7c653BC2b6EbB4aD3C77Dac", # WBTC
                        "0xB54Fc2F2ea17d798Ad5C7Aba2491055BCeb7C6b2", # BZRX
                        "0x6F8304039f34fd6A6acDd511988DCf5f62128a32"  # vBZRX
                    ]
                )
            elif thisNetwork == "mainnet":
                feeds = acct.deploy(PriceFeeds)
                #feeds = Contract.from_abi("feeds", address=bzx.priceFeeds(), abi=PriceFeeds.abi, owner=acct)

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
                        "0xB72B31907C1C95F3650b64b2469e08EdACeE5e8F", # vBZRX
                        "0x0bc529c00C6401aEF6D220BE8C6Ea1667F6Ad93e", # YFI
                        "0x80fB784B7eD66730e8b1DBd9820aFD29931aab03", # LEND
                        "0x7Fc66500c84A76Ad7e9c93437bFc5Ac33E2DDaE9", # AAVE
                        "0x1f9840a85d5aF5bf1D1762F925BDADdC4201F984", # UNI
                        "0xc00e94Cb662C3520282E6f5717214004A7f26888", # COMP
                        "0xBBbbCA6A901c926F240b89EacB641d8Aec7AEafD", # LRC
                        "0xB8c77482e45F1F44dE1745F52C74426C631bDD52", # BNB
                    ]
                , {"from": acct, "gas_price": 22e9})

                print("Calling setPriceFeed.")
                feeds.setPriceFeed(
                    [
                        "0xa0b86991c6218b36c1d19d4a2e9eb0ce3606eb48", # USDC
                        "0xdac17f958d2ee523a2206206994597c13d831ec7", # USDT (Tether)
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
                        "0x56d811088235F11C8920698a204A5010a788f4b3", # BZRX
                        "0x0bc529c00C6401aEF6D220BE8C6Ea1667F6Ad93e", # YFI
                        "0x80fB784B7eD66730e8b1DBd9820aFD29931aab03", # LEND
                        "0x7Fc66500c84A76Ad7e9c93437bFc5Ac33E2DDaE9", # AAVE
                        "0x1f9840a85d5aF5bf1D1762F925BDADdC4201F984", # UNI
                        "0xc00e94Cb662C3520282E6f5717214004A7f26888", # COMP
                        "0xBBbbCA6A901c926F240b89EacB641d8Aec7AEafD", # LRC
                        "0xB8c77482e45F1F44dE1745F52C74426C631bDD52", # BNB
                        "0x0000000000000000000000000000000000000001"  # Fast Gas / Gwei
                    ],
                    [
                        "0xA9F9F897dD367C416e350c33a92fC12e53e1Cee5", # USDC (DollarPegFeed)
                        "0xA9F9F897dD367C416e350c33a92fC12e53e1Cee5", # USDT (DollarPegFeed)
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
                        "0x8f7C7181Ed1a2BA41cfC3f5d064eF91b67daef66", # BZRX
                        "0x7c5d4F8345e66f68099581Db340cd65B078C41f4", # YFI
                        "0xc64F3C3925a216a11Ce0828498133cbC65fA4042", # LEND (old: 0xc9dDB0E869d931D031B24723132730Ecf3B4F74d)
                        "0x6Df09E975c830ECae5bd4eD9d90f3A95a4f88012", # AAVE
                        "0xD6aA3D25116d8dA79Ea0246c4826EB951872e02e", # UNI
                        "0x1B39Ee86Ec5979ba5C322b826B3ECb8C79991699", # COMP
                        "0x160AC928A16C93eD4895C2De6f81ECcE9a7eB7b4", # LRC
                        "", # BNB
                        "0x169E633A2D1E6c10dD91238Ba11c4A708dfEF37C"  # Fast Gas / Gwei
                    ]
                , {"from": acct, "gas_price": 22e9})

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
            #swaps = acct.deploy(SwapsImplKyber)
            swaps = acct.deploy(SwapsImplUniswapV2_ETH)

    else:
        if "SwapsImpl" in addresses[thisNetwork]:
            #swaps = Contract.from_abi("swaps", address=addresses[thisNetwork].SwapsImpl, abi=SwapsImplKyber.abi, owner=acct)
            swaps = Contract.from_abi("swaps", address=addresses[thisNetwork].SwapsImpl, abi=SwapsImplUniswapV2_ETH.abi, owner=acct)
        else:
            raise ValueError('SwapsImpl deployment missing!')

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
            bzx.setMaxSwapSize(0)

            #swaps = Contract.from_abi("swaps", bzx.swapsImpl(), abi=SwapsImplTestnets.abi, owner=acct)
            swaps.setLocalPriceFeedContract(bzx.priceFeeds())

            print("Calling setLoanPool.")
            bzx.setLoanPool(
                [
                    "0xe3d99c2152Fc8eA5F87B733706FAA241C37592f1", # ifWETH
                    "0x021C5923398168311Ff320902BF8c8C725B4F288", # iUSDC
                    "0xF6a0690f22da5464924A28a8198E8ecA69ffc47e", # iWBTC
                ],
                [
                    "0xfBE16bA4e8029B759D3c5ef8844124893f3ae470", # WETH
                    "0xB443f30CDd6076b1A5269dbc08b774F222d4Db4e", # USDC
                    "0x5aE55494Ccda82f1F7c653BC2b6EbB4aD3C77Dac", # WBTC
                ]
            )

            print("Calling setSupportedTokens.")
            bzx.setSupportedTokens(
                [
                    "0xfBE16bA4e8029B759D3c5ef8844124893f3ae470", # WETH
                    "0xB443f30CDd6076b1A5269dbc08b774F222d4Db4e", # USDC
                    "0xB54Fc2F2ea17d798Ad5C7Aba2491055BCeb7C6b2", # BZRX
                    "0x5aE55494Ccda82f1F7c653BC2b6EbB4aD3C77Dac", # WBTC
                    "0x6F8304039f34fd6A6acDd511988DCf5f62128a32"  # vBZRX
                ],
                [
                    True,
                    True,
                    True,
                    True,
                    True
                ],
                True
            )

            ## 7e18 = 5% collateral discount
            # handled in setup_pool_params2
            '''function setLiquidationIncentivePercent(
                address[] calldata loanTokens,
                address[] calldata collateralTokens,
                uint256[] calldata amounts)
                external
                onlyOwner'''

        elif thisNetwork == "mainnet":
            print("Calling setLoanPool.")

            bzx.setLoanPool(
                [
                    "0x6b093998d36f2c7f0cc359441fbb24cc629d5ff0", # iDAI
                    "0xb983e01458529665007ff7e0cddecdb74b967eb6", # iETH
                    "0x32e4c68b3a4a813b710595aeba7f6b7604ab9c15", # iUSDC
                    "0x2ffa85f655752fb2acb210287c60b9ef335f5b6e", # iWBTC
                    "0xab45bf58c6482b87da85d6688c4d9640e093be98", # iLEND
                    "0x687642347a9282be8fd809d8309910a3f984ac5a", # iKNC
                    "0x9189c499727f88f8ecc7dc4eea22c828e6aac015", # iMKR
                    "0x18240bd9c07fa6156ce3f3f61921cc82b2619157", # iBZRX
                    "0x463538705e7d22aa7f03ebf8ab09b067e1001b54", # iLINK
                    "0x7f3fe9d492a9a60aebb06d82cba23c6f32cad10b", # iYFI
                    "0x7e9997a38a439b2be7ed9c9c4628391d3e055d48", # iUSDT
                    "0x0cae8d91E0b1b7Bd00D906E990C3625b2c220db1", # iAAVE
                    "0x0a625FceC657053Fe2D9FFFdeb1DBb4e412Cf8A8", # iUNI
                    "0x6d29903BC2c4318b59B35d97Ab98ab9eC08Ed70D", # iCOMP
                    "0x3dA0e01472Dee3746b4D324a65D7EdFaECa9Aa4f", # iLRC
                    #"0x88183Ec0054F40D344e40EC934D5a9E2749a61d4", # iBNB
                ],
                [
                    "0x6b175474e89094c44da98b954eedeac495271d0f", # DAI
                    "0xc02aaa39b223fe8d0a0e5c4f27ead9083c756cc2", # ETH
                    "0xa0b86991c6218b36c1d19d4a2e9eb0ce3606eb48", # USDC
                    "0x2260fac5e5542a773aa44fbcfedf7c193bc2c599", # WBTC
                    "0x80fB784B7eD66730e8b1DBd9820aFD29931aab03", # LEND
                    "0xdd974d5c2e2928dea5f71b9825b8b646686bd200", # KNC
                    "0x9f8f72aa9304c8b593d555f12ef6589cc3a579a2", # MKR
                    "0x56d811088235F11C8920698a204A5010a788f4b3", # BZRX
                    "0x514910771AF9Ca656af840dff83E8264EcF986CA", # LINK
                    "0x0bc529c00C6401aEF6D220BE8C6Ea1667F6Ad93e", # YFI
                    "0xdac17f958d2ee523a2206206994597c13d831ec7", # USDT
                    "0x7Fc66500c84A76Ad7e9c93437bFc5Ac33E2DDaE9", # AAVE
                    "0x1f9840a85d5aF5bf1D1762F925BDADdC4201F984", # UNI
                    "0xc00e94Cb662C3520282E6f5717214004A7f26888", # COMP
                    "0xBBbbCA6A901c926F240b89EacB641d8Aec7AEafD", # LRC
                    #"0xB8c77482e45F1F44dE1745F52C74426C631bDD52", # BNB
                ]
            , {"from": acct, "gas_price": 22e9})

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
                    "0xB72B31907C1C95F3650b64b2469e08EdACeE5e8F", # vBZRX
                    "0x0bc529c00C6401aEF6D220BE8C6Ea1667F6Ad93e", # YFI
                    "0x80fB784B7eD66730e8b1DBd9820aFD29931aab03", # LEND
                    "0x7Fc66500c84A76Ad7e9c93437bFc5Ac33E2DDaE9", # AAVE
                    "0x1f9840a85d5aF5bf1D1762F925BDADdC4201F984", # UNI
                    "0xc00e94Cb662C3520282E6f5717214004A7f26888", # COMP
                    "0xBBbbCA6A901c926F240b89EacB641d8Aec7AEafD", # LRC
                    #"0xB8c77482e45F1F44dE1745F52C74426C631bDD52", # BNB
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
                    True, # vBZRX
                    True, # YFI
                    True, # LEND
                    True, # AAVE
                    True, # UNI
                    True, # COMP
                    True, # LRC
                    #True, # BNB
                ],
                True
            , {"from": acct, "gas_price": 22e9})

            ## 7e18 = 5% collateral discount
            # handled in setup_pool_params2
            '''function setLiquidationIncentivePercent(
                address[] calldata loanTokens,
                address[] calldata collateralTokens,
                uint256[] calldata amounts)
                external
                onlyOwner'''

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
        loanClosingsWithGasToken = acct.deploy(LoanClosingsWithGasToken)
        print("Calling replaceContract.")
        bzx.replaceContract(loanClosingsWithGasToken.address)
