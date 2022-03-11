#!/usr/bin/python3


'''
Arbitrum Addresses ->

bzxAddress: 0x37407F3178ffE07a6cF5C847F8f680FEcf319FAB
TokenRegistry: 0x86003099131d83944d826F8016E09CC678789A30
HelperProxy: 0xB8329B5458B1E493EFd8D9DA8C3B5E6D68e67C21
DAppHelper: 0x1BE70f29D30bB1D325E5D76Ee73109de3e50A57d

iETH: 0xE602d108BCFbB7f8281Fd0835c3CF96e5c9B5486
iBTC: 0x4eBD7e71aFA27506EfA4a4783DFbFb0aD091701e
iSPELL: 0x05a3a6C19efb00aB01fC7f0C8c4B8D2109d7Dc5A
iLINK: 0x76F3Fca193Aa9aD86347F70D82F013c19060D22C
iUSDC: 0xEDa7f294844808B7C93EE524F990cA7792AC2aBd
iUSDT: 0xd103a2D544fC02481795b0B33eb21DE430f3eD23
iMIM: 0x7Dcc818B91062213CB57b525108d97236068076b
iFRAX: 0xC3f6816C860e7d7893508C8F8568d5AF190f6d7d
'''

from brownie import *
from brownie import network, accounts
from brownie.network.contract import InterfaceContainer
from brownie.network.state import _add_contract, _remove_contract
from brownie.network.contract import Contract
import time
import pdb

acct = accounts.load("fresh_deployer1")

bzxAddress = "0x37407F3178ffE07a6cF5C847F8f680FEcf319FAB"

bzx = Contract.from_abi("bzx", address=bzxAddress,
    abi=interface.IBZx.abi, owner=acct)


def main():

    #deployment()
    #marginSettings()
    #demandCurve()
    '''updateOwner()'''

def deployment():
    underlyingSymbol = "ETH"
    iTokenSymbol = "i{}".format(underlyingSymbol)
    iTokenName = "Ooki {} iToken ({})".format(underlyingSymbol, iTokenSymbol)  

    loanTokenAddress = "0x82af49447d8a07e3bd95bd0d56f35241523fbab1"
    proxyAddress = "0xE602d108BCFbB7f8281Fd0835c3CF96e5c9B5486"
    '''
            "0x82af49447d8a07e3bd95bd0d56f35241523fbab1", # ETH
            "0x2f2a2543b76a4166549f7aab2e75bef0aefc5b0f", # BTC
            "0x3e6648c5a70a150a88bce65f4ad4d506fe15d2af", # SPELL
            "0xf97f4df75117a78c1A5a0DBb814Af92458539FB4", # LINK
            "0xff970a61a04b1ca14834a43f5de4533ebddb5cc8", # USDC
            "0xfd086bc7cd5c481dcc9c85ebe478a1c0b69fcbb9", # USDT
            "0xfea7a6a0b346362bf88a9e4a88416b77a57d6c2a", # MIM
            "0x17fc002b466eec40dae837fc4be5c67993ddbd6f", # FRAX

iETH: 0xE602d108BCFbB7f8281Fd0835c3CF96e5c9B5486
iBTC: 0x4eBD7e71aFA27506EfA4a4783DFbFb0aD091701e
iSPELL: 0x05a3a6C19efb00aB01fC7f0C8c4B8D2109d7Dc5A
iLINK: 0x76F3Fca193Aa9aD86347F70D82F013c19060D22C
iUSDC: 0xEDa7f294844808B7C93EE524F990cA7792AC2aBd
iUSDT: 0xd103a2D544fC02481795b0B33eb21DE430f3eD23
iMIM: 0x7Dcc818B91062213CB57b525108d97236068076b
iFRAX: 0xC3f6816C860e7d7893508C8F8568d5AF190f6d7d
    '''

    
    # Deployment

    #iTokenProxy = LoanToken.deploy(acct, loanTokenLogicStandard, {"from": acct})
    iTokenProxy = Contract.from_abi("loanTokenProxy",
                            proxyAddress, LoanToken.abi, acct)

    #iTokenProxy.setTarget("0x6E1e6f1B49b46DFEB61E52441Cc942Ed717E77da")

    #loanTokenSettings = acct.deploy(LoanTokenSettings)
    #LoanTokenSettingsLowerAdmin deployed at: 0x56f0741f0FF5C3a5f47319F4Ca31E68C482DA38c
    #LoanTokenSettings deployed at: 0xeaC17AFaEFC6325927D334Daf304b43d7aa91D5c
    #CurvedInterestRate deployed at: 0x171124e47fE7902E6A63f2d361Ee4F9772c87d07
    #LoanTokenLogicStandard deployed at: 0x6E1e6f1B49b46DFEB61E52441Cc942Ed717E77da

    loanTokenSettings = Contract.from_abi(
        "loanToken", address="0xeaC17AFaEFC6325927D334Daf304b43d7aa91D5c", abi=LoanTokenSettings.abi, owner=acct)

    iToken = Contract.from_abi("loanTokenLogicStandard",
                            iTokenProxy, LoanTokenLogicStandard.abi, acct)

    calldata = loanTokenSettings.initialize.encode_input(
        loanTokenAddress, iTokenName, iTokenSymbol)
    iToken.updateSettings(loanTokenSettings, calldata, {"from": acct})

    calldata = loanTokenSettings.setLowerAdminValues.encode_input(
        "0x111F9F3e59e44e257b24C5d1De57E05c380C07D2", # arbitrum guardian multisig
        "0x56f0741f0FF5C3a5f47319F4Ca31E68C482DA38c"  # LoanTokenSettingsLowerAdmin contract
    )
    iToken.updateSettings(loanTokenSettings, calldata, {"from": acct})

    iToken.updateFlashBorrowFeePercent(0.03e18, {"from": acct})

    # Setting price Feed
    #priceFeed = Contract.from_abi(
    #    "pricefeed", bzx.priceFeeds(), abi=PriceFeeds.abi, owner=acct)
    #priceFeed.setPriceFeed([loanTokenAddress], [chainlinkFeedAddress], {'from': acct})


    #bzx.setLoanPool([iToken], [loanTokenAddress], {"from": acct}) <-- uncomment
    #bzx.setSupportedTokens([loanTokenAddress], [True])


