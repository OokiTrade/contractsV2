#!/usr/bin/python3

from brownie import *
from brownie.network.contract import InterfaceContainer
from brownie.network.state import _add_contract, _remove_contract

import shared
from munch import Munch

'''deploys = Munch.fromDict({
    "bZxProtocol": True,
    "PriceFeeds": True,
    "SwapsImpl": True,
    "ProtocolMigration": True,
    "ProtocolSettings": True,
    "LoanSettings": True,
    "LoanOpenings": True,
    "LoanMaintenance": True,
    "LoanClosings": True,
})'''

'''
"0x0afBFCe9DB35FFd1dFdF144A788fa196FD08EFe9", # iETH
"0xA1e58F3B1927743393b25f261471E1f2D3D9f0F6", # iSAI
"0xd40C0e7230c5bde65B61B5EDDc3E973f76Aff252", # iDAI

"0xd0A1E359811322d97991E03f863a0C30C2cF029C", # WETH
"0xC4375B7De8af5a38a93548eb8453a498222C4fF2", # SAI
"0x4F96Fe3b7A6Cf9725f59d353F723c1bDb64CA6Aa", # DAI
'''
def main():
    thisNetwork = network.show_active()

    if thisNetwork == "development":
        acct = accounts[0]
    elif thisNetwork == "mainnet" or thisNetwork == "mainnet-fork":
        acct = accounts.load('deployer1')
    else:
        acct = accounts.load('testnet_deployer')
    print("Loaded account",acct)

    constants = shared.Constants()
    addresses = shared.Addresses()

    if thisNetwork == "kovan":
        itokens = [
            "0x9D2015Dd5306C08bDd8530605137d26c04DEDBD8", # fiWETH
            "0xaaC9822F31e5Aefb32bC228DcF259F23B49B9855", # iUSDC
            #"0x8D18c5b71348f69733C34Fd32eC8315BdC8222FB", # iSAI
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
        ]

        collateralTokens = [
            "0xE65D99a06D0Ded0D318E31dB3AE5D77629c625fc", # WETH
            "0x20BdF254Ca63883c3a83424753BB40185AF29cE4", # USDC
            "0xc4B7A70c3694cB1d37A18e6c6bD9271828C382A4", # WBTC
            "0x4893919982648FFeFE4324538D54402387C20198", # MKR
            "0x02357164ba33F299F7654cBB29da29dB38aE1f44", # KNC
            "0x39AC2818e08D285aBE548F77a0819651b8B5d213", # REP
            "0xAc091Ccf1b0c601182f3CCF3EB20F291ABA39029", # BAT
            "0x629B28c5aA5c953Df2511d2E48d316A07eAFb3e3", # ZRX
            "0xFB9325e5f4fC9629525427A1c92c0f4D723500Cf", # LINK
            "0xFCfA14dBc71beE2a2188431Fa15E1f8D57d93c62", # SUSD
            "0x8f746eC7ed5Cc265b90e7AF0f5B07b4406C9dDA8", # DAI
            "0x4c4462c6bca4c92bf41c40f9a4047f35fd296996", # USDT (Tether)
        ]
    elif thisNetwork == "mainnet" or thisNetwork == "mainnet-fork":
        itokens = [
            #"0x6b093998d36f2c7f0cc359441fbb24cc629d5ff0", # iDAI
            "0xb983e01458529665007ff7e0cddecdb74b967eb6", # iETH
            "0x32e4c68b3a4a813b710595aeba7f6b7604ab9c15", # iUSDC
            "0x2ffa85f655752fb2acb210287c60b9ef335f5b6e", # iWBTC
            "0xab45bf58c6482b87da85d6688c4d9640e093be98", # iLEND
            "0x687642347a9282be8fd809d8309910a3f984ac5a", # iKNC
            "0x9189c499727f88f8ecc7dc4eea22c828e6aac015", # iMKR
            #"0x18240bd9c07fa6156ce3f3f61921cc82b2619157", # iBZRX
            "0x463538705e7d22aa7f03ebf8ab09b067e1001b54", # iLINK
            #"0x7f3fe9d492a9a60aebb06d82cba23c6f32cad10b", # iYFI
            "0x7e9997a38a439b2be7ed9c9c4628391d3e055d48", # iUSDT
        ]

        collateralTokens = [
            "0x6b175474e89094c44da98b954eedeac495271d0f", # DAI
            "0xc02aaa39b223fe8d0a0e5c4f27ead9083c756cc2", # ETH
            "0xa0b86991c6218b36c1d19d4a2e9eb0ce3606eb48", # USDC
            "0x2260fac5e5542a773aa44fbcfedf7c193bc2c599", # WBTC
            "0x80fB784B7eD66730e8b1DBd9820aFD29931aab03", # LEND
            "0xdd974d5c2e2928dea5f71b9825b8b646686bd200", # KNC
            "0x9f8f72aa9304c8b593d555f12ef6589cc3a579a2", # MKR
            #"0x56d811088235F11C8920698a204A5010a788f4b3", # BZRX
            "0x514910771AF9Ca656af840dff83E8264EcF986CA", # LINK
            #"0x0bc529c00C6401aEF6D220BE8C6Ea1667F6Ad93e", # YFI
            "0xdac17f958d2ee523a2206206994597c13d831ec7", # USDT
        ]
    else:
        return

    for loanPoolAddress in itokens:
        if thisNetwork == "development":
            raise Exception("Development netowrk unsupported")
            #loanToken = acct.deploy(LoanTokenLogicStandard)
            #loanTokenSettings = acct.deploy(LoanTokenSettingsLowerAdmin)
        elif thisNetwork == "kovan":
            loanToken = Contract.from_abi("loanToken", address=loanPoolAddress, abi=LoanTokenLogicStandard.abi, owner=acct)
            loanTokenSettings = Contract.from_abi("loanToken", address="0xa1FB8F53678885D952dcdAeDf63E7fbf1F3e909f", abi=LoanTokenSettingsLowerAdmin.abi, owner=acct)
            #loanTokenSettings = acct.deploy(LoanTokenSettingsLowerAdmin)
        elif thisNetwork == "mainnet" or thisNetwork == "mainnet-fork":
            loanToken = Contract.from_abi("loanToken", address=loanPoolAddress, abi=LoanTokenLogicStandard.abi, owner=acct)
            loanTokenSettings = Contract.from_abi("loanToken", address="0xe934a491e10c72Eec085561BdC02F79e6a2c641D", abi=LoanTokenSettingsLowerAdmin.abi, owner=acct)
            #loanTokenSettings = acct.deploy(LoanTokenSettingsLowerAdmin)
        else:
            return

        loanTokenAddress = loanToken.loanTokenAddress()
        #print(loanTokenAddress)

        #sig = web3.sha3(text="setupLoanParams((bytes32,bool,address,address,address,uint256,uint256,uint256)[],bool)").hex()[:10]
        base_data = [
            b"0x0", ## id
            False, ## active
            str(acct), ## owner
            constants.ZERO_ADDRESS, ## loanToken
            constants.ZERO_ADDRESS, ## collateralToken
            Wei("20 ether"), ## minInitialMargin
            Wei("15 ether"), ## maintenanceMargin
            0 ## fixedLoanTerm
        ]
        
        #### Setup Torque Params
        '''print("\nSetting up Torque for "+loanToken.address+".")
        params = []
        for collateralToken in collateralTokens: #collateralTokensFull:
            if collateralToken == loanTokenAddress or collateralToken == loanToken.address:
                continue
            base_data_copy = base_data.copy()
            base_data_copy[4] = collateralToken ## collateralToken
            base_data_copy[5] = Wei("50 ether") ## minInitialMargin
            params.append(base_data_copy)

        calldata = loanTokenSettings.setupLoanParams.encode_input(params, True)
        
        print(calldata)
        loanToken.updateSettings(loanTokenSettings.address, calldata, { "from": acct })'''


        print("\nSetting up Fulcrum for "+loanToken.address+".")
        params = []
        for collateralToken in collateralTokens:
            if collateralToken == loanTokenAddress or collateralToken == loanToken.address:
                continue
            base_data_copy = base_data.copy()
            base_data_copy[4] = collateralToken ## collateralToken
            base_data_copy[5] = Wei("20 ether") ## minInitialMargin
            params.append(base_data_copy)

        calldata = loanTokenSettings.setupLoanParams.encode_input(params, False)
        
        print(calldata)
        #print("")
        #print(loanToken.updateSettings.encode_input(loanTokenSettings.address, calldata))
        loanToken.updateSettings(loanTokenSettings.address, calldata, { "from": acct, "gas_price": 420e9 })


