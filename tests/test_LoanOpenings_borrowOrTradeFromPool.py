#!/usr/bin/python3

import pytest
from brownie import Contract, Wei, reverts
from fixedint import *
from helpers import setupLoanPool

@pytest.fixture(scope="module")
def LinkDaiMarginParamsId(Constants, LINK, DAI, bzx, accounts):

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

def test_marginTradeFromPool_sim(Constants, LinkDaiMarginParamsId, bzx, DAI, LINK, accounts, web3):

    ## setup simulated loan pool
    setupLoanPool(Constants, bzx, accounts[1], accounts[2])

    bZxBeforeDAIBalance = DAI.balanceOf(bzx.address)
    print("bZxBeforeDAIBalance", bZxBeforeDAIBalance)
    
    bZxBeforeLINKBalance = LINK.balanceOf(bzx.address)
    print("bZxBeforeLINKBalance", bZxBeforeLINKBalance)

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

    print("loanTokenSent",loanTokenSent)
    print("collateralTokenSent",collateralTokenSent)

    tx = bzx.borrowOrTradeFromPool(
        LinkDaiMarginParamsId, #loanParamsId
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
    print(tx.events)

    bZxAfterDAIBalance = DAI.balanceOf(bzx.address)
    print("bZxAfterDAIBalance", bZxAfterDAIBalance)
    
    bZxAfterLINKBalance = LINK.balanceOf(bzx.address)
    print("bZxAfterLINKBalance", bZxAfterLINKBalance)

    tradeEvent = tx.events["Trade"][0]
    print(tradeEvent)

    interestForPosition = fixedint(loanTokenSent).mul(5e18).div(1e20).div(365).mul(2419200).div(86400)
    print("interestForPosition",interestForPosition)

    # expectedPositionSize = collateralTokenSent + ((loanTokenSent - interestForPosition) * tradeEvent["entryPrice"] // 1e18)
    expectedPositionSize = fixedint(loanTokenSent).sub(interestForPosition).mul(tradeEvent["entryPrice"]).div(1e18).add(collateralTokenSent)
    
    ## ignore differences in least significant digits due to rounding error
    expectedPositionSize = fixedint(expectedPositionSize).div(100)
    positionSize = fixedint(tradeEvent["positionSize"]).div(100)
    assert expectedPositionSize == positionSize

    '''l = bzx.getUserLoans(
        accounts[1],
        0,
        100,
        0,
        False,
        False)
    print (l)'''

    '''
    trace = web3.provider.make_request(
        "debug_traceTransaction", (tx.txid, {"disableMemory": True, "disableStack": True, "disableStorage": False})
    )
    trace = trace["result"]["structLogs"]
    for i in reversed(trace):
        if i["depth"] == 1:
            import pprint
            storage = pprint.pformat(i["storage"], indent=2, width=80)
            f = open("latest_storage.log", "w")
            f.write(storage)
            f.close()
            break
    '''
    
    #assert(False)

def test_borrowFromPool_sim(Constants, LinkDaiBorrowParamsId, bzx, DAI, LINK, accounts, web3):

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
        "0", # loanId
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

    bZxAfterDAIBalance = DAI.balanceOf(bzx.address)
    print("bZxAfterDAIBalance", bZxAfterDAIBalance)
    
    bZxAfterLINKBalance = LINK.balanceOf(bzx.address)
    print("bZxAfterLINKBalance", bZxAfterLINKBalance)

    borrowEvent = tx.events["Borrow"][0]
    print(borrowEvent)


    '''l = bzx.getUserLoans(
        accounts[1],
        0,
        100,
        0,
        False,
        False)
    print (l)'''

    '''
    trace = web3.provider.make_request(
        "debug_traceTransaction", (tx.txid, {"disableMemory": True, "disableStack": True, "disableStorage": False})
    )
    trace = trace["result"]["structLogs"]
    for i in reversed(trace):
        if i["depth"] == 1:
            import pprint
            storage = pprint.pformat(i["storage"], indent=2, width=80)
            f = open("latest_storage.log", "w")
            f.write(storage)
            f.close()
            break
    '''
    
    #assert(False)
