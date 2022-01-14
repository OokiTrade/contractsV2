#!/usr/bin/python3


'''
Polygon Addresses ->

bzxAddress: 0x059D60a9CEfBc70b9Ea9FFBb9a041581B1dFA6a8
TokenRegistry: 0x4B234781Af34E9fD756C27a47675cbba19DC8765
HelperProxy: 0xdb2800b894FDa88F6c49c38379398b257062dF80
DAppHelper: 0x15bFe513e143D7CBC3242265B4AA481D81196301

iMATIC: 0x81b91c9a68b94f88f3dfc4f375f101223ddd5007
iETH: 0xB8329B5458B1E493EFd8D9DA8C3B5E6D68e67C21
iWBTC: 0x1a7189Af4e5f58Ddd0b9B195a53E5f4e4b55c949
iLINK: 0x76F3Fca193Aa9aD86347F70D82F013c19060D22C
iUSDC: 0xC3f6816C860e7d7893508C8F8568d5AF190f6d7d
iUSDT: 0x5BFAC8a40782398fb662A69bac8a89e6EDc574b1
'''

from brownie import *
from brownie import network, accounts
from brownie.network.contract import InterfaceContainer
from brownie.network.state import _add_contract, _remove_contract
from brownie.network.contract import Contract
import time
import pdb

acct = accounts.load("fresh_deployer1")

bzxAddress = "0x059D60a9CEfBc70b9Ea9FFBb9a041581B1dFA6a8"

bzx = Contract.from_abi("bzx", address=bzxAddress,
    abi=interface.IBZx.abi, owner=acct)


def main():

    #deployment()
    #marginSettings()
    #demandCurve()
    '''updateOwner()'''

