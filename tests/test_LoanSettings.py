#!/usr/bin/python3

import pytest

from brownie import Wei, reverts

def test_addremoveLoanParams(Constants, bzx, loanSettings, accounts, TestToken):

    accounts[0].deploy(TestToken, "Token0", "Token0", 18, 1e21)
    accounts[0].deploy(TestToken, "Token1", "Token1", 18, 1e21)

    loanParams = {
        "id": "0x0",
        "active": False,
        "owner": Constants["ZERO_ADDRESS"],
        "loanToken": TestToken[0].address,
        "collateralToken": TestToken[1].address,
        "initialMargin": Wei("50 ether"),
        "maintenanceMargin": Wei("15 ether"),
        "maxLoanDuration": "2419200"
    }
    tx = loanSettings.setupLoanParams["tuple[]"]([list(loanParams.values())])

    loanParamsId = tx.events["LoanParamsIdSetup"][0]["id"]

    loanParamsAfter = loanSettings.getLoanParams(loanParamsId)
    loanParamsAfter = dict(zip(list(loanParamsAfter.keys()), loanParamsAfter))
    print(loanParamsAfter)
    
    assert(loanParamsAfter["id"] != "0x0")
    assert(loanParamsAfter["active"])
    assert(loanParamsAfter["owner"] == accounts[0])
    assert(loanParamsAfter["loanToken"] == TestToken[0].address)

    with reverts("unauthorized owner"):
        loanSettings.disableLoanParams([loanParamsId], { "from": accounts[1] })
        
    loanSettings.disableLoanParams([loanParamsId], { "from": accounts[0] })
    assert(loanSettings.getLoanParams(loanParamsId)[0] != "0x0")
