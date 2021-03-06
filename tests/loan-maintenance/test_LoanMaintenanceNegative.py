#!/usr/bin/python3

import pytest
from brownie import Wei, reverts
from helpers import setupLoanPool

@pytest.fixture(scope="module")
def LinkDaiBorrowParamsId(Constants, LINK, DAI, bzx, accounts):
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
def WethDaiBorrowParamsId(Constants, WETH, DAI, bzx, accounts):
    loanParams = {
        "id": "0x0",
        "active": False,
        "owner": Constants["ZERO_ADDRESS"],
        "loanToken": DAI.address,
        "collateralToken": WETH.address,
        "minInitialMargin": 20e18,
        "maintenanceMargin": 15e18,
        "fixedLoanTerm": "0" # torque loan
    }
    tx = bzx.setupLoanParams([list(loanParams.values())])
    return tx.events["LoanParamsIdSetup"][0]["id"]

@pytest.fixture(scope="module")
def ParamsIdMaxLoanTermNonZero(Constants, LINK, DAI, bzx, accounts):
    loanParams = {
        "id": "0x0",
        "active": True,
        "owner": Constants["ZERO_ADDRESS"],
        "loanToken": DAI.address,
        "collateralToken": LINK.address,
        "minInitialMargin": 20e18,
        "maintenanceMargin": 15e18,
        # "fixedLoanTerm": "0", # torque loan
        "maxLoanTerm": "26000"
    }
    tx = bzx.setupLoanParams([list(loanParams.values())])
    return tx.events["LoanParamsIdSetup"][0]["id"]

@pytest.fixture(scope="module")
def ParamsIdWethMaxLoanTermNonZero(Constants, LINK, DAI, bzx, accounts, WETH):
    loanParams = {
        "id": "0x0",
        "active": True,
        "owner": Constants["ZERO_ADDRESS"],
        "loanToken": WETH.address,
        "collateralToken": LINK.address,
        "minInitialMargin": 20e18,
        "maintenanceMargin": 15e18,
        # "fixedLoanTerm": "0", # torque loan
        "maxLoanTerm": "26000"
    }
    tx = bzx.setupLoanParams([list(loanParams.values())])
    return tx.events["LoanParamsIdSetup"][0]["id"]

@pytest.fixture(scope="module")
def loanId(Constants, bzx, DAI, LINK, accounts, web3, LinkDaiBorrowParamsId):
    return getLoanId(Constants, bzx, DAI, LINK, accounts, web3, LinkDaiBorrowParamsId)

@pytest.fixture(scope="module")
def loanIdWeth(Constants, bzx, DAI, LINK, accounts, web3, WethDaiBorrowParamsId):
    return getLoanId(Constants, bzx, DAI, LINK, accounts, web3, WethDaiBorrowParamsId)

@pytest.fixture(scope="module")
def loanIdMaxLoanTermZero(Constants, bzx, DAI, LINK, accounts, web3, LinkDaiBorrowParamsId):
    return getLoanId(Constants, bzx, DAI, LINK, accounts, web3, LinkDaiBorrowParamsId)

@pytest.fixture(scope="module")
def loanIdMaxLoanTermNonZero(Constants, bzx, DAI, LINK, accounts, web3, ParamsIdMaxLoanTermNonZero):
    return getLoanIdNonTorque(Constants, bzx, DAI, LINK, accounts, web3, ParamsIdMaxLoanTermNonZero)

@pytest.fixture(scope="module")
def loanIdWethMaxLoanTermNonZero(Constants, bzx, DAI, LINK, accounts, web3, ParamsIdWethMaxLoanTermNonZero):
    return getLoanIdNonTorque(Constants, bzx, DAI, LINK, accounts, web3, ParamsIdWethMaxLoanTermNonZero)

