#!/usr/bin/python3

from brownie import *
from brownie.network.contract import InterfaceContainer
from brownie.network.state import _add_contract, _remove_contract

import shared
from munch import Munch

def main():
    deployProtocol()

def deployItoken(symbol, loanTokenAddress, loanTokenLogicStandard,loanTokenSettings):
    print(f"Deploying {symbol}." )
    underlyingSymbol = symbol
    iTokenSymbol = "i{}".format(underlyingSymbol)
    iTokenName = "Fulcrum {} iToken ({})".format(underlyingSymbol, iTokenSymbol)
    iTokenProxy = acct.deploy(LoanToken, acct, loanTokenLogicStandard)
    calldata = loanTokenSettings.initialize.encode_input(
        loanTokenAddress, iTokenName, iTokenSymbol)
    iToken = Contract.from_abi("loanTokenLogicStandard",
                               iTokenProxy, LoanTokenLogicStandard.abi, acct)
    print(f"{symbol} updateSettings")
    iToken.updateSettings(loanTokenSettings, calldata)
    return iToken;

def marginSettings(loanTokenSettingsLowerAdmin, bzxRegistry, bzrx):

    # Setting margin settings

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

    global tx1, tx2
    tx1 = {}
    tx2 = {}

    supportedTokenAssetsPairs = bzxRegistry.getTokens(0, 100) # TODO move this into a loop for permissionless to support more than 100
    loanTokensArr = []
    collateralTokensArr = []
    amountsArr = []

    for tokenAssetPairA in supportedTokenAssetsPairs:
        print(tokenAssetPairA)
        params.clear()
        loanTokensArr.clear()
        collateralTokensArr.clear()
        amountsArr.clear()

        # below is to allow new iToken.loanTokenAddress in other existing iTokens
        existingIToken = Contract.from_abi("existingIToken", address=tokenAssetPairA[0], abi=LoanTokenLogicStandard.abi, owner=acct)

        existingITokenLoanTokenAddress = existingIToken.loanTokenAddress()
        print("itoken", existingIToken.name(), existingITokenLoanTokenAddress)
        for tokenAssetPairB in supportedTokenAssetsPairs:

            collateralTokenAddress = tokenAssetPairB[1]

            if collateralTokenAddress == existingITokenLoanTokenAddress:
                continue

            base_data_copy = base_data.copy()
            base_data_copy[3] = existingITokenLoanTokenAddress
            base_data_copy[4] = collateralTokenAddress # pair is iToken, Underlying

            #For tests only
            base_data_copy[5] = Wei("20 ether")  # minInitialMargin
            base_data_copy[6] = Wei("15 ether")  # maintenanceMargin

            print(base_data_copy)
            params.append(base_data_copy)

            loanTokensArr.append(existingITokenLoanTokenAddress)
            collateralTokensArr.append(collateralTokenAddress)
            amountsArr.append(7*10**18)

        if (len(params) != 0):
            print (f"Update settings {existingIToken}")
            calldata = loanTokenSettingsLowerAdmin.setupLoanParams.encode_input(params, True)
            tx1[existingITokenLoanTokenAddress] = existingIToken.updateSettings(loanTokenSettingsLowerAdmin.address, calldata, {"from": acct})

            print ("Update settings")
            calldata = loanTokenSettingsLowerAdmin.setupLoanParams.encode_input(params, False)
            tx1[existingITokenLoanTokenAddress] = existingIToken.updateSettings(loanTokenSettingsLowerAdmin.address, calldata, {"from": acct})

        bzx.setLiquidationIncentivePercent(loanTokensArr, collateralTokensArr, amountsArr)


def demandCurve(bzxRegistry, loanTokenSettingsLowerAdmin, ibzrx):

    supportedTokenAssetsPairs = bzxRegistry.getTokens(0, 100) # TODO move this into a loop for permissionless to support more than 100


    for tokenAssetPairA in supportedTokenAssetsPairs:

        existingIToken = Contract.from_abi("existingIToken", address=tokenAssetPairA[0], abi=LoanTokenLogicStandard.abi, owner=acct)
        print("itoken", existingIToken.name())

        calldata = loanTokenSettingsLowerAdmin.setDemandCurve.encode_input(0, 10*10**18, 0, 0, 80*10**18, 80*10**18, 120*10**18)
        existingIToken.updateSettings(loanTokenSettingsLowerAdmin.address, calldata, {"from": acct})



