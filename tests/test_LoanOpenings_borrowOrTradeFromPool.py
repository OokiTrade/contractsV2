#!/usr/bin/python3

import pytest
from brownie import Contract, Wei, reverts


@pytest.fixture(scope="module", autouse=True)
def loanOpenings(LoanOpenings, FuncSigs, accounts, bzx, bzxproxy, Constants, priceFeeds, swapsImpl):

    loanOpenings = accounts[0].deploy(LoanOpenings)

    sigs = []
    for s in FuncSigs["LoanOpenings"].values():
        sigs.append(s)
    targets = [loanOpenings.address] * len(sigs)
    bzxproxy.setTargets(sigs, targets)

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
        "initialMargin": Wei("50 ether"),
        "maintenanceMargin": Wei("15 ether"),
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

    loanTokenSent = 104.25e18

    DAI.mint(
        bzx.address,
        loanTokenSent,
        { "from": accounts[0] }
    )
    
    collateralTokenSent = bzx.getRequiredCollateral(
        DAI.address,
        LINK.address,
        100.1e18,
        50e18,
        False
    )
    LINK.mint(
        bzx.address,
        collateralTokenSent,
        { "from": accounts[0] }
    )

    bZxBeforeDAIBalance = DAI.balanceOf(bzx.address)
    print("bZxBeforeDAIBalance", bZxBeforeDAIBalance)
    
    bZxBeforeLINKBalance = LINK.balanceOf(bzx.address)
    print("bZxBeforeLINKBalance", bZxBeforeLINKBalance)

    tx = bzx.borrowOrTradeFromPool(
        LinkDaiParamsId, #loanParamsId
        "0", # loanId
        False, # isTorqueLoan,
        [
            accounts[2], # lender
            accounts[1], # borrower
            accounts[1], # receiver
            Constants["ZERO_ADDRESS"], # manager
        ],
        [
            5e18, # newRate (5%)
            100e18, # newPrincipal
            0,#1.25e18, # torqueInterest (100e18 * 0.05 / 365 * 7884000 / 86400)
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

    #assert(borrowerBeforeBalance - 10e18 == borrowerAfterBalance)
    #assert(receiverBeforeBalance + 1e18 == receiverAfterBalance)
    
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
    
    assert(False)




 
 




