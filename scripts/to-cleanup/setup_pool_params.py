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
        acct = accounts.load('testnet_admin')
    print("Loaded account",acct)

    constants = shared.Constants()
    addresses = shared.Addresses()

    if thisNetwork == "kovan":
        itokens = [
            "0xe3d99c2152Fc8eA5F87B733706FAA241C37592f1", # ifWETH
            "0xF6a0690f22da5464924A28a8198E8ecA69ffc47e", # iWBTC
            "0x021C5923398168311Ff320902BF8c8C725B4F288", # iUSDC
        ]

        collateralTokens = [
            "0xfBE16bA4e8029B759D3c5ef8844124893f3ae470", # WETH
            "0x5aE55494Ccda82f1F7c653BC2b6EbB4aD3C77Dac", # WBTC
            "0xB443f30CDd6076b1A5269dbc08b774F222d4Db4e", # USDC
        ]
    elif thisNetwork == "mainnet" or thisNetwork == "mainnet-fork":
        itokens = [
            "0x6b093998d36f2c7f0cc359441fbb24cc629d5ff0", # iDAI
            "0x32e4c68b3a4a813b710595aeba7f6b7604ab9c15", # iUSDC
            "0x7e9997a38a439b2be7ed9c9c4628391d3e055d48", # iUSDT
            "0xb983e01458529665007ff7e0cddecdb74b967eb6", # iETH
            "0x2ffa85f655752fb2acb210287c60b9ef335f5b6e", # iWBTC
            "0x687642347a9282be8fd809d8309910a3f984ac5a", # iKNC
            "0x9189c499727f88f8ecc7dc4eea22c828e6aac015", # iMKR
            "0x18240bd9c07fa6156ce3f3f61921cc82b2619157", # iBZRX
            "0x463538705e7d22aa7f03ebf8ab09b067e1001b54", # iLINK
            "0x7f3fe9d492a9a60aebb06d82cba23c6f32cad10b", # iYFI
            "0x0a625FceC657053Fe2D9FFFdeb1DBb4e412Cf8A8", # iUNI
            "0x0cae8d91E0b1b7Bd00D906E990C3625b2c220db1", # iAAVE
            "0x6d29903BC2c4318b59B35d97Ab98ab9eC08Ed70D", # iCOMP
            "0x3dA0e01472Dee3746b4D324a65D7EdFaECa9Aa4f", # iLRC
            "0x88183Ec0054F40D344e40EC934D5a9E2749a61d4", # iBNB
        ]

        collateralTokens = [
            "0x6b175474e89094c44da98b954eedeac495271d0f", # DAI
            "0xa0b86991c6218b36c1d19d4a2e9eb0ce3606eb48", # USDC
            "0xdac17f958d2ee523a2206206994597c13d831ec7", # USDT
            "0xc02aaa39b223fe8d0a0e5c4f27ead9083c756cc2", # ETH
            "0x2260fac5e5542a773aa44fbcfedf7c193bc2c599", # WBTC
            "0xdd974d5c2e2928dea5f71b9825b8b646686bd200", # KNC
            "0x9f8f72aa9304c8b593d555f12ef6589cc3a579a2", # MKR
            "0x56d811088235F11C8920698a204A5010a788f4b3", # BZRX
            "0x514910771AF9Ca656af840dff83E8264EcF986CA", # LINK
            "0x0bc529c00C6401aEF6D220BE8C6Ea1667F6Ad93e", # YFI
            "0x1f9840a85d5aF5bf1D1762F925BDADdC4201F984", # UNI
            "0x7Fc66500c84A76Ad7e9c93437bFc5Ac33E2DDaE9", # AAVE
            "0xc00e94Cb662C3520282E6f5717214004A7f26888", # COMP
            "0xBBbbCA6A901c926F240b89EacB641d8Aec7AEafD", # LRC
            "0xB8c77482e45F1F44dE1745F52C74426C631bDD52", # BNB
        ]
    else:
        return

    for loanPoolAddress in itokens:
        #if loanPoolAddress == "0x0a625FceC657053Fe2D9FFFdeb1DBb4e412Cf8A8" or loanPoolAddress == "0x0cae8d91E0b1b7Bd00D906E990C3625b2c220db1":
        #    continue

        if thisNetwork == "development":
            raise Exception("Development netowrk unsupported")
            #loanToken = acct.deploy(LoanTokenLogicStandard)
            #loanTokenSettings = acct.deploy(LoanTokenSettingsLowerAdmin)
        elif thisNetwork == "kovan":
            loanToken = Contract.from_abi("loanToken", address=loanPoolAddress, abi=LoanTokenLogicStandard.abi, owner=acct)
            loanTokenSettings = Contract.from_abi("loanToken", address="0x96305EA01086424b5E822f0B6bD01197A7768518", abi=LoanTokenSettingsLowerAdmin.abi, owner=acct)
            #loanTokenSettings = acct.deploy(LoanTokenSettingsLowerAdmin)
        elif thisNetwork == "mainnet" or thisNetwork == "mainnet-fork":
            loanToken = Contract.from_abi("loanToken", address=loanPoolAddress, abi=LoanTokenLogicStandard.abi, owner=acct)
            loanTokenSettings = Contract.from_abi("loanToken", address="0xcd273a029fB6aaa89ca9A7101C5901b1f429d457", abi=LoanTokenSettingsLowerAdmin.abi, owner=acct)
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
            
            '''
            "0x18240bd9c07fa6156ce3f3f61921cc82b2619157", # iBZRX
            "0x56d811088235F11C8920698a204A5010a788f4b3", # BZRX

            "0x6b093998d36f2c7f0cc359441fbb24cc629d5ff0", # iDAI
            "0x32e4c68b3a4a813b710595aeba7f6b7604ab9c15", # iUSDC
            "0x7e9997a38a439b2be7ed9c9c4628391d3e055d48", # iUSDT

            "0x6b175474e89094c44da98b954eedeac495271d0f", # DAI
            "0xa0b86991c6218b36c1d19d4a2e9eb0ce3606eb48", # USDC
            "0xdac17f958d2ee523a2206206994597c13d831ec7", # USDT
            '''

            if not (
                loanPoolAddress == "0x18240bd9c07fa6156ce3f3f61921cc82b2619157" or
                collateralToken == "0x56d811088235F11C8920698a204A5010a788f4b3"):
                continue

            base_data_copy = base_data.copy()
            base_data_copy[4] = collateralToken ## collateralToken
            base_data_copy[5] = Wei("20 ether") ## minInitialMargin
            params.append(base_data_copy)

        if (len(params) == 0):
            continue
        calldata = loanTokenSettings.setupLoanParams.encode_input(params, False)
        
        print(calldata)
        #print("")
        #print(loanToken.updateSettings.encode_input(loanTokenSettings.address, calldata))
        #loanToken.updateSettings(loanTokenSettings.address, calldata, { "from": acct, "gas_price": 175e9, "required_confs": 0 })


