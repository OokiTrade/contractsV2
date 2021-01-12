#!/usr/bin/python3

from brownie import *
from brownie import network, accounts
from brownie.network.contract import InterfaceContainer
from brownie.network.state import _add_contract, _remove_contract
from brownie.network.contract import Contract 
from scripts.deployment.deploy_price_feeds import deployAndSetPriceFeeds

# import shared
from munch import Munch

deploys = Munch.fromDict({
    "addressProvider": True,
    "bZxProtocol": True,
    "iTokens": True,
    "PriceFeeds": True,
    "SwapsImpl": True,
    "ProtocolSettings": True,
    "LoanSettings": True,
    "LoanOpenings": True,
    "LoanMaintenance": True,
    "LoanClosings": True,
})


def main():
    deploy()


def deploy():
    global deploys, bzx, tokens, constants, addresses, thisNetwork, acct, addressProvider, iTokensListName, underlyingListName
    
    iTokensListName = ["iUSDC", "ifWETH", "iWBTC"]
    underlyingListName = ["USDC", "fWETH", "WBTC"]

    thisNetwork = network.show_active()

    if thisNetwork == "development":
        acct = accounts[0]
    elif thisNetwork == "mainnet":
        acct = accounts.load("deployer1")
    elif thisNetwork == "kovan":
        acct = accounts.load("testnet_admin")
    else:
        raise ValueError("unknown network")
    print("network: ", thisNetwork)
    print("Loaded account: ", acct)


    ### DEPLOYMENT START ###

    if deploys.addressProvider is True:
        print("Deploying addressProvider.")
        deployAddressProvider()
    else:
        addressProvider = getDeployAddressProvider(acct)
    _add_contract(addressProvider)
    

    if deploys.bZxProtocol is True:
        print("Deploying bZxProtocol.")
        deployBZXProtocol()
    _add_contract(getBzxInstance())

    if deploys.iTokens is True:
        print("Deploying iTokens.")
        deployITokens()
        loanTokenSettingsInitialize()
    loadITokens() # this sets global iTokens names

    if deploys.PriceFeeds is True:
        print("Deploying PriceFeeds.")
        deployAndSetPriceFeeds(acct, getITokenList())


    # bzx modules initializations




    if deploys.SwapsImpl is True:
        print("Deploying Swaps.")
        deployAndSetSwapImpl()




















def deployBZXProtocol():
    if thisNetwork == "mainnet":
        # TODO
        raise ValueError("deployBZXProtocol mainnet deployment missing!")
    else:
        bzxproxy = acct.deploy(bZxProtocol)
        addressProvider.setBzxProtocol(bzxproxy)
    _add_contract(getBzxInstance())

def deployAddressProvider():
    if thisNetwork == "mainnet":
        # TODO
        raise ValueError("deployAddressProvider mainnet deployment missing!")
    else:
        global addressProvider 
        addressProvider = acct.deploy(AddressesProvider)
        addressProvider = Contract.from_abi("addressProvider", address=addressProvider.address, abi=AddressesProvider.abi, owner=acct)
    _add_contract(addressProvider)


def getBzxInstance():
    return Contract.from_abi("bzx", address=addressProvider.getBzxProtocol(), abi=interface.IBZx.abi, owner=acct)

def getDeployAddressProvider(acct):
    thisNetwork = network.show_active()

    if thisNetwork == "development":
        addressProviderAddress = ""
    elif thisNetwork == "mainnet":
        addressProviderAddress = ""
    elif thisNetwork == "kovan":
        addressProviderAddress = ""
    else:
        raise ValueError("unknown network")
    return addressProviderAddress


def deployITokens():
    if thisNetwork == "mainnet":
        # TODO
        raise ValueError("iToken mainnet deployment missing!")
    else:
        iTokenListAddresses = []
        loanTokenLogicStandard = acct.deploy(LoanTokenLogicStandard, acct)
        for token in iTokensListName:           
            loanTokenProxy = acct.deploy(LoanToken, acct, loanTokenLogicStandard.address)
            iTokenListAddresses.append(loanTokenProxy.address)

            print("Deployed", token)

        addressProvider.setITokenList(iTokenListAddresses)
        print("iTokens", iTokenListAddresses)

def loadITokens():
    print(getITokenList())
    for iToken in getITokenList():
        print("adding", iToken.name())
        globals()[iToken.symbol()] = iToken
        _add_contract(globals()[iToken.symbol()])

def getITokenList():
    iTokenList = []
    for iTokenAddress in addressProvider.getITokenList():
        iTokenList.append(Contract.from_abi("loanTokenLogicStandard", iTokenAddress, LoanTokenLogicStandard.abi, acct))
    return iTokenList

def loanTokenSettingsInitialize():
    if thisNetwork == "mainnet":
        # TODO
        raise ValueError("loanTokenSettingsInitialize mainnet deployment missing!")
    else:
        loanTokenSettings = acct.deploy(LoanTokenSettings)
        index = 0
        for iToken in getITokenList():
            print("setting", iToken.name())
            testToken = acct.deploy(TestToken, "Fulcrum " + underlyingListName[index], underlyingListName[index], 18, 1e50)
            calldata = loanTokenSettings.initialize.encode_input(testToken, "Fulcrum " + iTokensListName[index], iTokensListName[index])
            iToken.updateSettings(loanTokenSettings, calldata)
            index = index + 1
            print("name after", iToken.name())

def deployAndSetSwapImpl():
    if thisNetwork == "mainnet":
        # TODO
        raise ValueError("deployAndSetSwapImpl mainnet deployment missing!")
    else:
        swaps = acct.deploy(SwapsImplTestnets)
        # bzx.setSwapsImplContract(swaps)
        # swaps.setLocalPriceFeedContract(bzx.priceFeeds())

        