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

    tx = DAI.approve(bzx.address, 1)
    print("tx", tx.info())

    loan = bzx.loans(loanId_LINK_DAI)
    print("loan", loan)

    print("bzx.address", bzx.address) 
    tx = bzx.liquidate(loanId_LINK_DAI, accounts[2], 1)
    print("tx", tx.info())
    print("accounts", accounts)
    liquidateEvent = tx.events["Liquidate"][0];
    assert(liquidateEvent["loanToken"] == DAI)
    assert(liquidateEvent["collateralToken"] == LINK)
    assert(liquidateEvent["liquidator"] == accounts[0])
    assert(liquidateEvent["user"] == accounts[1])
    assert(liquidateEvent["lender"] == accounts[2])
    assert(liquidateEvent["repayAmount"] == 1)

def test_closeWithDepositCloseWithDepositEvent(bzx, loanId_LINK_DAI, priceFeeds, DAI, LINK, accounts):
    priceFeeds.setRates(
        LINK.address,
        DAI.address,
        1e18 # exchange rate droped from default 10 to 1 so that we can liquidate
    )

    loan = bzx.loans(loanId_LINK_DAI)
    print("loan", loan)
    print("accounts", accounts)

    tx = DAI.approve(bzx.address, 10000000000000000000000000000000000, {"from": accounts[1]})
    print("tx", tx.info())

    tx = LINK.approve(bzx.address, 100000000000000000000000000000000, {"from": accounts[1]})
    print("tx", tx.info())

    tx = bzx.closeWithDeposit(loanId_LINK_DAI, accounts[1], 1, {"from": accounts[1]})
    assert False

# def test_closeWithSwapCloseWithSwapEvent(bzx):
#     assert False

