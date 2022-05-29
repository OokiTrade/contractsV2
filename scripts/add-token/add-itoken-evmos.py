#!/usr/bin/python3


'''
Evmos Addresses ->

bzxAddress: 0xf2FBaD7E59f0DeeE0ec2E724d2b6827Ea1cCf35f
TokenRegistry: 0x2767078d232f50A943d0BA2dF0B56690afDBB287
HelperProxy: 0xe98dE80395972Ff6e32885F6a472b38436bE1716

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
    print("Deploying ", iTokenName)
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

            ## Margin trades
            calldata = loanTokenSettingsLowerAdmin.setupLoanParams.encode_input(params, False)
            existingIToken.updateSettings(loanTokenSettingsLowerAdmin.address, calldata, {"from": deployer})

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