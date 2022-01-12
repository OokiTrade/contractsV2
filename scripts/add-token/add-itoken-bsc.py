#!/usr/bin/python3


'''
BSC Addresses ->

bzxAddress: 0xD154eE4982b83a87b0649E5a7DDA1514812aFE1f
TokenRegistry: 0x1BE70f29D30bB1D325E5D76Ee73109de3e50A57d
HelperProxy: 0x81B91c9a68b94F88f3DFC4F375f101223dDd5007
DAppHelper: 0x91EB15A8EC9aE2280B7003824b2d1e9Caf802b6C

iBNB: 0xB8329B5458B1E493EFd8D9DA8C3B5E6D68e67C21
iBUSD: 0x1a7189Af4e5f58Ddd0b9B195a53E5f4e4b55c949
iETH: 0x76F3Fca193Aa9aD86347F70D82F013c19060D22C
iUSDT: 0xC3f6816C860e7d7893508C8F8568d5AF190f6d7d
iBTC: 0x5BFAC8a40782398fb662A69bac8a89e6EDc574b1
iLINK: 0x4B234781Af34E9fD756C27a47675cbba19DC8765
'''

from brownie import *
from brownie import network, accounts
from brownie.network.contract import InterfaceContainer
from brownie.network.state import _add_contract, _remove_contract
from brownie.network.contract import Contract
import time
import pdb

acct = accounts.load("fresh_deployer1")

bzxAddress = "0xD154eE4982b83a87b0649E5a7DDA1514812aFE1f"

bzx = Contract.from_abi("bzx", address=bzxAddress,
    abi=interface.IBZx.abi, owner=acct)


def main():

    #deployment()
    #marginSettings()
    #demandCurve()
    '''updateOwner()'''

def deployment():
    underlyingSymbol = "LINK"
    iTokenSymbol = "i{}".format(underlyingSymbol)
    iTokenName = "Fulcrum {} iToken ({})".format(underlyingSymbol, iTokenSymbol)  

    loanTokenAddress = "0xf8a0bf9cf54bb92f17374d9e9a321e6a111a51bd"

    #LoanTokenLogicStandard deployed at: 0xa9651b36101E00E43dA389A2b491E94Ca9F807b6
    loanTokenLogicStandard = Contract.from_abi(
        "LoanTokenLogicStandard", address="0xb1F7F49245e98519cE617F1bFE403fd28e23E4Cc", abi=LoanTokenLogicStandard.abi, owner=acct)
    #loanTokenLogicStandard = acct.deploy(LoanTokenLogicWeth, acct).address

    
    # Deployment

    iTokenProxy = LoanToken.deploy(acct, loanTokenLogicStandard, {"from": acct})
    #iTokenProxy = Contract.from_abi("loanTokenProxy",
    #                        "0x4B234781Af34E9fD756C27a47675cbba19DC8765", LoanToken.abi, acct)

    #loanTokenSettings = acct.deploy(LoanTokenSettings)
    #LoanTokenSettingsLowerAdmin deployed at: 0x86003099131d83944d826F8016E09CC678789A30
    #LoanTokenSettings deployed at: 0xbB4e3A0A540819EfdF0A9C88dFcD9B1D628802dF

    loanTokenSettings = Contract.from_abi(
        "loanToken", address="0x5E88C676808B87974807f918790181E1e9af20fE", abi=LoanTokenSettings.abi, owner=acct)

    iToken = Contract.from_abi("loanTokenLogicStandard",
                            iTokenProxy, LoanTokenLogicStandard.abi, acct)

    calldata = loanTokenSettings.initialize.encode_input(
        loanTokenAddress, iTokenName, iTokenSymbol)
    iToken.updateSettings(loanTokenSettings, calldata, {"from": acct})

    calldata = loanTokenSettings.setLowerAdminValues.encode_input(
        "0x82cedB275BF513447300f670708915F99f085FD6", # bsc guardian multisig
        "0x86003099131d83944d826F8016E09CC678789A30"  # LoanTokenSettingsLowerAdmin contract
    )
    iToken.updateSettings(loanTokenSettings, calldata, {"from": acct})


    # Setting price Feed
    #priceFeed = Contract.from_abi(
    #    "pricefeed", bzx.priceFeeds(), abi=PriceFeeds.abi, owner=acct)
    #priceFeed.setPriceFeed([loanTokenAddress], [chainlinkFeedAddress], {'from': acct})


    bzx.setLoanPool([iToken], [loanTokenAddress], {"from": acct})
    #bzx.setSupportedTokens([loanTokenAddress], [True])



