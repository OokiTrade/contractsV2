#!/usr/bin/python3
import time

'''
Optimism Addresses ->

bzxAddress: 0xAcedbFd5Bc1fb0dDC948579d4195616c05E74Fd1
TokenRegistry: 0x22a2208EeEDeb1E2156370Fd1c1c081355c68f2B
HelperProxy: 0x3920993FEca46AF170d296466d8bdb47A4b4e152

'''

from brownie import *
from brownie import network, accounts
from brownie.network.contract import InterfaceContainer
from brownie.network.state import _add_contract, _remove_contract
from brownie.network.contract import Contract
import time
import pdb

def deployment(loanTokenSettings, settngsLowerAdmin, loanTokenAddress, underlyingSymbol, iTokenProxy):
    iTokenSymbol = "i{}".format(underlyingSymbol.upper())
    iTokenName = "Ooki {} iToken ({})".format(underlyingSymbol, iTokenSymbol)

    iToken = Contract.from_abi("loanTokenLogicStandard", iTokenProxy, LoanTokenLogicStandard.abi, deployer)

    calldata = loanTokenSettings.initialize.encode_input(loanTokenAddress, iTokenName, iTokenSymbol)
    iToken.updateSettings(loanTokenSettings, calldata, {"from": deployer})

    calldata = loanTokenSettings.setLowerAdminValues.encode_input(
        deployer, # mising gnossis
        settngsLowerAdmin  # LoanTokenSettingsLowerAdmin contract
    )
    iToken.updateSettings(loanTokenSettings, calldata, {"from": deployer})
    iToken.updateFlashBorrowFeePercent(0.03e18, {"from": deployer})

    # Setting price Feed
    #priceFeed = Contract.from_abi(
    #    "pricefeed", bzx.priceFeeds(), abi=PriceFeeds.abi, owner=deployer)
    #priceFeed.setPriceFeed([loanTokenAddress], [chainlinkFeedAddress], {'from': deployer})


    #bzx.setLoanPool([iToken], [loanTokenAddress], {"from": deployer}) <-- uncomment
    #bzx.setSupportedTokens([loanTokenAddress], [True])


def marginSettings(bzxRegistry,loanTokenSettingsLowerAdmin, iTokenProxy, stableItokens):
    # Setting margin settings
    iToken = Contract.from_abi("loanTokenLogicStandard", iTokenProxy, LoanTokenLogicStandard.abi)
    base_data = [
        b"0x0",  # id
        False,  # active
        str(deployer),  # owner
        "0x0000000000000000000000000000000000000001",  # loanToken
        "0x0000000000000000000000000000000000000002",  # collateralToken
        Wei("20 ether"),  # minInitialMargin
        Wei("15 ether"),  # maintenanceMargin
        0  # fixedLoanTerm
    ]

    params = []

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
        existingIToken = Contract.from_abi("existingIToken", address=tokenAssetPairA[0], abi=LoanTokenLogicStandard.abi, owner=deployer)
        existingITokenLoanTokenAddress = existingIToken.loanTokenAddress()
        print("itoken", existingIToken.name(), tokenAssetPairA[0])

        print("existingITokenLoanTokenAddress", existingITokenLoanTokenAddress, iToken.loanTokenAddress())

        if existingITokenLoanTokenAddress != iToken.loanTokenAddress():
            print("skip", existingITokenLoanTokenAddress)
            continue

        for tokenAssetPairB in supportedTokenAssetsPairs:

            collateralTokenAddress = tokenAssetPairB[1]

            if collateralTokenAddress == existingITokenLoanTokenAddress:
                continue

            base_data_copy = base_data.copy()
            base_data_copy[3] = existingITokenLoanTokenAddress
            base_data_copy[4] = collateralTokenAddress # pair is iToken, Underlying

            if (existingITokenLoanTokenAddress != collateralTokenAddress
                    and (existingITokenLoanTokenAddress in stableItokens and collateralTokenAddress in stableItokens)
            ):
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
            existingIToken.updateSettings(loanTokenSettingsLowerAdmin.address, calldata, {"from": deployer})
            time.sleep(20)

            ## Margin trades
            calldata = loanTokenSettingsLowerAdmin.setupLoanParams.encode_input(params, False)
            existingIToken.updateSettings(loanTokenSettingsLowerAdmin.address, calldata, {"from": deployer})
            time.sleep(20)

        print()
        print(loanTokensArr)
        print(collateralTokensArr)
        print(amountsArr)
        bzx.setLiquidationIncentivePercent(loanTokensArr, collateralTokensArr, amountsArr, {"from": deployer})