def getLoanIdNonTorque(Constants, bzx, DAI, LINK, accounts, web3, LinkDaiBorrowParamsId):
    ## setup simulated loan pool
    setupLoanPool(Constants, bzx, accounts[1], accounts[2])

    bZxBeforeDAIBalance = DAI.balanceOf(bzx.address)
    print("bZxBeforeDAIBalance", bZxBeforeDAIBalance)
    
    bZxBeforeLINKBalance = LINK.balanceOf(bzx.address)
    print("bZxBeforeLINKBalance", bZxBeforeLINKBalance)

    ## loanTokenSent to protocol is just the borrowed/escrowed interest since the actual borrow would have 
    ## already been transfered to the borrower by the pool before borrowOrTradeFromPool is called
    loanTokenSent = 1e18
    newPrincipal = 101e18

    DAI.mint(
        bzx.address,
        loanTokenSent,
        { "from": accounts[0] }
    )
    
    collateralTokenSent = bzx.getRequiredCollateral(
        DAI.address,
        LINK.address,
        newPrincipal,
        50e18,
        True
    )
    LINK.mint(
        bzx.address,
        collateralTokenSent,
        { "from": accounts[0] }
    )

    print("newPrincipal",newPrincipal)
    print("loanTokenSent",loanTokenSent)
    print("collateralTokenSent",collateralTokenSent)

    tx = bzx.borrowOrTradeFromPool(
        LinkDaiBorrowParamsId, #loanParamsId
        "0", # loanId - starts a new loan
        False, # isTorqueLoan,
        50e18, # initialMargin
        [
            accounts[2], # lender
            accounts[1], # borrower
            accounts[1], # receiver
            Constants["ZERO_ADDRESS"], # manager
        ],
        [
            5e18, # newRate (5%)
            newPrincipal, # newPrincipal
            1e18, # torqueInterest
            loanTokenSent, # loanTokenSent
            collateralTokenSent # collateralTokenSent
        ],
        b'', # loanDataBytes
        { "from": accounts[1] }
    )
    print(tx.info())

    bZxAfterDAIBalance = DAI.balanceOf(bzx.address)
    print("bZxAfterDAIBalance", bZxAfterDAIBalance)
    
    bZxAfterLINKBalance = LINK.balanceOf(bzx.address)
    print("bZxAfterLINKBalance", bZxAfterLINKBalance)

    tradeEvent = tx.events["Trade"][0]
    print("borrowEvent", tradeEvent)
    print("borrowEvent.loanId", tradeEvent["loanId"])
    return tradeEvent["loanId"]

def getLoanId(Constants, bzx, DAI, LINK, accounts, web3, LinkDaiBorrowParamsId):
    ## setup simulated loan pool
    setupLoanPool(Constants, bzx, accounts[1], accounts[2])

    bZxBeforeDAIBalance = DAI.balanceOf(bzx.address)
    print("bZxBeforeDAIBalance", bZxBeforeDAIBalance)
    
    bZxBeforeLINKBalance = LINK.balanceOf(bzx.address)
    print("bZxBeforeLINKBalance", bZxBeforeLINKBalance)

    ## loanTokenSent to protocol is just the borrowed/escrowed interest since the actual borrow would have 
    ## already been transfered to the borrower by the pool before borrowOrTradeFromPool is called
    loanTokenSent = 1e18
    newPrincipal = 101e18

    DAI.mint(
        bzx.address,
        loanTokenSent,
        { "from": accounts[0] }
    )
    
    collateralTokenSent = bzx.getRequiredCollateral(
        DAI.address,
        LINK.address,
        newPrincipal,
        50e18,
        True
    )
    LINK.mint(
        bzx.address,
        collateralTokenSent,
        { "from": accounts[0] }
    )

    print("newPrincipal",newPrincipal)
    print("loanTokenSent",loanTokenSent)
    print("collateralTokenSent",collateralTokenSent)

    tx = bzx.borrowOrTradeFromPool(
        LinkDaiBorrowParamsId, #loanParamsId
        "0", # loanId - starts a new loan
        True, # isTorqueLoan,
        50e18, # initialMargin
        [
            accounts[2], # lender
            accounts[1], # borrower
            accounts[1], # receiver
            Constants["ZERO_ADDRESS"], # manager
        ],
        [
            5e18, # newRate (5%)
            newPrincipal, # newPrincipal
            1e18, # torqueInterest
            loanTokenSent, # loanTokenSent
            collateralTokenSent # collateralTokenSent
        ],
        b'', # loanDataBytes
        { "from": accounts[1] }
    )
    print(tx.info())

    bZxAfterDAIBalance = DAI.balanceOf(bzx.address)
    print("bZxAfterDAIBalance", bZxAfterDAIBalance)
    
    bZxAfterLINKBalance = LINK.balanceOf(bzx.address)
    print("bZxAfterLINKBalance", bZxAfterLINKBalance)

    borrowEvent = tx.events["Borrow"][0]
    print("borrowEvent", borrowEvent)
    print("borrowEvent.loanId", borrowEvent["loanId"])
    return borrowEvent["loanId"]

