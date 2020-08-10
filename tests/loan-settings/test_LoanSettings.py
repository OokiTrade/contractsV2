#!/usr/bin/python3

import pytest
from brownie import Wei, reverts

@pytest.fixture(scope="module", autouse=True)
def loanSettings(LoanSettings, accounts, bzx):
    bzx.replaceContract(accounts[0].deploy(LoanSettings).address)

@pytest.fixture(scope="module", autouse=True)
def loanParamsId(accounts, bzx, loanParams):
    tx = bzx.setupLoanParams([list(loanParams.values())])
    loanParamsId = tx.events["LoanParamsIdSetup"][0]["id"]
    return loanParamsId

@pytest.fixture(scope="module", autouse=True)
def loanParams(accounts, bzx, WETH, DAI, Constants):
    loanParams = {
        "id": "0x0",
        "active": False,
        "owner": Constants["ZERO_ADDRESS"],
        "loanToken": DAI.address,
        "collateralToken": WETH.address,
        "initialMargin": Wei("50 ether"),
        "maintenanceMargin": Wei("15 ether"),
        "fixedLoanTerm": "2419200"
    }
    return loanParams

def test_setup_removeLoanParams(bzx, accounts, DAI, loanParamsId, loanParams):
    loanParamsAfter = bzx.getLoanParams([loanParamsId])[0]
    loanParamsAfter = dict(zip(list(loanParams.keys()), loanParamsAfter))
    print(loanParamsAfter)

    assert(loanParamsAfter["id"] != "0x0")
    assert(loanParamsAfter["active"])
    assert(loanParamsAfter["owner"] == accounts[0])
    assert(loanParamsAfter["loanToken"] == DAI.address)

    with reverts("unauthorized owner"):
        bzx.disableLoanParams([loanParamsId], { "from": accounts[1] })
        
    bzx.disableLoanParams([loanParamsId], { "from": accounts[0] })
    assert(bzx.getLoanParams([loanParamsId])[0][0] != "0x0")

def test_setup_removeLoanOrder(bzx, accounts, DAI, loanParamsId, loanParams):
    loanParamsAfter = bzx.getLoanParams([loanParamsId])[0]
    loanParamsAfter = dict(zip(list(loanParams.keys()), loanParamsAfter))
    print(loanParamsAfter)
    
    assert(loanParamsAfter["id"] != "0x0")
    assert(loanParamsAfter["active"])
    assert(loanParamsAfter["owner"] == accounts[0])
    assert(loanParamsAfter["loanToken"] == DAI.address)

    with reverts("unauthorized owner"):
        bzx.disableLoanParams([loanParamsId], { "from": accounts[1] })
        
    bzx.disableLoanParams([loanParamsId], { "from": accounts[0] })
    assert(bzx.getLoanParams([loanParamsId])[0][0] != "0x0")

def test_disableLoanParams(bzx, accounts, DAI, WETH, loanParamsId, loanParams):
    bzx.disableLoanParams([loanParamsId], { "from": accounts[0] })
    loanParamsAfter = bzx.getLoanParams([loanParamsId])[0]
    loanParamsAfter = dict(zip(list(loanParams.keys()), loanParamsAfter))
    print("loanParamsAfter", loanParamsAfter)
    assert(loanParamsAfter["id"] != "0x0")
    assert(loanParamsAfter["active"] == False) # False because we disabled Loan Param just before
    assert(loanParamsAfter["owner"] == accounts[0])
    assert(loanParamsAfter["loanToken"] == DAI.address)
    assert(loanParamsAfter["collateralToken"] == WETH.address)
    assert(loanParamsAfter["initialMargin"] == Wei("50 ether"))
    assert(loanParamsAfter["maintenanceMargin"] == Wei("15 ether"))
    assert(loanParamsAfter["fixedLoanTerm"] == "2419200")

def test_getLoanParams(bzx, accounts, DAI, WETH, loanParamsId, loanParams):
    loanParamsAfter = bzx.getLoanParams([loanParamsId])[0]
    loanParamsAfter = dict(zip(list(loanParams.keys()), loanParamsAfter))
    print("loanParamsAfter", loanParamsAfter)
    assert(loanParamsAfter["id"] != "0x0")
    assert(loanParamsAfter["active"])
    assert(loanParamsAfter["owner"] == accounts[0])
    assert(loanParamsAfter["loanToken"] == DAI.address)
    assert(loanParamsAfter["collateralToken"] == WETH.address)
    assert(loanParamsAfter["initialMargin"] == Wei("50 ether"))
    assert(loanParamsAfter["maintenanceMargin"] == Wei("15 ether"))
    assert(loanParamsAfter["fixedLoanTerm"] == "2419200")

def test_getLoanParamsList(bzx, accounts, loanParamsId, loanParams):
    loanParamsList = bzx.getLoanParamsList(accounts[0], 0, 1)
    assert(loanParamsList[0] == loanParamsId)

def test_getTotalPrincipal(Constants, bzx, accounts, DAI, WETH, LINK, loanParamsId, loanParams):
    totalPrincipal = bzx.getTotalPrincipal(accounts[0], DAI.address)
    print("totalPrincipal", totalPrincipal)
    assert(totalPrincipal == 0)
