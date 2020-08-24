#!/usr/bin/python3

import pytest
from brownie import Wei
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
def loanId(Constants, bzx, DAI, LINK, accounts, web3, LinkDaiBorrowParamsId):
    return getLoanId(Constants, bzx, DAI, LINK, accounts, web3, LinkDaiBorrowParamsId)

def getLoanId(Constants, bzx, DAI, LINK, accounts, web3, LinkDaiBorrowParamsId):
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
    print(tx.info())

    bZxAfterDAIBalance = DAI.balanceOf(bzx.address)
    print("bZxAfterDAIBalance", bZxAfterDAIBalance)
    
    bZxAfterLINKBalance = LINK.balanceOf(bzx.address)
    print("bZxAfterLINKBalance", bZxAfterLINKBalance)

    borrowEvent = tx.events["Borrow"][0]
    print("borrowEvent", borrowEvent)
    print("borrowEvent.loanId", borrowEvent["loanId"])
    return borrowEvent["loanId"]

# TODO the following impossible to reach because of the Constants hardcode 

# def test_depositCollateral(Constants, bzx, loan):
#     bzx.depositCollateral(0, 0)
#     assert False

# def test_extendLoanDuration(Constants, bzx):
#     assert False

def test_getActiveLoans(bzx, loanId):
    tx = bzx.getActiveLoans(0, 1, False)
    print("tx", tx[0][0])
    assert (tx[0][0] == loanId)

def test_getLenderInterestData(bzx, loanId, accounts, DAI):
    tx = bzx.getLenderInterestData(accounts[1], DAI)
    print("tx", tx)
    assert(tx[0] == 0)
    assert(tx[1] == 0)
    assert(tx[2] == 0)
    assert(tx[3] == 0)
    assert(tx[4] == 10000000000000000000)
    assert(tx[5] == 0)

def test_getLoan(bzx, loanId, DAI, LINK):
    loan = bzx.getLoan(loanId)
    print("loan", loan)
    assert(loan[0] == loanId)
    assert(loan[2] == DAI)
    assert(loan[3] == LINK)
    assert(loan[4] == 101e18)
    assert(loan[9] == 50e18)

def test_getLoanInterestData(bzx, loanId, DAI):
    interestData = bzx.getLoanInterestData(loanId)
    print("interestData", interestData)
    assert(interestData[0] == DAI)
    assert(interestData[2] == 1e18)

def test_getUserLoans(bzx, loanId, accounts, DAI, LINK):
    userLoans = bzx.getUserLoans(accounts[1], 0, 1, 0, 0, 0)[0]
    print("userLoans", userLoans)
    assert(userLoans[0] == loanId)
    assert(userLoans[2] == DAI)
    assert(userLoans[3] == LINK)
    assert(userLoans[4] == 101e18)
    assert(userLoans[9] == 50e18)

def test_reduceLoanDuration(bzx, accounts, loanId):
    tx = bzx.reduceLoanDuration(loanId, accounts[1], 1, { "from": accounts[1]})
    print("tx", tx.info())
    assert(tx.events["Transfer"][1]["from"] == bzx)
    assert(tx.events["Transfer"][1]["to"] == accounts[1])
    assert(tx.events["Transfer"][1]["value"] == 1)

def test_withdrawAccruedInterest(bzx, loanId, accounts, LINK):
    tx = bzx.withdrawAccruedInterest(LINK, { "from": accounts[2]})
    print("tx", tx.info())
    assert(tx.value == 0)

def test_withdrawCollateral(bzx, loanId, accounts):
    tx = bzx.withdrawCollateral(loanId, accounts[1], 1, { "from": accounts[1]})
    print("tx", tx.info())
    assert(tx.events["Transfer"]["from"] == bzx)
    assert(tx.events["Transfer"]["to"] == accounts[1])
    assert(tx.events["Transfer"]["value"] == 1)
    assert(tx.return_value == 1)