def deployment():
    underlyingSymbol = "USDT"
    iTokenSymbol = "i{}".format(underlyingSymbol)
    iTokenName = "Fulcrum {} iToken ({})".format(underlyingSymbol, iTokenSymbol)  

    loanTokenAddress = "0xc2132D05D31c914a87C6611C10748AEb04B58e8F"

    #LoanTokenLogicStandard deployed at: 0xa9651b36101E00E43dA389A2b491E94Ca9F807b6
    loanTokenLogicStandard = Contract.from_abi(
        "LoanTokenLogicStandard", address="0xb1F7F49245e98519cE617F1bFE403fd28e23E4Cc", abi=LoanTokenLogicStandard.abi, owner=acct)
    #loanTokenLogicStandard = acct.deploy(LoanTokenLogicWeth, acct).address

    
    # Deployment

    iTokenProxy = LoanToken.deploy(acct, loanTokenLogicStandard, {"from": acct})
    #iTokenProxy = Contract.from_abi("loanTokenProxy",
    #                        "0x81b91c9a68b94f88f3dfc4f375f101223ddd5007", LoanToken.abi, acct)

    #loanTokenSettings = acct.deploy(LoanTokenSettings)
    #LoanTokenSettingsLowerAdmin deployed at: 0xA1988005a5D6e68a3572F43a18460708CB29ABe0
    #LoanTokenSettings deployed at: 0xbB4e3A0A540819EfdF0A9C88dFcD9B1D628802dF

    loanTokenSettings = Contract.from_abi(
        "loanToken", address="0x3ff9BFe18206f81d073e35072b1c4D61f866663f", abi=LoanTokenSettings.abi, owner=acct)

    iToken = Contract.from_abi("loanTokenLogicStandard",
                            iTokenProxy, LoanTokenLogicStandard.abi, acct)

    calldata = loanTokenSettings.initialize.encode_input(
        loanTokenAddress, iTokenName, iTokenSymbol)
    iToken.updateSettings(loanTokenSettings, calldata, {"from": acct})

    calldata = loanTokenSettings.setLowerAdminValues.encode_input(
        "0x01F569df8A270eCA78597aFe97D30c65D8a8ca80", # polygon guardian multisig
        "0x91EB15A8EC9aE2280B7003824b2d1e9Caf802b6C"  # LoanTokenSettingsLowerAdmin contract
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
        "loanToken", address="0x91EB15A8EC9aE2280B7003824b2d1e9Caf802b6C", abi=LoanTokenSettingsLowerAdmin.abi, owner=acct)
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
    
    bzxRegistry = Contract.from_abi("bzxRegistry", address="0x4B234781Af34E9fD756C27a47675cbba19DC8765", abi=TokenRegistry.abi)
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
        print("itoken", existingIToken.name(), tokenAssetPairA[0])

        ## only AUTO
        #if existingITokenLoanTokenAddress != "0xa184088a740c695E156F91f5cC086a06bb78b827":
        #    continue

        for tokenAssetPairB in supportedTokenAssetsPairs:

            collateralTokenAddress = tokenAssetPairB[1]

            if collateralTokenAddress == existingITokenLoanTokenAddress:
                continue

            ## skipping BZRX for now
            #if existingITokenLoanTokenAddress == "0x54cFe73f2c7d0c4b62Ab869B473F5512Dc0944D2" or collateralTokenAddress == "0x54cFe73f2c7d0c4b62Ab869B473F5512Dc0944D2":
            #    continue

            ## only BZRX for now
            #if existingITokenLoanTokenAddress != "0x54cFe73f2c7d0c4b62Ab869B473F5512Dc0944D2" and collateralTokenAddress != "0x54cFe73f2c7d0c4b62Ab869B473F5512Dc0944D2":
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


            if ((existingITokenLoanTokenAddress == "0x2791Bca1f2de4661ED88A30C99A7a9449Aa84174" and collateralTokenAddress == "0xc2132D05D31c914a87C6611C10748AEb04B58e8F")
                or (existingITokenLoanTokenAddress == "0xc2132D05D31c914a87C6611C10748AEb04B58e8F" and collateralTokenAddress == "0x2791Bca1f2de4661ED88A30C99A7a9449Aa84174")):
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

    bzxRegistry = Contract.from_abi("bzxRegistry", address="0x4B234781Af34E9fD756C27a47675cbba19DC8765", abi=TokenRegistry.abi)
    supportedTokenAssetsPairs = bzxRegistry.getTokens(0, 100) # TODO move this into a loop for permissionless to support more than 100

    loanTokenSettingsLowerAdmin = Contract.from_abi(
        "loanToken", address="0x91EB15A8EC9aE2280B7003824b2d1e9Caf802b6C", abi=LoanTokenSettingsLowerAdmin.abi, owner=acct)

    for tokenAssetPairA in supportedTokenAssetsPairs:
        
        ## no BZRX params
        #if (tokenAssetPairA[0] == "0x97dfbEF4eD5a7f63781472Dbc69Ab8e5d7357cB9"):
        #    continue

        ## only BZRX params
        #if (tokenAssetPairA[0] != "0x97dfbEF4eD5a7f63781472Dbc69Ab8e5d7357cB9"):
        #    continue

        '''if (tokenAssetPairA[0] != "0xda4f261f26c82766408dcf6ba1b510fa8e64efe9" and tokenAssetPairA[0] != "0xC5b6cC0A9D61600BE42e83d8fA1331dB9E29e48C"):
            continue'''

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

    guardian_multisig = "0x01F569df8A270eCA78597aFe97D30c65D8a8ca80"

    ## bZxProtocol
    c = Contract.from_abi("c", address="0x059d60a9cefbc70b9ea9ffbb9a041581b1dfa6a8", abi=LoanToken.abi, owner=acct)
    print("old owner:", c.owner())
    c.transferOwnership(guardian_multisig, {"from": acct})
    print("new owner:", c.owner())
    print("----")

    ## PriceFeeds_POLYGON
    c = Contract.from_abi("c", address="0x600F8E7B10CF6DA18871Ff79e4A61B13caCEd9BC", abi=LoanToken.abi, owner=acct)
    print("old owner:", c.owner())
    c.transferOwnership(guardian_multisig, {"from": acct})
    print("new owner:", c.owner())
    print("----")

    ## SwapsImplUniswapV2_POLYGON
    c = Contract.from_abi("c", address="0x463c80e2c99965791865612EdD0C81C26AB5EbEC", abi=LoanToken.abi, owner=acct)
    print("old owner:", c.owner())
    c.transferOwnership(guardian_multisig, {"from": acct})
    print("new owner:", c.owner())
    print("----")

    ## HelperProxy
    c = Contract.from_abi("c", address="0xdb2800b894FDa88F6c49c38379398b257062dF80", abi=LoanToken.abi, owner=acct)
    print("old owner:", c.owner())
    c.transferOwnership(guardian_multisig, {"from": acct})
    print("new owner:", c.owner())
    print("----")

    ## FeeExtractAndDistribute_Polygon_proxy
    c = Contract.from_abi("c", address="0xf970FA9E6797d0eBfdEE8e764FC5f3123Dc6befD", abi=LoanToken.abi, owner=acct)
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
    c = Contract.from_abi("c", address="0x91c78Bd238AcC14459673d5cf4fE460AeE7BF692", abi=LoanToken.abi, owner=acct)
    print("old owner:", c.owner())
    c.transferOwnership(guardian_multisig, {"from": acct})
    print("new owner:", c.owner())
    print("----")

    bzxRegistry = Contract.from_abi("bzxRegistry", address="0x4B234781Af34E9fD756C27a47675cbba19DC8765", abi=TokenRegistry.abi)
    supportedTokenAssetsPairs = bzxRegistry.getTokens(0, 100) # TODO move this into a loop for permissionless to support more than 100

    for tokenAssetPairA in supportedTokenAssetsPairs:

        existingIToken = Contract.from_abi("existingIToken", address=tokenAssetPairA[0], abi=LoanToken.abi, owner=acct)
        print("itoken", existingIToken.name(), tokenAssetPairA[0])
        print("old owner:", existingIToken.owner())
        existingIToken.transferOwnership(guardian_multisig, {"from": acct})
        print("new owner:", existingIToken.owner())
        print("----")
'''