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
    elif thisNetwork == "sandbox":
        acct = accounts.load('mainnet_deployer')
    else:
        acct = accounts.load('testnet_deployer')
    print("Loaded account",acct)

    constants = shared.Constants()
    addresses = shared.Addresses()

    if thisNetwork == "kovan":
        itokens = [
            "0x0afBFCe9DB35FFd1dFdF144A788fa196FD08EFe9", # iETH
            #"0xA1e58F3B1927743393b25f261471E1f2D3D9f0F6", # iSAI
            "0xd40C0e7230c5bde65B61B5EDDc3E973f76Aff252", # iDAI
            "0x988F40e4B07aC9b5e78533282Ba14a57440827e8"  # iKNC
        ]

        '''collateralTokensFull = [
            "0xd0A1E359811322d97991E03f863a0C30C2cF029C", # WETH
            #"0xC4375B7De8af5a38a93548eb8453a498222C4fF2", # SAI
            "0x4F96Fe3b7A6Cf9725f59d353F723c1bDb64CA6Aa", # DAI
            "0xad67cB4d63C9da94AcA37fDF2761AaDF780ff4a2", # KNC
            "0x0afBFCe9DB35FFd1dFdF144A788fa196FD08EFe9", # iETH
            #"0xA1e58F3B1927743393b25f261471E1f2D3D9f0F6", # iSAI
            "0xd40C0e7230c5bde65B61B5EDDc3E973f76Aff252", # iDAI
            "0x988F40e4B07aC9b5e78533282Ba14a57440827e8"  # iKNC
        ]'''

        collateralTokens = [
            "0xd0A1E359811322d97991E03f863a0C30C2cF029C", # WETH
            #"0xC4375B7De8af5a38a93548eb8453a498222C4fF2", # SAI
            "0x4F96Fe3b7A6Cf9725f59d353F723c1bDb64CA6Aa", # DAI
            "0xad67cB4d63C9da94AcA37fDF2761AaDF780ff4a2", # KNC
        ]
    elif thisNetwork == "sandbox":
        itokens = [
            "0x493c57c4763932315a328269e1adad09653b9081", # iDAI
        ]

        '''collateralTokensFull = [
            "0xc02aaa39b223fe8d0a0e5c4f27ead9083c756cc2", # WETH
            "0x6b175474e89094c44da98b954eedeac495271d0f", # DAI
            "0x77f973FCaF871459aa58cd81881Ce453759281bC", # iETH
            "0x493c57c4763932315a328269e1adad09653b9081", # iDAI
        ]'''

        collateralTokens = [
            "0xc02aaa39b223fe8d0a0e5c4f27ead9083c756cc2", # WETH
            "0x6b175474e89094c44da98b954eedeac495271d0f", # DAI
        ]
        '''itokens = [
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
        ]'''
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
        elif thisNetwork == "sandbox":
            loanToken = Contract.from_abi("loanToken", address=loanPoolAddress, abi=LoanTokenLogicStandard.abi, owner=acct)
            loanTokenSettings = Contract.from_abi("loanToken", address="0x1a88a5B750C88245B4f796aC2Dc7A5d17046Ad19", abi=LoanTokenSettingsLowerAdmin.abi, owner=acct)
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
        print("\nSetting up Torque for "+loanToken.address+".")
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
        loanToken.updateSettings(loanTokenSettings.address, calldata, { "from": acct })


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
        loanToken.updateSettings(loanTokenSettings.address, calldata, { "from": acct })