def test_depositCollateralDepositAmountIsZero(Constants, bzx):
    with reverts("depositAmount is 0"):
        bzx.depositCollateral(0, 0)

def test_depositCollateralLoanIsClosed(Constants, bzx):
    with reverts("loan is closed"):
        bzx.depositCollateral(0, 1)

def test_depositCollateralWrongAssetSent(Constants, bzx, loanId):
    with reverts("wrong asset sent"):
        bzx.depositCollateral(loanId, 1, {"value": "1 ether"})

# TODO this is impossible to test until Constants have injected wethToken
# def test_depositCollateralEtherDepositMismatch(Constants, bzx, loanId):
#     with reverts("ether deposit mismatch"):
#         bzx.depositCollateral(loanId, 1, {"value": "2 ether"})

def test_withdrawCollateralWithdrawAmountIsZero(Constants, bzx, accounts):
    with reverts("withdrawAmount is 0"):
        bzx.withdrawCollateral(0, accounts[1], 0)

def test_withdrawCollateralLoanIsClosed(Constants, bzx, accounts):
    with reverts("loan is closed"):
        bzx.withdrawCollateral(0, accounts[1], 1)

def test_withdrawCollateralUnauthorized(Constants, bzx, accounts, loanId):
    with reverts("unauthorized"):
        bzx.withdrawCollateral(loanId, accounts[9], 1)

def test_extendLoanDurationDepositAmountIsZero(Constants, bzx):
    with reverts("depositAmount is 0"):
        bzx.extendLoanDuration(0, 0, False, 0)

def test_extendLoanDurationLoanIsClosed(Constants, bzx):
    with reverts("loan is closed"):
        bzx.extendLoanDuration(0, 1, False, 0)

def test_extendLoanDurationUnauthorized(Constants, bzx, loanId):
    with reverts("unauthorized"):
        bzx.extendLoanDuration(loanId, 1, True, 1)

def test_extendLoanDurationIndefiniteTermOnly(Constants, bzx, loanIdMaxLoanTermNonZero):
    with reverts("SafeERC20: low-level call failed"):
        bzx.extendLoanDuration(loanIdMaxLoanTermNonZero, 1, False, 0)

def test_extendLoanDurationWrongAssetsSent(Constants, bzx, loanIdMaxLoanTermZero):
    with reverts("wrong asset sent"):
        bzx.extendLoanDuration(loanIdMaxLoanTermZero, 1, False, 0, {"value": "1 ether"})

# TODO cannot be reached because it requires timestamp manipulation
# def test_extendLoanDurationDepositCannotCoverBackInterest(Constants, bzx, loanId, accounts):
#     with reverts("deposit cannot cover back interest"):
#         bzx.extendLoanDuration(loanId, 50e18, False, b'')

# def test_extendLoanDurationLoanTooShort(Constants, bzx, loanId, accounts):
#     with reverts("deposit cannot cover back interest"):
#         bzx.extendLoanDuration(loanId, 1, True, b'', {"from":accounts[1], "value": "1 ether"})
#     assert False

# TODO cannot be reached because it requires timestamp manipulation
# def test_extendLoanDurationLoanTooShort2(Constants, bzx):
#     assert False

