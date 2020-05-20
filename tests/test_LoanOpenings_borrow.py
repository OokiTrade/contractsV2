#!/usr/bin/python3

import pytest
from brownie import Contract, Wei, reverts


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
def WethDaiParamsId(Constants, WETH, DAI, bzx, accounts):

    loanParams = {
        "id": "0x0",
        "active": False,
        "owner": Constants["ZERO_ADDRESS"],
        "loanToken": DAI.address,
        "collateralToken": WETH.address,
        "initialMargin": Wei("50 ether"),
        "maintenanceMargin": Wei("15 ether"),
        "fixedLoanTerm": "0"
    }
    tx = bzx.setupLoanParams([list(loanParams.values())])
    return tx.events["LoanParamsIdSetup"][0]["id"]

@pytest.fixture(scope="module")
def WethDaiOrderSetup(Constants, WethDaiParamsId, bzx, DAI, accounts):

    DAI.approve(bzx.address, Constants["MAX_UINT"])
    
    bzx.setupOrderWithId(
        WethDaiParamsId,
        1e24, #1M
        5e18, #5%
        86400,
        2419200,
        0,
        True,
        { "from": accounts[0] }
    )

def test_borrow(Constants, WethDaiParamsId, WethDaiOrderSetup, bzx, DAI, WETH, accounts, web3):

    #DAI.approve(bzx.address, Constants["MAX_UINT"])

    borrower = accounts[1]
    receiver = accounts[2]

    borrowerBeforeBalance = web3.eth.getBalance(str(borrower))
    receiverBeforeBalance = DAI.balanceOf(receiver)
    print("borrowerBeforeBalance", borrowerBeforeBalance)
    print("receiverBeforeBalance", receiverBeforeBalance)

    borrowAmount = 1e18

    collateralTokenSent = bzx.getDepositAmountForBorrow(
        DAI.address,
        WETH.address,
        borrowAmount,
        50e18,
        864000,
        5e18
    )

    tx = bzx.borrow(
        WethDaiParamsId, ## loanParamsId
        0,  ## loanId
        borrowAmount, ## borrowAmount
        864000, ## initialLoanDuration
        accounts[0], ## lender
        accounts[2], ## receiver
        Constants["ZERO_ADDRESS"], ## manager
        True, ## depositCollateral
        { "from": accounts[1], "value": collateralTokenSent }
    )
    print(tx.events)

    borrowerAfterBalance = web3.eth.getBalance(str(borrower))
    receiverAfterBalance = DAI.balanceOf(receiver)
    print("borrowerAfterBalance", borrowerAfterBalance)
    print("receiverAfterBalance", receiverAfterBalance)

    assert(borrowerBeforeBalance - collateralTokenSent == borrowerAfterBalance)
    assert(receiverBeforeBalance + borrowAmount == receiverAfterBalance)

    l = bzx.getUserLoans(
        accounts[1],
        0,
        100,
        0,
        False,
        False)
    print (l)

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
