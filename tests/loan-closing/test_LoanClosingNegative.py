#!/usr/bin/python3

import pytest
from brownie import Wei, reverts
from helpers import getLoanId

@pytest.fixture(scope="module")
def LinkDaiBorrowParamsId(Constants, LINK, DAI, bzx, accounts, WETH):
    loanParams = {
        "id": "0x0",
        "active": False,
        "owner": Constants["ZERO_ADDRESS"],
        "loanToken": DAI.address,
        "collateralToken": LINK.address,
        "minInitialMargin": 20e18,
        "maintenanceMargin": 15e18,
        "fixedLoanTerm": "0", # torque loan
    }
    tx = bzx.setupLoanParams([list(loanParams.values())])
    return tx.events["LoanParamsIdSetup"][0]["id"]

@pytest.fixture(scope="module")
def loanId_LINK_DAI(Constants, bzx, DAI, LINK, accounts, web3, LinkDaiBorrowParamsId):
    return getLoanId(Constants, bzx, DAI, LINK, accounts, web3, LinkDaiBorrowParamsId)

def test_liquidateLoanIsClosed(bzx, accounts, Constants):
    with reverts("loan is closed"):
        bzx.liquidate(1, accounts[1], 1)

def test_liquidateHealtyPosition(bzx, accounts, loanId_LINK_DAI):
    with reverts("healthy position"):
        bzx.liquidate(loanId_LINK_DAI, accounts[1], 1)

def test_liquidateNothingToLiquidate(bzx, accounts, loanId_LINK_DAI, priceFeeds, DAI, LINK):
    priceFeeds.setRates(
        LINK.address,
        DAI.address,
        1e18 # exchange rate droped from default 10 to 1 so that we can liquidate
    )

    with reverts("nothing to liquidate"):
        bzx.liquidate(loanId_LINK_DAI, accounts[1], 0)

def test_liquidateWrongAssetSent(bzx, accounts, loanId_LINK_DAI, DAI, LINK, priceFeeds):
    priceFeeds.setRates(
        LINK.address,
        DAI.address,
        1e18 # exchange rate droped from default 10 to 1 so that we can liquidate
    )

    with reverts("wrong asset sent"):
        bzx.liquidate(loanId_LINK_DAI, accounts[1], 1, {  "value": "1 ether"})

# TODO this cannot be tested because Constants hardcoding wethToken address
# def test_liquidateNotEnoughEther(bzx, accounts, loanId_LINK_DAI, DAI, LINK, priceFeeds):
#     priceFeeds.setRates(
#         LINK.address,
#         DAI.address,
#         1e18 # exchange rate droped from default 10 to 1 so that we can liquidate
#     )

#     with reverts("not enough ether"):
#         bzx.liquidate(loanId_LINK_DAI, accounts[1], 1e17, {  "value": "1 ether"})
#     assert False

def test_rolloverLoanIsClosed(bzx):
    with reverts("loan is closed"):
        bzx.rollover(1, b'')

def test_rolloverHealtyPosition(bzx, loanId_LINK_DAI):
    with reverts("healthy position"):
        bzx.rollover(loanId_LINK_DAI, b'')

# TODO hard to reach
# def test_rolloverInsuficientDestAmount(bzx, accounts, loanId_LINK_DAI):
#     with reverts("insufficient dest amount"):
#         bzx.rollover(loanId_LINK_DAI)

# TODO hard to reach
# def test_rolloverExcessiveSourceAmount(bzx, accounts, Constants):
#     with reverts("excessive source amount"):
#         bzx.rollover(1, accounts[1], 1)

