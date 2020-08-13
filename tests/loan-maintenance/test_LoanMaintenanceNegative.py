#!/usr/bin/python3

import pytest
from brownie import Wei, reverts

def test_depositCollateralDepositAmountIsZero(Constants, bzx):
    with reverts("depositAmount is 0"):
        bzx.depositCollateral(0, 0)

def test_depositCollateralLoanIsClosed(Constants, bzx, accounts, LINK, DAI):
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
    loanParamsId = tx.events["LoanParamsIdSetup"][0]["id"]
    bzx.disableLoanParams([loanParamsId], { "from": accounts[0] })
    with reverts("depositAmount is 0"):
        bzx.depositCollateral(loanParamsId, 0)

def test_depositCollateralWrongAssetSent(Constants, bzx):
    assert False

# def test_depositCollateralEtherDepositMismatch(Constants, bzx):
#     assert False

# def test_withdrawCollateralWithdrawAmountIsZero(Constants, bzx):
#     assert False

# def test_withdrawCollateralLoanIsClosed(Constants, bzx):
#     assert False

# def test_withdrawCollateralUnauthorized(Constants, bzx):
#     assert False


# def test_extendLoanDurationDepositAmountIsZero(Constants, bzx):
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

