#!/usr/bin/python3

import pytest
from brownie import Wei, reverts

def test_setLoanPool(Constants, bzx, accounts):
    with reverts("count mismatch"):
        bzx.setLoanPool(
            [
                accounts[6],
                accounts[8]
            ],
            [
                accounts[9]
            ]
        )

def test_setSupportedTokens(Constants, bzx, DAI, LINK):
    with reverts("count mismatch"):
        bzx.setSupportedTokens(
        [
            DAI,
            LINK
        ],
        [
            True
        ],
            False
    )

def test_setLendingFeePercent(Constants, bzx):
    with reverts("value too high"):
        bzx.setLendingFeePercent(11**20)

def test_setTradingFeePercent(Constants, bzx):
    with reverts("value too high"):
        bzx.setTradingFeePercent(11**20)

def test_setBorrowingFeePercent(Constants, bzx):
    with reverts("value too high"):
        bzx.setBorrowingFeePercent(11**20)

def test_setAffiliateFeePercent(Constants, bzx):
    with reverts("value too high"):
        bzx.setAffiliateFeePercent(11**20)

def test_setLiquidationIncentivePercent(Constants, bzx, DAI, WETH):
    with reverts("value too high"):
        bzx.setLiquidationIncentivePercent([DAI], [WETH],[11**20])

def test_withdrawLendingFees(Constants, bzx, DAI, accounts):
    with reverts("unauthorized"):
        bzx.withdrawFees([DAI], accounts[0], 1)

def test_withdrawLendingFeesZeroBalance(Constants, bzx, DAI, accounts):
    bzx.setFeesController(accounts[0])
    amountsView = bzx.queryFees.call([DAI], 1)[0]
    amounts = bzx.withdrawFees.call([DAI], accounts[0], 1)
    assert(amounts[0] == 0)

def test_withdrawTradingFees(Constants, bzx, DAI, accounts):
    with reverts("unauthorized"):
        bzx.withdrawFees([DAI], accounts[0], 2)

def test_withdrawTradingFeesZeroBalance(Constants, bzx, DAI, accounts):
    bzx.setFeesController(accounts[0])
    amountsView = bzx.queryFees.call([DAI], 2)[0]
    amounts = bzx.withdrawFees.call([DAI], accounts[0], 2)
    assert(amountsView[0] == 0)
    assert(amounts[0] == 0)

def test_withdrawBorrowingFees(Constants, bzx, DAI, accounts):
    with reverts("unauthorized"):
        bzx.withdrawFees([DAI], accounts[0], 3)

def test_withdrawBorrowingFeesZeroBalance(Constants, bzx, DAI, accounts):
    bzx.setFeesController(accounts[0])
    amountsView = bzx.queryFees.call([DAI], 3)[0]
    amounts = bzx.withdrawFees.call([DAI], accounts[0], 3)
    assert(amountsView[0] == 0)
    assert(amounts[0] == 0)

def test_withdrawAllFees(Constants, bzx, DAI, accounts):
    with reverts("unauthorized"):
        bzx.withdrawFees([DAI], accounts[0], 0)

def test_withdrawAllFeesZeroBalance(Constants, bzx, DAI, accounts):
    bzx.setFeesController(accounts[0])
    amountsView = bzx.queryFees.call([DAI], 0)[0]
    amounts = bzx.withdrawFees.call([DAI], accounts[0], 0)
    assert(amountsView[0] == 0)
    assert(amounts[0] == 0)