def marginSettings():

    # Setting margin settings

    loanTokenSettingsLowerAdmin = Contract.from_abi(
        "loanToken", address="0x86003099131d83944d826F8016E09CC678789A30", abi=LoanTokenSettingsLowerAdmin.abi, owner=acct)
    base_data = [
        b"0x0",  # id
        False,  # active
        str(acct),  # owner
        "0x0000000000000000000000000000000000000001",  # loanToken
        "0x0000000000000000000000000000000000000002",  # collateralToken
        Wei("20 ether"),  # minInitialMargin
        Wei("15 ether"),  # maintenanceMargin
        0  # fixedLoanTerm
    ]

    params = []
    
    bzxRegistry = Contract.from_abi("bzxRegistry", address="0x1BE70f29D30bB1D325E5D76Ee73109de3e50A57d", abi=TokenRegistry.abi)
    supportedTokenAssetsPairs = bzxRegistry.getTokens(0, 100) # TODO move this into a loop for permissionless to support more than 100
    loanTokensArr = []
    collateralTokensArr = []
    amountsArr = []

    for tokenAssetPairA in supportedTokenAssetsPairs:

        params.clear()
        loanTokensArr.clear()
        collateralTokensArr.clear()
        amountsArr.clear()

        # below is to allow new iToken.loanTokenAddress in other existing iTokens
        existingIToken = Contract.from_abi("existingIToken", address=tokenAssetPairA[0], abi=LoanTokenLogicStandard.abi, owner=acct)
        existingITokenLoanTokenAddress = existingIToken.loanTokenAddress()
        print("itoken", existingIToken.name(), existingITokenLoanTokenAddress)

        ## only AUTO
        #if existingITokenLoanTokenAddress != "0xa184088a740c695E156F91f5cC086a06bb78b827":
        #    continue

        for tokenAssetPairB in supportedTokenAssetsPairs:

            collateralTokenAddress = tokenAssetPairB[1]

            if collateralTokenAddress == existingITokenLoanTokenAddress:
                continue

            ## skipping BZRX for now
            #if existingITokenLoanTokenAddress == "0x4b87642AEDF10b642BE4663Db842Ecc5A88bf5ba" or collateralTokenAddress == "0x4b87642AEDF10b642BE4663Db842Ecc5A88bf5ba":
            #    continue

            ## only BZRX for now
            #if existingITokenLoanTokenAddress != "0x4b87642AEDF10b642BE4663Db842Ecc5A88bf5ba" and collateralTokenAddress != "0x4b87642AEDF10b642BE4663Db842Ecc5A88bf5ba":
            #    continue
            '''
                        "0x0E09FaBB73Bd3Ade0a17ECC321fD13a19e81cE82", # CAKE
                        "0xa184088a740c695E156F91f5cC086a06bb78b827", # AUTO
                        "0xbA2aE424d960c26247Dd6c32edC70B295c744C43", # DOGE
            '''
            ## only CAKE, AUTO, or DOGE params
            '''if (
                (existingITokenLoanTokenAddress != "0x0E09FaBB73Bd3Ade0a17ECC321fD13a19e81cE82" and collateralTokenAddress != "0x0E09FaBB73Bd3Ade0a17ECC321fD13a19e81cE82") and
                (existingITokenLoanTokenAddress != "0xa184088a740c695E156F91f5cC086a06bb78b827" and collateralTokenAddress != "0xa184088a740c695E156F91f5cC086a06bb78b827")):
                #(existingITokenLoanTokenAddress != "0xbA2aE424d960c26247Dd6c32edC70B295c744C43" and collateralTokenAddress != "0xbA2aE424d960c26247Dd6c32edC70B295c744C43")):
                continue'''

            base_data_copy = base_data.copy()
            base_data_copy[3] = existingITokenLoanTokenAddress
            base_data_copy[4] = collateralTokenAddress # pair is iToken, Underlying
               
            if ((existingITokenLoanTokenAddress == "0xe9e7CEA3DedcA5984780Bafc599bD69ADd087D56" and collateralTokenAddress == "0x55d398326f99059ff775485246999027b3197955")
                or (existingITokenLoanTokenAddress == "0x55d398326f99059ff775485246999027b3197955" and collateralTokenAddress == "0xe9e7CEA3DedcA5984780Bafc599bD69ADd087D56")):
                base_data_copy[5] = "6666666666666666666"  # minInitialMargin
                base_data_copy[6] = Wei("5 ether")  # maintenanceMargin
            else:
                base_data_copy[5] = Wei("20 ether")  # minInitialMargin
                base_data_copy[6] = Wei("15 ether")  # maintenanceMargin
            
            #print(base_data_copy)
            params.append(base_data_copy)

            loanTokensArr.append(existingITokenLoanTokenAddress)
            collateralTokensArr.append(collateralTokenAddress)
            amountsArr.append(7*10**18)

        print(params)
        if (len(params) != 0):
            ## Torque loans
            calldata = loanTokenSettingsLowerAdmin.setupLoanParams.encode_input(params, True)
            existingIToken.updateSettings(loanTokenSettingsLowerAdmin.address, calldata, {"from": acct})

            ## Margin trades
            calldata = loanTokenSettingsLowerAdmin.setupLoanParams.encode_input(params, False)
            existingIToken.updateSettings(loanTokenSettingsLowerAdmin.address, calldata, {"from": acct})

        bzx.setLiquidationIncentivePercent(loanTokensArr, collateralTokensArr, amountsArr, {"from": acct})


