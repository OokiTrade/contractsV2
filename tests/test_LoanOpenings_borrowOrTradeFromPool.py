#!/usr/bin/python3

import pytest
from brownie import Contract, Wei, reverts
from fixedint import *

@pytest.fixture(scope="module", autouse=True)
def loanOpenings(LoanOpenings, accounts, bzx, Constants, priceFeeds, swapsImpl):
    bzx.replaceContract(accounts[0].deploy(LoanOpenings).address)

    bzx.setCoreParams(
        Constants["ZERO_ADDRESS"], # protocolTokenAddress
        priceFeeds.address, # priceFeeds
        swapsImpl.address, # swapsImpl
        10e18 # protocolFeePercent (10%)
    )

@pytest.fixture(scope="module")
def LinkDaiParamsId(Constants, LINK, DAI, bzx, accounts):

    loanParams = {
        "id": "0x0",
        "active": False,
        "owner": Constants["ZERO_ADDRESS"],
        "loanToken": DAI.address,
        "collateralToken": LINK.address,
        "initialMargin": 100e18, # 2x position (100% initialMargin for a LONG)
        "maintenanceMargin": 15e18,
        "fixedLoanTerm": "2419200" # 28 days
    }
    tx = bzx.setupLoanParams([list(loanParams.values())])
    return tx.events["LoanParamsIdSetup"][0]["id"]

def test_borrowOrTradeFromPool_sim(Constants, LinkDaiParamsId, bzx, DAI, LINK, accounts, web3):

    ## setup protocol manager
    bzx.setProtocolManagers(
        [
            accounts[1],
        ],
        [
            True
        ]
    )

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
        LinkDaiParamsId, #loanParamsId
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
    assert(expectedPositionSize == tradeEvent["positionSize"])

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




 
 