def deployProtocol():
    global deploys, bzx, bzxRegistry, tokens, constants, addresses, thisNetwork, \
        acct, swaps, usdc, weth, wbtc, usdt, dai,wmatic, \
        loanTokenSettingsLowerAdmin, bzxRegistry, feeds

    tokens = Munch()
    itokens = Munch()
    chainlinkFeeds = Munch()
    bzxProtocol = '0xfe4F0eb0A1Ad109185c9AaDE64C48ff8e928e54B'

    acct = accounts[0] #accounts.load('deployer1')
    print("Loaded account",acct)

    constants = shared.Constants()
    addresses = shared.Addresses()

    ### DEPLOYMENT START ###
    print ("Deploying BZRX Token")
    tokens.bzrx = acct.deploy(BZRXToken, acct)

    print ("Deploying vBZRX Token")
    wvbzrxImpl = acct.deploy(VBZRXWrapper)
    wvbzrx = acct.deploy(Proxy_0_5, wvbzrxImpl)

    #tokens.weth = Contract.from_abi("wETH", "0x7ceB23fD6bC0adD59E62ac25578270cFf1b9f619", TestWeth.abi)
    #tokens.wbtc = Contract.from_abi("wBTC", "0x1BFD67037B42Cf73acF2047067bd4F2C47D9BfD6", TestToken.abi)
    #tokens.usdc = Contract.from_abi("USDC", "0x2791Bca1f2de4661ED88A30C99A7a9449Aa84174", TestToken.abi)
    tokens.usdt = Contract.from_abi("USDT", "0xc2132D05D31c914a87C6611C10748AEb04B58e8F", TestToken.abi)
    tokens.wmatic = Contract.from_abi("wMATIC", "0x0d500B1d8E8eF31E21C99d1Db9A6444d3ADf1270", TestToken.abi)
    #tokens.link = Contract.from_abi("LINK", "0xb0897686c545045afc77cf20ec7a532e3120e0f1", TestToken.abi)
    #tokens.quick = Contract.from_abi("QUICK", "0x831753DD7087CaC61aB5644b308642cc1c33Dc13", TestToken.abi)
    tokens.wvbzrx = Contract.from_abi("wvBZRX", wvbzrx.address, TestToken.abi)
    #tokens.aave = Contract.from_abi("AAVE", "0xD6DF932A45C0f255f85145f286eA0b292B21C90B", TestToken.abi)
    #

    #chainlinkFeeds.weth = "0xF9680D99D6C9589e2a93a78A04A279e509205945"
    #chainlinkFeeds.wbtc = "0xc907E116054Ad103354f2D350FD2514433D57F6f"
    #chainlinkFeeds.usdc = "0xfE4A8cc5b5B2366C1B58Bea3858e81843581b2F7"
    chainlinkFeeds.usdt = "0x0A6513e40db6EB1b165753AD52E80663aeA50545"
    chainlinkFeeds.wmatic = "0xAB594600376Ec9fD91F8e885dADF0CE036862dE0"
    #chainlinkFeeds.link = "0xd9FFdb71EbE7496cC440152d43986Aae0AB76665"
    #chainlinkFeeds.bzrx = ""
    #chainlinkFeeds.wvbzrx = ""
    #chainlinkFeeds.quick = ""
    #chainlinkFeeds.aave = ""



    # print ("Deploying ArbitraryCaller")
    # acct.deploy(ArbitraryCaller)

    print ("Deploying loanTokenSettingsLowerAdmin")
    loanTokenSettingsLowerAdmin = acct.deploy(LoanTokenSettingsLowerAdmin)

    print ("Deploying TokenRegistry")
    bzxRegistry = acct.deploy(TokenRegistry)

    print("Deploying bZxProtocol.")

    bzxproxy = Contract.from_abi("bZxProtocol", address=bzxProtocol, abi=bZxProtocol.abi, owner=acct)
    bzxproxy.transferOwnership(acct, {'from':bzxproxy.owner()})
    bzx = Contract.from_abi("bzx", address=bzxproxy.address, abi=interface.IBZx.abi, owner=acct)
    _add_contract(bzx)

    ## SwapImpl
    print("Deploying Swaps.")
    swaps = acct.deploy(SwapsImplUniswapV2_POLYGON)

    ## ProtocolSettings
    print("Deploying ProtocolSettings.")
    settings = acct.deploy(ProtocolSettings)
    print("Calling replaceContract.")
    bzx.replaceContract(settings.address)

    print("Calling setSupportedTokens.")

    bzx.setSupportedTokens(
        [
     #       tokens.weth,
            tokens.usdt,
     #       tokens.wbtc,
     #       tokens.usdc,
            tokens.wmatic,
     #       tokens.link,
     #       tokens.quick,
     #       tokens.aave,
            tokens.wvbzrx,
            tokens.bzrx
        ],
        [

            True,
            True,
            True,
            True

        ],
        True
        , {"from": acct})

    bzx.setFeesController(acct.address)

    ## LoanSettings
    print("Deploying LoanSettings.")
    loanSettings = acct.deploy(LoanSettings)
    print("Calling replaceContract.")
    bzx.replaceContract(loanSettings.address)

    ## LoanOpenings
    print("Deploying LoanOpenings.")
    loanOpenings = acct.deploy(LoanOpenings)
    print("Calling replaceContract.")
    bzx.replaceContract(loanOpenings.address)

    ## LoanMaintenance
    print("Deploying LoanMaintenance.")
    loanMaintenance = acct.deploy(LoanMaintenance)
    print("Calling replaceContract.")
    bzx.replaceContract(loanMaintenance.address)

    ## LoanClosings
    print("Deploying LoanClosings.")
    loanClosings = acct.deploy(LoanClosings)
    print("Calling replaceContract.")
    bzx.replaceContract(loanClosings.address)

    ## Deploy iTokens
    print("Deploying iTokens.")
    loanTokenLogicStandard = acct.deploy(LoanTokenLogicStandard, acct)
    loanTokenSettings = acct.deploy(LoanTokenSettings)


    #itokens.weth = deployItoken('wETH', tokens.weth.address, loanTokenLogicStandard, loanTokenSettings);
    itokens.usdt = deployItoken('USDT', tokens.usdt.address, loanTokenLogicStandard, loanTokenSettings);
    #itokens.wbtc = deployItoken('WBTC', tokens.wbtc.address, loanTokenLogicStandard, loanTokenSettings);
    #itokens.usdc = deployItoken('USDC', tokens.usdc.address, loanTokenLogicStandard, loanTokenSettings);
    itokens.wmatic = deployItoken('wMATIC', tokens.wmatic.address, loanTokenLogicStandard, loanTokenSettings);
    #itokens.link = deployItoken('LINK', tokens.link.address, loanTokenLogicStandard, loanTokenSettings);
    itokens.bzrx = deployItoken('BZRX', tokens.bzrx.address, loanTokenLogicStandard, loanTokenSettings);
    #itokens.quick = deployItoken('QUICK', tokens.quick.address, loanTokenLogicStandard, loanTokenSettings);
    #itokens.aave = deployItoken('AAVE', tokens.aave.address, loanTokenLogicStandard, loanTokenSettings);
    itokens.wvbzrx = deployItoken('wvBZRX', tokens.wvbzrx.address, loanTokenLogicStandard, loanTokenSettings);

    print("Deploying setLoanPool")
    bzx.setLoanPool(
        [
            #itokens.weth,
            itokens.usdt,
            #itokens.wbtc,
            #itokens.usdc,
            itokens.wmatic,
            #itokens.link,
            #itokens.quick,
            #itokens.aave,
            itokens.wvbzrx,
            itokens.bzrx,
        ],
        [
            #tokens.weth,
            tokens.usdt,
            #tokens.wbtc,
            #tokens.usdc,
            tokens.wmatic,
            #tokens.link,
            #tokens.quick,
            #tokens.aave,
            tokens.wvbzrx,
            tokens.bzrx,
        ])

    print("Margin Settings")
    marginSettings(loanTokenSettingsLowerAdmin, bzxRegistry, tokens.bzrx)

    print("Deitokesmand Curve")
    demandCurve(bzxRegistry, loanTokenSettingsLowerAdmin, itokens.bzrx)

    print("Calling setSwapsImplContract.")
    bzx.setSwapsImplContract(
        swaps.address  # swapsImpl
    )

    ## PriceFeeds
    print("Deploying PriceFeeds.")
    feeds = acct.deploy(PriceFeeds_POLYGON)
    #feeds = Contract.from_abi("feeds", address=bzx.priceFeeds(), abi=PriceFeeds.abi, owner=acct)

    print("Calling setPriceFeedContract.")
    bzx.setPriceFeedContract(
        feeds.address # priceFeeds
    )

    print("Calling setDecimals.")
    tx = feeds.setDecimals(
        [
            #tokens.weth,
            tokens.usdt,
            #tokens.wbtc,
            #tokens.usdc,
            tokens.wmatic,
            #tokens.link,
            #tokens.quick,
            #tokens.aave,
            tokens.wvbzrx,
            tokens.bzrx,
        ]
        , {"from": acct})

    print("Calling setPriceFeed.")
    feeds.setPriceFeed(
        [
            #tokens.weth,
            tokens.usdt,
            #tokens.wbtc,
            #tokens.usdc,
            tokens.wmatic,
            #tokens.link
            #quick, wvbzrx, aave
        ],
        [
            #chainlinkFeeds.weth,
            chainlinkFeeds.usdt,
            #chainlinkFeeds.wbtc,
            #chainlinkFeeds.usdc,
            chainlinkFeeds.wmatic,
            #chainlinkFeeds.link,
            #quick, wvbzrx, aave
        ]
        , {"from": acct})

    tokenHolder = acct.deploy(TokenHolder, acct)
    helperImpl = acct.deploy(HelperImpl)
    dappHelper = acct.deploy(DAppHelper)
    print("bZx protocol: ", bzxProtocol)
    print("tokenHolder: ", tokenHolder.address)
    print("helperImpl: ", helperImpl.address)
    print("dappHelper: ", dappHelper.address)
    print("tokens: ")
    for token in tokens.keys():
        print(f"{token}: {tokens[token]}")

    print("itokens: ")
    for token in itokens.keys():
        print(f"{token}: {itokens[token]}")

    exec(open("./scripts/deploy-masterchef_matic.py").read())