def demandCurve():

    bzxRegistry = Contract.from_abi("bzxRegistry", address="0x1BE70f29D30bB1D325E5D76Ee73109de3e50A57d", abi=TokenRegistry.abi)
    supportedTokenAssetsPairs = bzxRegistry.getTokens(0, 100) # TODO move this into a loop for permissionless to support more than 100

    loanTokenSettingsLowerAdmin = Contract.from_abi(
        "loanToken", address="0x86003099131d83944d826F8016E09CC678789A30", abi=LoanTokenSettingsLowerAdmin.abi, owner=acct)

    for tokenAssetPairA in supportedTokenAssetsPairs:
        
        ## no BZRX params
        #if (tokenAssetPairA[0] == "0xA726F2a7B200b03beB41d1713e6158e0bdA8731F"):
        #    continue

        ## only BZRX params
        #if (tokenAssetPairA[0] != "0xA726F2a7B200b03beB41d1713e6158e0bdA8731F"):
        #    continue

        #if (tokenAssetPairA[0] != "0xda4f261f26c82766408dcf6ba1b510fa8e64efe9" and tokenAssetPairA[0] != "0xC5b6cC0A9D61600BE42e83d8fA1331dB9E29e48C"):
        #    continue

        #existingITokenLoanTokenAddress = tokenAssetPairA[1]
        #collateralTokenAddress = tokenAssetPairA[1]

        ## only CAKE, AUTO, or DOGE params
        '''if (
            (existingITokenLoanTokenAddress != "0x0E09FaBB73Bd3Ade0a17ECC321fD13a19e81cE82" and collateralTokenAddress != "0x0E09FaBB73Bd3Ade0a17ECC321fD13a19e81cE82") and
            (existingITokenLoanTokenAddress != "0xa184088a740c695E156F91f5cC086a06bb78b827" and collateralTokenAddress != "0xa184088a740c695E156F91f5cC086a06bb78b827") and
            (existingITokenLoanTokenAddress != "0xbA2aE424d960c26247Dd6c32edC70B295c744C43" and collateralTokenAddress != "0xbA2aE424d960c26247Dd6c32edC70B295c744C43")):
            continue'''

        existingIToken = Contract.from_abi("existingIToken", address=tokenAssetPairA[0], abi=LoanTokenLogicStandard.abi, owner=acct)
        print("itoken", existingIToken.name(), tokenAssetPairA[0])
        
        calldata = loanTokenSettingsLowerAdmin.setDemandCurve.encode_input(0, 20*10**18, 0, 0, 60*10**18, 80*10**18, 120*10**18)
        existingIToken.updateSettings(loanTokenSettingsLowerAdmin.address, calldata, {"from": acct})

