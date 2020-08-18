#!/usr/bin/python3

import pytest
from brownie import Wei, reverts
from helpers import getLoanId
# LoanClosing has events that emit from LoanClosingBase

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


def test_liquidateLiquidateEvent(bzx, loanId_LINK_DAI, priceFeeds, DAI, LINK, accounts):
    priceFeeds.setRates(
        LINK.address,
        DAI.address,
        1e18 # exchange rate droped from default 10 to 1 so that we can liquidate
    )

    LINK.mint(
        bzx.address,
        1e18,
        { "from": accounts[1] }
    )

    bzx.liquidate(loanId_LINK_DAI, accounts[1], 1)
    assert False

# def test_closeWithDepositCloseWithDepositEvent(bzx):
#     assert False

# def test_closeWithSwapCloseWithSwapEvent(bzx):
#     assert False

