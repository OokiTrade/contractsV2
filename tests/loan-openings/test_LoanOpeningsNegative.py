#!/usr/bin/python3

import pytest
from brownie import Wei, reverts
from helpers import getLoanId, setupLoanPool

@pytest.fixture(scope="module")
def setLoanPool(Constants, bzx, accounts):
    setupLoanPool(Constants, bzx, accounts[1], accounts[2])

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
def otherLinkDaiMarginParamsId(Constants, LINK, DAI, bzx, accounts):
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

@pytest.fixture(scope="module")
def smallInitialMarginParamsId(Constants, LINK, DAI, bzx, accounts):
    loanParams = {
        "id": "0x0",
        "active": False,
        "owner": Constants["ZERO_ADDRESS"],
        "loanToken": DAI.address,
        "collateralToken": LINK.address,
        "minInitialMargin": 200e20,
        "maintenanceMargin": 15e18,
        "fixedLoanTerm": "2419200" # 28 days
    }
    tx = bzx.setupLoanParams([list(loanParams.values())])
    return tx.events["LoanParamsIdSetup"][0]["id"]

@pytest.fixture(scope="module")
def zeroMaxTermParamsId(Constants, LINK, DAI, bzx, accounts):
    loanParams = {
        "id": "0x0",
        "active": False,
        "owner": Constants["ZERO_ADDRESS"],
        "loanToken": DAI.address,
        "collateralToken": LINK.address,
        "minInitialMargin": 20e18,
        "maintenanceMargin": 15e18,
        "fixedLoanTerm": "0" # 28 days
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

def test_borrowOrTradeFromPoolCollateralIsZero(Constants, bzx, linkDaiMarginParamsId, accounts, setLoanPool):
    with reverts("collateral is 0"):
        tx = bzx.borrowOrTradeFromPool(linkDaiMarginParamsId, 0, 0, 1, 
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

def test_borrowOrTradeFromPoolInitialMarginTooLow(Constants, bzx, smallInitialMarginParamsId, accounts):
    initialMargin = 10**20
    newPrincipal = 10

    with reverts("initialMargin too low"):
        tx = bzx.borrowOrTradeFromPool(smallInitialMarginParamsId, 1, False, initialMargin, 
            [Constants["ZERO_ADDRESS"], Constants["ZERO_ADDRESS"], Constants["ZERO_ADDRESS"], Constants["ZERO_ADDRESS"]], 
            [1, newPrincipal, 1, 1, 1], 
            b"", {"from": accounts[1], "value": "0 ether"})
        tx.info()

def test_borrowOrTradeFromPoolInvalidInterest(Constants, bzx, zeroMaxTermParamsId, accounts):
    initialMargin = 10**20
    newPrincipal = 10

    with reverts("invalid interest"):
        tx = bzx.borrowOrTradeFromPool(zeroMaxTermParamsId, 1, False, initialMargin, 
            [Constants["ZERO_ADDRESS"], Constants["ZERO_ADDRESS"], Constants["ZERO_ADDRESS"], Constants["ZERO_ADDRESS"]], 
            [1, newPrincipal, 0, 1, 1], 
            b"", {"from": accounts[1], "value": "0 ether"})
        tx.info()

def test_borrowOrTradeFromPoolLoanParamsDisabled(Constants, bzx, linkDaiMarginParamsId, accounts):
    tx = bzx.disableLoanParams([linkDaiMarginParamsId])
    tx.info()
    initialMargin = 10**20
    newPrincipal = 10
    with reverts("loanParams disabled"):
        tx = bzx.borrowOrTradeFromPool(linkDaiMarginParamsId, 1, False, initialMargin, 
            [Constants["ZERO_ADDRESS"], Constants["ZERO_ADDRESS"], Constants["ZERO_ADDRESS"], Constants["ZERO_ADDRESS"]], 
            [1, newPrincipal, 0, 1, 1], 
            b"", {"from": accounts[1], "value": "0 ether"})
        tx.info()


# TODO this is impossible to reach
# def test_borrowOrTradeFromPoolLoanExists(Constants, bzx, accounts, linkDaiMarginParamsId):
#     with reverts("loan exists"):
#         tx = bzx.borrowOrTradeFromPool(linkDaiMarginParamsId, 1, False, initialMargin, 
#             [Constants["ZERO_ADDRESS"], Constants["ZERO_ADDRESS"], Constants["ZERO_ADDRESS"], Constants["ZERO_ADDRESS"]], 
#             [1, newPrincipal, 0, 1, 1], 
#             b"", {"from": accounts[1], "value": "0 ether"})
#         tx.info()

def test_borrowOrTradeFromPoolLoanHasEnded(Constants, bzx, accounts, linkDaiMarginParamsId):
    initialMargin = 10**20
    newPrincipal = 10
    with reverts("loan has ended"):
        tx = bzx.borrowOrTradeFromPool(linkDaiMarginParamsId, 1, False, initialMargin, 
                [Constants["ZERO_ADDRESS"], Constants["ZERO_ADDRESS"], Constants["ZERO_ADDRESS"], Constants["ZERO_ADDRESS"]], 
                [1, newPrincipal, 0, 1, 1], 
                b"", {"from": accounts[1], "value": "0 ether"})
        tx.info()

def test_borrowOrTradeFromPoolBorrowerMismatch(Constants, bzx, accounts, linkDaiMarginParamsId, LINK, DAI):

    setupLoanPool(Constants, bzx, accounts[1], accounts[2])
    loanTokenSent = 100e18

    DAI.mint(
        bzx.address,
        loanTokenSent,
        { "from": accounts[0] }
    )
    collateralTokenSent = bzx.getRequiredCollateral(
        DAI.address,
        LINK.address,
        loanTokenSent,
        100e18,
        False
    )
    LINK.mint(
        bzx.address,
        collateralTokenSent,
        { "from": accounts[0] }
    )
    tx = bzx.borrowOrTradeFromPool(
        linkDaiMarginParamsId, #loanParamsId
        "0", # loanId
        False, # isTorqueLoan,
        100e18, # initialMargin
        [
            accounts[2], # lender
            accounts[1], # borrower
            accounts[1], # receiver
            Constants["ZERO_ADDRESS"], # manager
        ],
        [
            5e18, # newRate (5%)
            loanTokenSent, # newPrincipal
            0, # torqueInterest
            loanTokenSent, # loanTokenSent
            collateralTokenSent # collateralTokenSent
        ],
        b'', # loanDataBytes
        { "from": accounts[1] }
    )
    tx.info()
    loanId = tx.events["Trade"][0]["loanId"]

    initialMargin = 10**20
    newPrincipal = 10
    with reverts("borrower mismatch"):
        tx = bzx.borrowOrTradeFromPool(linkDaiMarginParamsId, loanId, False, initialMargin, 
                [Constants["ZERO_ADDRESS"], Constants["ZERO_ADDRESS"], Constants["ZERO_ADDRESS"], Constants["ZERO_ADDRESS"]], 
                [1, newPrincipal, 0, 1, 1], 
                b"", {"from": accounts[1], "value": "0 ether"})
        tx.info()

def test_borrowOrTradeFromPoolLenderMismatch(Constants, bzx, accounts, linkDaiMarginParamsId, LINK, DAI):

    setupLoanPool(Constants, bzx, accounts[1], accounts[2])
    loanTokenSent = 100e18

    DAI.mint(
        bzx.address,
        loanTokenSent,
        { "from": accounts[0] }
    )
    collateralTokenSent = bzx.getRequiredCollateral(
        DAI.address,
        LINK.address,
        loanTokenSent,
        100e18,
        False
    )
    LINK.mint(
        bzx.address,
        collateralTokenSent,
        { "from": accounts[0] }
    )
    tx = bzx.borrowOrTradeFromPool(
        linkDaiMarginParamsId, #loanParamsId
        "0", # loanId
        False, # isTorqueLoan,
        100e18, # initialMargin
        [
            accounts[2], # lender
            accounts[1], # borrower
            accounts[1], # receiver
            Constants["ZERO_ADDRESS"], # manager
        ],
        [
            5e18, # newRate (5%)
            loanTokenSent, # newPrincipal
            0, # torqueInterest
            loanTokenSent, # loanTokenSent
            collateralTokenSent # collateralTokenSent
        ],
        b'', # loanDataBytes
        { "from": accounts[1] }
    )
    tx.info()
    loanId = tx.events["Trade"][0]["loanId"]

    initialMargin = 10**20
    newPrincipal = 10
    with reverts("lender mismatch"):
        tx = bzx.borrowOrTradeFromPool(linkDaiMarginParamsId, loanId, False, initialMargin, 
                [Constants["ZERO_ADDRESS"], accounts[1], Constants["ZERO_ADDRESS"], Constants["ZERO_ADDRESS"]], 
                [1, newPrincipal, 0, 1, 1], 
                b"", {"from": accounts[1], "value": "0 ether"})
        tx.info()

def test_borrowOrTradeFromPoolLoanParamMismatch(Constants, bzx, accounts, linkDaiMarginParamsId, otherLinkDaiMarginParamsId, LINK, DAI):

    setupLoanPool(Constants, bzx, accounts[1], accounts[2])
    loanTokenSent = 100e18

    DAI.mint(
        bzx.address,
        loanTokenSent,
        { "from": accounts[0] }
    )
    collateralTokenSent = bzx.getRequiredCollateral(
        DAI.address,
        LINK.address,
        loanTokenSent,
        100e18,
        False
    )
    LINK.mint(
        bzx.address,
        collateralTokenSent,
        { "from": accounts[0] }
    )
    tx = bzx.borrowOrTradeFromPool(
        linkDaiMarginParamsId, #loanParamsId
        "0", # loanId
        False, # isTorqueLoan,
        100e18, # initialMargin
        [
            accounts[2], # lender
            accounts[1], # borrower
            accounts[1], # receiver
            Constants["ZERO_ADDRESS"], # manager
        ],
        [
            5e18, # newRate (5%)
            loanTokenSent, # newPrincipal
            0, # torqueInterest
            loanTokenSent, # loanTokenSent
            collateralTokenSent # collateralTokenSent
        ],
        b'', # loanDataBytes
        { "from": accounts[1] }
    )
    tx.info()
    loanId = tx.events["Trade"][0]["loanId"]

    initialMargin = 10**20
    newPrincipal = 10
    with reverts("loanParams mismatch"):
        tx = bzx.borrowOrTradeFromPool(otherLinkDaiMarginParamsId, loanId, False, initialMargin, 
                [accounts[2], accounts[1], Constants["ZERO_ADDRESS"], Constants["ZERO_ADDRESS"]], 
                [1, newPrincipal, 0, 1, 1], 
                b"", {"from": accounts[1], "value": "0 ether"})
        tx.info()

def test_borrowOrTradeFromPoolSurplusLoanToken(Constants, bzx, accounts, linkDaiMarginParamsId, LINK, DAI):

    setupLoanPool(Constants, bzx, accounts[1], accounts[2])
    loanTokenSent = 100e18

    DAI.mint(
        bzx.address,
        loanTokenSent,
        { "from": accounts[0] }
    )
    collateralTokenSent = bzx.getRequiredCollateral(
        DAI.address,
        LINK.address,
        loanTokenSent,
        100e18,
        False
    )
    LINK.mint(
        bzx.address,
        collateralTokenSent,
        { "from": accounts[0] }
    )

    with reverts("surplus loan token"):
        tx = bzx.borrowOrTradeFromPool(
            linkDaiMarginParamsId, #loanParamsId
            "0", # loanId
            True, # isTorqueLoan,
            100e18, # initialMargin
            [
                accounts[2], # lender
                accounts[1], # borrower
                accounts[1], # receiver
                Constants["ZERO_ADDRESS"], # manager
            ],
            [
                5e18, # newRate (5%)
                loanTokenSent, # newPrincipal
                0, # torqueInterest
                loanTokenSent, # loanTokenSent
                collateralTokenSent # collateralTokenSent
            ],
            b'', # loanDataBytes
            { "from": accounts[1] }
        )

def test_borrowOrTradeFromPoolUnhealtyPosition(Constants, bzx, accounts, linkDaiMarginParamsId, LINK, DAI):

    setupLoanPool(Constants, bzx, accounts[1], accounts[2])
    loanTokenSent = 100e18

    DAI.mint(
        bzx.address,
        loanTokenSent,
        { "from": accounts[0] }
    )
    collateralTokenSent = bzx.getRequiredCollateral(
        DAI.address,
        LINK.address,
        loanTokenSent,
        100e18,
        False
    )
    LINK.mint(
        bzx.address,
        collateralTokenSent,
        { "from": accounts[0] }
    )

    with reverts("unhealthy position"):
        tx = bzx.borrowOrTradeFromPool(
            linkDaiMarginParamsId, #loanParamsId
            "0", # loanId
            False, # isTorqueLoan,
            100e18, # initialMargin
            [
                accounts[2], # lender
                accounts[1], # borrower
                accounts[1], # receiver
                Constants["ZERO_ADDRESS"], # manager
            ],
            [
                5e18, # newRate (5%)
                loanTokenSent, # newPrincipal
                0, # torqueInterest
                loanTokenSent, # loanTokenSent
                10 # collateralTokenSent
            ],
            b'', # loanDataBytes
            { "from": accounts[1] }
        )

def test_setDelegatedManagerUnauthorized(Constants, bzx):
    with reverts("unauthorized"):
        bzx.setDelegatedManager(0, Constants["ZERO_ADDRESS"], 0);