def marginSettings():

    # Setting margin settings

    loanTokenSettingsLowerAdmin = Contract.from_abi(
        "loanToken", address="0x56f0741f0FF5C3a5f47319F4Ca31E68C482DA38c", abi=LoanTokenSettingsLowerAdmin.abi, owner=acct)
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
    
    bzxRegistry = Contract.from_abi("bzxRegistry", address="0x86003099131d83944d826F8016E09CC678789A30", abi=TokenRegistry.abi)
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


            '''
            "0xff970a61a04b1ca14834a43f5de4533ebddb5cc8", # USDC
            "0xfd086bc7cd5c481dcc9c85ebe478a1c0b69fcbb9", # USDT
            "0xfea7a6a0b346362bf88a9e4a88416b77a57d6c2a", # MIM
            "0x17fc002b466eec40dae837fc4be5c67993ddbd6f", # FRAX
            '''
            if ((existingITokenLoanTokenAddress == "0xff970a61a04b1ca14834a43f5de4533ebddb5cc8" and collateralTokenAddress == "0xfd086bc7cd5c481dcc9c85ebe478a1c0b69fcbb9")
                or (existingITokenLoanTokenAddress == "0xff970a61a04b1ca14834a43f5de4533ebddb5cc8" and collateralTokenAddress == "0xfea7a6a0b346362bf88a9e4a88416b77a57d6c2a")
                or (existingITokenLoanTokenAddress == "0xff970a61a04b1ca14834a43f5de4533ebddb5cc8" and collateralTokenAddress == "0x17fc002b466eec40dae837fc4be5c67993ddbd6f")

                or (existingITokenLoanTokenAddress == "0xfd086bc7cd5c481dcc9c85ebe478a1c0b69fcbb9" and collateralTokenAddress == "0xff970a61a04b1ca14834a43f5de4533ebddb5cc8")
                or (existingITokenLoanTokenAddress == "0xfd086bc7cd5c481dcc9c85ebe478a1c0b69fcbb9" and collateralTokenAddress == "0xfea7a6a0b346362bf88a9e4a88416b77a57d6c2a")
                or (existingITokenLoanTokenAddress == "0xfd086bc7cd5c481dcc9c85ebe478a1c0b69fcbb9" and collateralTokenAddress == "0x17fc002b466eec40dae837fc4be5c67993ddbd6f")

                or (existingITokenLoanTokenAddress == "0xfea7a6a0b346362bf88a9e4a88416b77a57d6c2a" and collateralTokenAddress == "0xff970a61a04b1ca14834a43f5de4533ebddb5cc8")
                or (existingITokenLoanTokenAddress == "0xfea7a6a0b346362bf88a9e4a88416b77a57d6c2a" and collateralTokenAddress == "0xfd086bc7cd5c481dcc9c85ebe478a1c0b69fcbb9")
                or (existingITokenLoanTokenAddress == "0xfea7a6a0b346362bf88a9e4a88416b77a57d6c2a" and collateralTokenAddress == "0x17fc002b466eec40dae837fc4be5c67993ddbd6f")

                or (existingITokenLoanTokenAddress == "0x17fc002b466eec40dae837fc4be5c67993ddbd6f" and collateralTokenAddress == "0xff970a61a04b1ca14834a43f5de4533ebddb5cc8")
                or (existingITokenLoanTokenAddress == "0x17fc002b466eec40dae837fc4be5c67993ddbd6f" and collateralTokenAddress == "0xfd086bc7cd5c481dcc9c85ebe478a1c0b69fcbb9")
                or (existingITokenLoanTokenAddress == "0x17fc002b466eec40dae837fc4be5c67993ddbd6f" and collateralTokenAddress == "0xfea7a6a0b346362bf88a9e4a88416b77a57d6c2a")):
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

    bzxRegistry = Contract.from_abi("bzxRegistry", address="0x86003099131d83944d826F8016E09CC678789A30", abi=TokenRegistry.abi)
    supportedTokenAssetsPairs = bzxRegistry.getTokens(0, 100) # TODO move this into a loop for permissionless to support more than 100

    loanTokenSettingsLowerAdmin = Contract.from_abi(
        "loanToken", address="0x56f0741f0FF5C3a5f47319F4Ca31E68C482DA38c", abi=LoanTokenSettingsLowerAdmin.abi, owner=acct)

    for tokenAssetPairA in supportedTokenAssetsPairs:

        existingIToken = Contract.from_abi("existingIToken", address=tokenAssetPairA[0], abi=LoanTokenLogicStandard.abi, owner=acct)
        print("itoken", existingIToken.name(), tokenAssetPairA[0])
        
        calldata = loanTokenSettingsLowerAdmin.setDemandCurve.encode_input("0x171124e47fE7902E6A63f2d361Ee4F9772c87d07") ## CurvedInterestRate
        existingIToken.updateSettings(loanTokenSettingsLowerAdmin.address, calldata, {"from": acct})


