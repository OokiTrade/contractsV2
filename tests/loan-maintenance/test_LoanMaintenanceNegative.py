#!/usr/bin/python3

import pytest
from brownie import Wei, reverts

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
        "fixedLoanTerm": "0" # torque loan
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
def loanId(Constants, bzx, DAI, LINK, accounts, web3, LinkDaiBorrowParamsId):
    ## setup simulated loan pool
    bzx.setLoanPool(
        [
            accounts[1],
        ],
        [
            accounts[2]
        ]
    )

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
    print(tx.events)
    print(tx.info())

    bZxAfterDAIBalance = DAI.balanceOf(bzx.address)
    print("bZxAfterDAIBalance", bZxAfterDAIBalance)
    
    bZxAfterLINKBalance = LINK.balanceOf(bzx.address)
    print("bZxAfterLINKBalance", bZxAfterLINKBalance)

    borrowEvent = tx.events["Borrow"][0]
    print("borrowEvent", borrowEvent)
    print("borrowEvent.loanId", borrowEvent["loanId"])
    return borrowEvent["loanId"]
    


@pytest.fixture(scope="module")
def loanIdWeth(Constants, bzx, DAI, LINK, accounts, web3, WethDaiBorrowParamsId):
    ## setup simulated loan pool
    bzx.setLoanPool(
        [
            accounts[1],
        ],
        [
            accounts[2]
        ]
    )

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
        WethDaiBorrowParamsId, #loanParamsId
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
    print(tx.events)
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

def test_depositCollateralEtherDepositMismatch(Constants, bzx, loanIdWeth):
    with reverts("ether deposit mismatch"):
        bzx.depositCollateral(loanIdWeth, 1, {"value": "2 ether"})

def test_withdrawCollateralWithdrawAmountIsZero(Constants, bzx, accounts):
    with reverts("withdrawAmount is 0"):
        bzx.withdrawCollateral(0, accounts[1], 0)

def test_withdrawCollateralLoanIsClosed(Constants, bzx, accounts):
    with reverts("loan is closed"):
        bzx.withdrawCollateral(0, accounts[1], 1)

def test_withdrawCollateralUnauthorized(Constants, bzx, accounts, loanId):
    with reverts("unauthorized"):
        bzx.withdrawCollateral(loanId, accounts[9], 1)

# def test_extendLoanDurationDepositAmountIsZero(Constants, bzx):
#     with reverts("depositAmount is 0"):
#         bzx.extendLoanDuration(0, 1, 1)
#     assert False

# def test_extendLoanDurationLoanIsClosed(Constants, bzx):
#     assert False

# def test_extendLoanDurationUnauthorized(Constants, bzx):
#     assert False

# def test_extendLoanDurationIndefiniteTermOnly(Constants, bzx):
#     assert False

# def test_extendLoanDurationWrongAssetsSent(Constants, bzx):
#     assert False

# def test_extendLoanDurationDepositCannotCoverBackInterest(Constants, bzx):
#     assert False

# def test_extendLoanDurationLoanTooShort(Constants, bzx):
#     assert False

# def test_extendLoanDurationLoanTooShort2(Constants, bzx):
#     assert False

