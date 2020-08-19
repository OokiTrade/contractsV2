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
    print("loan.lender", loan[11])
    loanParams = bzx.loanParams(loan[1])
    print("loanParams", loanParams)
    print("loanParams.token", loanParams[3])
    print("accounts", accounts)
    print("DAI", DAI.address)
    print("LINK", LINK.address)


    DAI.mint(
        accounts[1],
        100,
        { "from": accounts[0] }
    )

    print("balance", DAI.balanceOf(accounts[1]));

    tx = DAI.approve(bzx.address, 100, {"from": accounts[1]}) 
    tx = bzx.closeWithDeposit(loanId_LINK_DAI, accounts[1], 100, {"from": accounts[1]})
    closeWithDepositEvent = tx.events["CloseWithDeposit"][0]
    tx.info()

    assert(closeWithDepositEvent["user"] == accounts[1])
    assert(closeWithDepositEvent["lender"] == accounts[2])
    assert(closeWithDepositEvent["loanId"] == loanId_LINK_DAI)
    assert(closeWithDepositEvent["closer"] == accounts[1])
    assert(closeWithDepositEvent["loanToken"] == DAI.address)
    assert(closeWithDepositEvent["collateralToken"] == LINK.address)
    assert(closeWithDepositEvent["repayAmount"] == 100)
    assert(closeWithDepositEvent["collateralToLoanRate"] == 1000000000000000000)
    assert(closeWithDepositEvent["currentMargin"] == 0)

def test_closeWithSwapCloseWithSwapEvent(bzx, loanId_LINK_DAI, priceFeeds, DAI, LINK, accounts):
    # priceFeeds.setRates(
    #     LINK.address,
    #     DAI.address,
    #     1e18 # exchange rate droped from default 10 to 1 so that we can liquidate
    # )

    loan = bzx.loans(loanId_LINK_DAI)
    print("loan", loan)


    tx = bzx.closeWithSwap(loanId_LINK_DAI, accounts[1], 100, True, b'', {"from": accounts[1]})
    tx.info()
    closeWithSwap = tx.events["CloseWithSwap"][0]
    assert(closeWithSwap["user"] == accounts[1])
    assert(closeWithSwap["lender"] == accounts[2])
    assert(closeWithSwap["loanId"] == loanId_LINK_DAI)
    assert(closeWithSwap["closer"] == accounts[1])
    assert(closeWithSwap["loanToken"] == DAI.address)
    assert(closeWithSwap["collateralToken"] == LINK.address)
    assert(closeWithSwap["positionCloseSize"] == 100) 

