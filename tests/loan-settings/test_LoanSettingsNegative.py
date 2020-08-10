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

def test_disableUnauthorizedOwnerLoanSettings(bzx, accounts, DAI, loanParamsId,):
    with reverts("unauthorized owner"):
        bzx.disableLoanParams([loanParamsId], { "from": accounts[1] })

# TODO @Tom help: is there a way to get LoanSettings address
# def test_LoanSettings_fallback_not_allowd(bzx, accounts, DAI, web3, bZxProtocol):
#     print("LoanSettings", bZxProtocol)
#     with reverts("unauthorized owner"):
        # web3.eth.sendTransaction({ "from": str(accounts[0]), "to": bZxProtocol.address, "value": 1, "gas": "5999" })

def test_LoanSettings_loanParamAlreadyExists(bzx, accounts, DAI, loanParamsId, loanParams):
    with reverts("loanParams exists"):
        bzx.setupLoanParams([list(loanParams.values()), list(loanParams.values())])


def test_LoanSettings_otherRequires(bzx, accounts, DAI, loanParamsId, loanParams, Constants):

    localLoanParams = loanParams.copy()
   
    localLoanParams["loanToken"] = Constants["ZERO_ADDRESS"]
    print("localLoanParams",localLoanParams)
    with reverts("invalid params"):
        bzx.setupLoanParams([list(localLoanParams.values())])
 
    localLoanParams = loanParams.copy()
    localLoanParams["collateralToken"] = Constants["ZERO_ADDRESS"]
    with reverts("invalid params"):
        bzx.setupLoanParams([list(localLoanParams.values())])

    localLoanParams = loanParams.copy()
    localLoanParams["initialMargin"] = "10 ether"
    with reverts("invalid params"):
        bzx.setupLoanParams([list(localLoanParams.values())])

    localLoanParams = loanParams.copy()
    localLoanParams["fixedLoanTerm"] = 1
    with reverts("invalid params"):
        bzx.setupLoanParams([list(localLoanParams.values())])
