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

            print(base_data_copy)
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


def updateOwner():
    guardian_multisig = "0x4e5b10F8221eadCeDEAA84a122620e22775F82Df"
    ## bZxProtocol
    BZX = Contract.from_abi("BZX", "0xAcedbFd5Bc1fb0dDC948579d4195616c05E74Fd1", bZxProtocol.abi)
    print("old owner:", BZX.owner())
    BZX.transferOwnership(guardian_multisig, {"from": deployer})
    print("new owner:", BZX.owner())
    print("----")

    ## PriceFeeds_OPTIMISM
    feeds = Contract.from_abi("feeds", address="0x723bD1672b4bafF0B8132eAfc082EB864cF18D24", abi=PriceFeeds_OPTIMISM.abi)
    print("old owner:", feeds.owner())
    feeds.transferOwnership(guardian_multisig, {"from": deployer})
    print("new owner:", feeds.owner())
    print("----")


    ## HelperProxy
    HELPER = Contract.from_abi("HELPER", "0x3920993FEca46AF170d296466d8bdb47A4b4e152", HelperImpl.abi)
    print("old owner:", HELPER.owner())
    HELPER.transferOwnership(guardian_multisig, {"from": deployer})
    print("new owner:", HELPER.owner())
    print("----")

    # ## FeeExtractAndDistribute
    # c = Contract.from_abi("c", address="0xf970FA9E6797d0eBfdEE8e764FC5f3123Dc6befD", abi=LoanToken.abi, owner=deployer)
    # print("old owner:", c.owner())
    # c.transferOwnership(guardian_multisig, {"from": deployer})
    # print("new owner:", c.owner())
    # print("----")

    ## DexRecords
    dex_record = Contract.from_abi("DexRecords", "0x8FA2c0864fE84D1f56D6C3C33e31E00564425782", DexRecords.abi)
    print("old owner:", dex_record.owner())
    dex_record.transferOwnership(guardian_multisig, {"from": deployer})
    print("new owner:", dex_record.owner())
    print("----")

    ## SwapsImplUniswapV3_ETH
    univ3 = Contract.from_abi("SwapsImplUniswapV3_ETH", "0x7Ec3888aaF6Fe27E73742526c832e996Eb8fd7Fe", SwapsImplUniswapV3_ETH.abi)
    print("old owner:", univ3.owner())
    univ3.transferOwnership(guardian_multisig, {"from": deployer})
    print("new owner:", univ3.owner())
    print("----")

    ## LoanTokenSettings
    loanTokenSettings = Contract.from_abi("settings", address="0xe98dE80395972Ff6e32885F6a472b38436bE1716", abi=LoanTokenSettings.abi)
    print("old owner:", loanTokenSettings.owner())
    loanTokenSettings.transferOwnership(guardian_multisig, {"from": deployer})
    print("new owner:", loanTokenSettings.owner())
    print("----")

    ## LoanTokenSettingsLowerAdmin
    settngsLowerAdmin = Contract.from_abi("settngsLowerAdmin", address="0x46530E77a3ad47f432D1ad206fB8c44435932B91", abi=LoanTokenSettingsLowerAdmin.abi)
    print("old owner:", settngsLowerAdmin.owner())
    settngsLowerAdmin.transferOwnership(guardian_multisig, {"from": deployer})
    print("new owner:", settngsLowerAdmin.owner())
    print("----")

    TOKEN_REGISTRY = Contract.from_abi("TOKEN_REGISTRY", "0x22a2208EeEDeb1E2156370Fd1c1c081355c68f2B", TokenRegistry.abi)
    supportedTokenAssetsPairs = TOKEN_REGISTRY.getTokens(0, 100)

    for tokenAssetPairA in supportedTokenAssetsPairs:
        existingIToken = Contract.from_abi("existingIToken", address=tokenAssetPairA[0], abi=LoanToken.abi, owner=deployer)
        print("itoken", existingIToken.name(), tokenAssetPairA[0])
        print("old owner:", existingIToken.owner())
        existingIToken.transferOwnership(guardian_multisig, {"from": deployer})
        print("new owner:", existingIToken.owner())
        print("----")