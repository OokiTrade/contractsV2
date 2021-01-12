#!/usr/bin/python3

from brownie import *


def deployAndSetPriceFeeds(acct, iTokenList):
    thisNetwork = network.show_active()
    if thisNetwork == "mainnet":
        feeds = acct.deploy(PriceFeeds)

        # TODO
        raise ValueError("priceFeeds mainnet deployment missing!")
        setDecimals()
        setPriceFeed()
    else:
        feeds = acct.deploy(PriceFeedsLocal)
       
        for i in iTokenList:
            for i in iTokenList:
                feeds.setRates(
                    i.loanTokenAddress(), # USDC
                    j.loanTokenAddress(), # WETH
                    1*10**18
                )

        print("Calling setDecimals.")
        loanTokenAddressList = [token.loanTokenAddress() for token in iTokenList]
        feeds.setDecimals(loanTokenAddressList)

        # TODO setPriceFeed


def setPriceFeed():
    print("Calling setPriceFeed.")
    raise ValueError("TODO")

def setDecimals():
    print("Calling setDecimals.")
    raise ValueError("TODO")