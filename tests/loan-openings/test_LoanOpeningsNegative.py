#!/usr/bin/python3

import pytest
from brownie import Wei, reverts
from helpers import getLoanId

@pytest.fixture(scope="module")
def setLoanPool(bzx, accounts):
    return bzx.setLoanPool(
        [
            accounts[1],
        ],
        [
            accounts[2]
        ]
    )

@pytest.fixture(scope="module")
def linkDaiMarginParamsId(Constants, LINK, DAI, bzx, accounts):

    loanParams = {
        "id": "0x0",
        "active": False,
        "owner": Constants["ZERO_ADDRESS"],
        "loanToken": DAI.address,
        "collateralToken": LINK.address,
        "minInitialMargin": 20e18,
        "maintenanceMargin": 15e18,
        "fixedLoanTerm": "2419200" # 28 days
    }
    tx = bzx.setupLoanParams([list(loanParams.values())])
    return tx.events["LoanParamsIdSetup"][0]["id"]

@pytest.fixture(scope="module")
def sameTokenParamsId(Constants, LINK, DAI, bzx, accounts):

    loanParams = {
        "id": "0x0",
        "active": False,
        "owner": Constants["ZERO_ADDRESS"],
        "loanToken": DAI.address,
        "collateralToken": DAI.address,
        "minInitialMargin": 20e18,
        "maintenanceMargin": 15e18,
        "fixedLoanTerm": "2419200" # 28 days
    }
    tx = bzx.setupLoanParams([list(loanParams.values())])
    return tx.events["LoanParamsIdSetup"][0]["id"]

def test_borrowOrTradeFromPoolLoanDataBytesRequiredWithEther(Constants, bzx):
    with reverts("loanDataBytes required with ether"):
        tx = bzx.borrowOrTradeFromPool(0, 0, 0, 0, 
        [Constants["ZERO_ADDRESS"], Constants["ZERO_ADDRESS"], Constants["ZERO_ADDRESS"], Constants["ZERO_ADDRESS"]], 
        [0, 0, 0, 0, 0], 
        b"", {"value": "1 ether"})
        tx.info()

def test_borrowOrTradeFromPoolNotAuthorized(Constants, bzx):
    with reverts("not authorized"):
        tx = bzx.borrowOrTradeFromPool(0, 0, 0, 0, 
            [Constants["ZERO_ADDRESS"], Constants["ZERO_ADDRESS"], Constants["ZERO_ADDRESS"], Constants["ZERO_ADDRESS"]], 
            [0, 0, 0, 0, 0], 
            b"", {"value": "0 ether"})
        tx.info()

def test_borrowOrTradeFromPoolLoanParamsNotExist(Constants, bzx, setLoanPool, accounts):
    with reverts("loanParams not exists"):
        tx = bzx.borrowOrTradeFromPool(0, 0, 0, 0, 
            [Constants["ZERO_ADDRESS"], Constants["ZERO_ADDRESS"], Constants["ZERO_ADDRESS"], Constants["ZERO_ADDRESS"]], 
            [0, 0, 0, 0, 0], 
            b"", {"from": accounts[1], "value": "0 ether"})
        tx.info()

def test_borrowOrTradeFromPoolCollateralIsZero(Constants, bzx, linkDaiMarginParamsId, accounts):
    with reverts("collateral is 0"):
        tx = bzx.borrowOrTradeFromPool(linkDaiMarginParamsId, 0, 0, 0, 
            [Constants["ZERO_ADDRESS"], Constants["ZERO_ADDRESS"], Constants["ZERO_ADDRESS"], Constants["ZERO_ADDRESS"]], 
            [0, 0, 0, 0, 0], 
            b"", {"from": accounts[1], "value": "0 ether"})
        tx.info()


def test_borrowOrTradeFromPoolCollateralLoanMatch(Constants, bzx, sameTokenParamsId, accounts):
    initialMargin = 10**20
    newPrincipal = 1
    with reverts("collateral/loan match"):
        tx = bzx.borrowOrTradeFromPool(sameTokenParamsId, 1, False, initialMargin, 
            [Constants["ZERO_ADDRESS"], Constants["ZERO_ADDRESS"], Constants["ZERO_ADDRESS"], Constants["ZERO_ADDRESS"]], 
            [1, newPrincipal, 1, 1, 1], 
            b"", {"from": accounts[1], "value": "0 ether"})
        tx.info()

# def test_borrowOrTradeFromPoolInitialMarginTooLow(Constants, bzx, linkDaiMarginParamsId, accounts):
#     initialMargin = 10**20
#     newPrincipal = 1
#     with reverts("initialMargin too low"):
#         tx = bzx.borrowOrTradeFromPool(linkDaiMarginParamsId, 1, False, initialMargin, 
#             [Constants["ZERO_ADDRESS"], Constants["ZERO_ADDRESS"], Constants["ZERO_ADDRESS"], Constants["ZERO_ADDRESS"]], 
#             [1, newPrincipal, 1, 1, 1], 
#             b"", {"from": accounts[1], "value": "0 ether"})
#         tx.info()

# def test_borrowOrTradeFromPoolInvalidInterest(Constants, bzx):
#     with reverts("invalid interest"):
#         bzx.borrowOrTradeFromPool(0, 0)

# def test_borrowOrTradeFromPoolLoanParamsDisabled(Constants, bzx):
#     with reverts("loanParams disabled"):
#         bzx.borrowOrTradeFromPool(0, 0)

# def test_borrowOrTradeFromPoolLoanExists(Constants, bzx):
#     with reverts("loan exists"):
#         bzx.borrowOrTradeFromPool(0, 0)

# def test_borrowOrTradeFromPoolLoanHasEnded(Constants, bzx):
#     with reverts("loan has ended"):
#         bzx.borrowOrTradeFromPool(0, 0)

# def test_borrowOrTradeFromPoolBorrowerMismatch(Constants, bzx):
#     with reverts("borrower mismatch"):
#         bzx.borrowOrTradeFromPool(0, 0)

# def test_borrowOrTradeFromPoolLenderMismatch(Constants, bzx):
#     with reverts("lender mismatch"):
#         bzx.borrowOrTradeFromPool(0, 0)

# def test_borrowOrTradeFromPoolLoanParamMismatch(Constants, bzx):
#     with reverts("loanParams mismatch"):
#         bzx.borrowOrTradeFromPool(0, 0)

# def test_borrowOrTradeFromPoolSurplusLoanToken(Constants, bzx):
#     with reverts("surplus loan token"):
#         bzx.borrowOrTradeFromPool(0, 0)

# def test_borrowOrTradeFromPoolCollateralInsuficient(Constants, bzx):
#     with reverts("collateral insufficient"):
#         bzx.borrowOrTradeFromPool(0, 0)

# def test_setDelegatedManagerUnauthorized(Constants, bzx):
#     with reverts("unauthorized"):
#         bzx.setDelegatedManager(0, Constants["ZERO_ADDRESS"], 0);