'''
def updateOwner():

bzxAddress: 0x37407F3178ffE07a6cF5C847F8f680FEcf319FAB
PriceFeeds_ARBITRUM: 0x8f6A694fe9d99F4913501e6592438598DA415C9e
SwapsImplUniswapV2_ARBITRUM: 0xA9033952ac045168243A1A50c889516445247618
HelperProxy: 0xB8329B5458B1E493EFd8D9DA8C3B5E6D68e67C21


    guardian_multisig = "0x111F9F3e59e44e257b24C5d1De57E05c380C07D2"

    ## bZxProtocol
    c = Contract.from_abi("c", address="0x37407F3178ffE07a6cF5C847F8f680FEcf319FAB", abi=LoanToken.abi, owner=acct)
    print("old owner:", c.owner())
    c.transferOwnership(guardian_multisig, {"from": acct})
    print("new owner:", c.owner())
    print("----")

    ## PriceFeeds_ARBITRUM
    c = Contract.from_abi("c", address="0x8f6A694fe9d99F4913501e6592438598DA415C9e", abi=LoanToken.abi, owner=acct)
    print("old owner:", c.owner())
    c.transferOwnership(guardian_multisig, {"from": acct})
    print("new owner:", c.owner())
    print("----")

    ## SwapsImplUniswapV2_ARBITRUM
    c = Contract.from_abi("c", address="0xA9033952ac045168243A1A50c889516445247618", abi=LoanToken.abi, owner=acct)
    print("old owner:", c.owner())
    c.transferOwnership(guardian_multisig, {"from": acct})
    print("new owner:", c.owner())
    print("----")

    ## HelperProxy
    c = Contract.from_abi("c", address="0xB8329B5458B1E493EFd8D9DA8C3B5E6D68e67C21", abi=LoanToken.abi, owner=acct)
    print("old owner:", c.owner())
    c.transferOwnership(guardian_multisig, {"from": acct})
    print("new owner:", c.owner())
    print("----")

    bzxRegistry = Contract.from_abi("bzxRegistry", address="0x86003099131d83944d826F8016E09CC678789A30", abi=TokenRegistry.abi)
    supportedTokenAssetsPairs = bzxRegistry.getTokens(0, 100) # TODO move this into a loop for permissionless to support more than 100

    for tokenAssetPairA in supportedTokenAssetsPairs:

        existingIToken = Contract.from_abi("existingIToken", address=tokenAssetPairA[0], abi=LoanToken.abi, owner=acct)
        print("itoken", existingIToken.name(), tokenAssetPairA[0])
        print("old owner:", existingIToken.owner())
        existingIToken.transferOwnership(guardian_multisig, {"from": acct})
        print("new owner:", existingIToken.owner())
        print("----")
'''