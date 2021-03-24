#!/usr/bin/python3

from brownie import *
from brownie import network, accounts
from brownie.network.contract import InterfaceContainer
from brownie.network.state import _add_contract, _remove_contract
from brownie.network.contract import Contract
import time
import pdb

acct = accounts.load("deployer1")

# TODO insert real price feed below (usdc now)
#chainlinkFeedAddress = "0xA9F9F897dD367C416e350c33a92fC12e53e1Cee5"
bzxAddress = "0xC47812857A74425e2039b57891a3DFcF51602d5d"

bzx = Contract.from_abi("bzx", address=bzxAddress,
    abi=interface.IBZx.abi, owner=acct)

def main():

    #deployment()
    #marginSettings()
    #demandCurve()

def deployment():
    underlyingSymbol = "BTC"
    iTokenSymbol = "i{}".format(underlyingSymbol)
    iTokenName = "Fulcrum {} iToken ({})".format(underlyingSymbol, iTokenSymbol)  

    loanTokenAddress = "0x7130d2a12b9bcbfae4f2634d864a1ee1ce3ead9c"

    #LoanTokenLogicStandard deployed at: 0xa9651b36101E00E43dA389A2b491E94Ca9F807b6
    loanTokenLogicStandard = Contract.from_abi(
        "LoanTokenLogicStandard", address="0xa9651b36101E00E43dA389A2b491E94Ca9F807b6", abi=LoanTokenLogicStandard.abi, owner=acct)
    #loanTokenLogicStandard = acct.deploy(LoanTokenLogicWeth, acct).address

    


    # Deployment

    iTokenProxy = acct.deploy(LoanToken, acct, loanTokenLogicStandard)

    #loanTokenSettings = acct.deploy(LoanTokenSettings)
    #LoanTokenSettingsLowerAdmin deployed at: 0xA1988005a5D6e68a3572F43a18460708CB29ABe0
    #LoanTokenSettings deployed at: 0xbB4e3A0A540819EfdF0A9C88dFcD9B1D628802dF

    loanTokenSettings = Contract.from_abi(
        "loanToken", address="0xbB4e3A0A540819EfdF0A9C88dFcD9B1D628802dF", abi=LoanTokenSettings.abi, owner=acct)


    calldata = loanTokenSettings.initialize.encode_input(
        loanTokenAddress, iTokenName, iTokenSymbol)

    iToken = Contract.from_abi("loanTokenLogicStandard",
                            iTokenProxy, LoanTokenLogicStandard.abi, acct)


    iToken.updateSettings(loanTokenSettings, calldata)



    # Setting price Feed
    #priceFeed = Contract.from_abi(
    #    "pricefeed", bzx.priceFeeds(), abi=PriceFeeds.abi, owner=acct)
    #priceFeed.setPriceFeed([loanTokenAddress], [chainlinkFeedAddress], {'from': acct})


    bzx.setLoanPool([iToken], [loanTokenAddress])
    #bzx.setSupportedTokens([loanTokenAddress], [True])


def marginSettings():

    # Setting margin settings

    loanTokenSettingsLowerAdmin = Contract.from_abi(
        "loanToken", address="0xA1988005a5D6e68a3572F43a18460708CB29ABe0", abi=LoanTokenSettingsLowerAdmin.abi, owner=acct)
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
    
    bzxRegistry = Contract.from_abi("bzxRegistry", address="0x2fA30fB75E08f5533f0CF8EBcbb1445277684E85", abi=TokenRegistry.abi)
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
        print("itoken", existingIToken.name())
        existingITokenLoanTokenAddress = existingIToken.loanTokenAddress()

        for tokenAssetPairB in supportedTokenAssetsPairs:

            collateralTokenAddress = tokenAssetPairB[1]

            if collateralTokenAddress == existingITokenLoanTokenAddress:
                continue

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
            
            print(base_data_copy)
            params.append(base_data_copy)

            loanTokensArr.append(existingITokenLoanTokenAddress)
            collateralTokensArr.append(collateralTokenAddress)
            amountsArr.append(7*10**18)

        calldata = loanTokenSettingsLowerAdmin.setupLoanParams.encode_input(params, True)
        existingIToken.updateSettings(loanTokenSettingsLowerAdmin.address, calldata, {"from": acct})

        calldata = loanTokenSettingsLowerAdmin.setupLoanParams.encode_input(params, False)
        existingIToken.updateSettings(loanTokenSettingsLowerAdmin.address, calldata, {"from": acct})

        bzx.setLiquidationIncentivePercent(loanTokensArr, collateralTokensArr, amountsArr)


def demandCurve():

    bzxRegistry = Contract.from_abi("bzxRegistry", address="0x2fA30fB75E08f5533f0CF8EBcbb1445277684E85", abi=TokenRegistry.abi)
    supportedTokenAssetsPairs = bzxRegistry.getTokens(0, 100) # TODO move this into a loop for permissionless to support more than 100

    loanTokenSettingsLowerAdmin = Contract.from_abi(
        "loanToken", address="0xA1988005a5D6e68a3572F43a18460708CB29ABe0", abi=LoanTokenSettingsLowerAdmin.abi, owner=acct)

    for tokenAssetPairA in supportedTokenAssetsPairs:
        
        existingIToken = Contract.from_abi("existingIToken", address=tokenAssetPairA[0], abi=LoanTokenLogicStandard.abi, owner=acct)
        print("itoken", existingIToken.name())
        
        calldata = loanTokenSettingsLowerAdmin.setDemandCurve.encode_input(0, 23.75*10**18, 0, 0, 80*10**18, 80*10**18, 120*10**18)
        existingIToken.updateSettings(loanTokenSettingsLowerAdmin.address, calldata, {"from": acct})