def demandCurve(bzx, settngsLowerAdmin, iTokenProxy, CUI):
    iToken = Contract.from_abi("loanTokenLogicStandard", iTokenProxy, LoanTokenLogicStandard.abi)
    calldata = settngsLowerAdmin.setDemandCurve.encode_input(CUI)
    print("setDemandCurve::calldata", calldata)
    iToken.updateSettings(settngsLowerAdmin.address, calldata,  {"from": deployer})
    bzx.setupLoanPoolTWAI(iTokenProxy, {"from": deployer})

'''
def updateOwner():

bzxAddress: 0x37407F3178ffE07a6cF5C847F8f680FEcf319FAB
PriceFeeds_ARBITRUM: 0x8f6A694fe9d99F4913501e6592438598DA415C9e
SwapsImplUniswapV2_ARBITRUM: 0xA9033952ac045168243A1A50c889516445247618
HelperProxy: 0xB8329B5458B1E493EFd8D9DA8C3B5E6D68e67C21


    guardian_multisig = "0x111F9F3e59e44e257b24C5d1De57E05c380C07D2"

    ## bZxProtocol
    c = Contract.from_abi("c", address="0x37407F3178ffE07a6cF5C847F8f680FEcf319FAB", abi=LoanToken.abi, owner=deployer)
    print("old owner:", c.owner())
    c.transferOwnership(guardian_multisig, {"from": deployer})
    print("new owner:", c.owner())
    print("----")

    ## PriceFeeds_ARBITRUM
    c = Contract.from_abi("c", address="0x8f6A694fe9d99F4913501e6592438598DA415C9e", abi=LoanToken.abi, owner=deployer)
    print("old owner:", c.owner())
    c.transferOwnership(guardian_multisig, {"from": deployer})
    print("new owner:", c.owner())
    print("----")

    ## SwapsImplUniswapV2_ARBITRUM
    c = Contract.from_abi("c", address="0xA9033952ac045168243A1A50c889516445247618", abi=LoanToken.abi, owner=deployer)
    print("old owner:", c.owner())
    c.transferOwnership(guardian_multisig, {"from": deployer})
    print("new owner:", c.owner())
    print("----")

    ## HelperProxy
    c = Contract.from_abi("c", address="0xB8329B5458B1E493EFd8D9DA8C3B5E6D68e67C21", abi=LoanToken.abi, owner=deployer)
    print("old owner:", c.owner())
    c.transferOwnership(guardian_multisig, {"from": deployer})
    print("new owner:", c.owner())
    print("----")

    bzxRegistry = Contract.from_abi("bzxRegistry", address="0x86003099131d83944d826F8016E09CC678789A30", abi=TokenRegistry.abi)
    supportedTokenAssetsPairs = bzxRegistry.getTokens(0, 100) # TODO move this into a loop for permissionless to support more than 100

    for tokenAssetPairA in supportedTokenAssetsPairs:

        existingIToken = Contract.from_abi("existingIToken", address=tokenAssetPairA[0], abi=LoanToken.abi, owner=deployer)
        print("itoken", existingIToken.name(), tokenAssetPairA[0])
        print("old owner:", existingIToken.owner())
        existingIToken.transferOwnership(guardian_multisig, {"from": deployer})
        print("new owner:", existingIToken.owner())
        print("----")
'''