'''
def updateOwner():

    guardian_multisig = "0x82cedB275BF513447300f670708915F99f085FD6"

    ## bZxProtocol
    c = Contract.from_abi("c", address="0xD154eE4982b83a87b0649E5a7DDA1514812aFE1f", abi=LoanToken.abi, owner=acct)
    print("old owner:", c.owner())
    c.transferOwnership(guardian_multisig, {"from": acct})
    print("new owner:", c.owner())
    print("----")

    ## PriceFeeds_BSC
    c = Contract.from_abi("c", address="0x43CCac29802332e1fd3A41264dDbe34cE3073a88", abi=LoanToken.abi, owner=acct)
    print("old owner:", c.owner())
    c.transferOwnership(guardian_multisig, {"from": acct})
    print("new owner:", c.owner())
    print("----")

    ## SwapsImplUniswapV2_BSC
    c = Contract.from_abi("c", address="0x6cb2adf7adb4efce3b10ce8933d8a8d70dba7f78", abi=LoanToken.abi, owner=acct)
    print("old owner:", c.owner())
    c.transferOwnership(guardian_multisig, {"from": acct})
    print("new owner:", c.owner())
    print("----")

    ## HelperProxy
    c = Contract.from_abi("c", address="0x81B91c9a68b94F88f3DFC4F375f101223dDd5007", abi=LoanToken.abi, owner=acct)
    print("old owner:", c.owner())
    c.transferOwnership(guardian_multisig, {"from": acct})
    print("new owner:", c.owner())
    print("----")

    ## FeeExtractAndDistribute_BSC_proxy
    c = Contract.from_abi("c", address="0x5c9b515f05a0E2a9B14C171E2675dDc1655D9A1c", abi=LoanToken.abi, owner=acct)
    print("old owner:", c.owner())
    c.transferOwnership(guardian_multisig, {"from": acct})
    print("new owner:", c.owner())
    print("----")

    ## TokenHolder
    c = Contract.from_abi("c", address="0x55Eb3DD3f738cfdda986B8Eff3fa784477552C61", abi=LoanToken.abi, owner=acct)
    print("old owner:", c.owner())
    c.transferOwnership(guardian_multisig, {"from": acct})
    print("new owner:", c.owner())
    print("----")

    ## FixedSwapTokenConverter
    c = Contract.from_abi("c", address="0x5531188E72e63ee80e695099b36a15FDdDcEE6Aa", abi=LoanToken.abi, owner=acct)
    print("old owner:", c.owner())
    c.transferOwnership(guardian_multisig, {"from": acct})
    print("new owner:", c.owner())
    print("----")

    bzxRegistry = Contract.from_abi("bzxRegistry", address="0x1BE70f29D30bB1D325E5D76Ee73109de3e50A57d", abi=TokenRegistry.abi)
    supportedTokenAssetsPairs = bzxRegistry.getTokens(0, 100) # TODO move this into a loop for permissionless to support more than 100

    for tokenAssetPairA in supportedTokenAssetsPairs:

        existingIToken = Contract.from_abi("existingIToken", address=tokenAssetPairA[0], abi=LoanToken.abi, owner=acct)
        print("itoken", existingIToken.name(), tokenAssetPairA[0])
        print("old owner:", existingIToken.owner())
        existingIToken.transferOwnership(guardian_multisig, {"from": acct})
        print("new owner:", existingIToken.owner())
        print("----")
'''