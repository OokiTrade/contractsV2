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
        ]
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

def test_setLiquidationIncentivePercent(Constants, bzx, DAI):
    with reverts("value too high"):
        bzx.setLiquidationIncentivePercent([DAI],[11**20])

def test_withdrawLendingFees(Constants, bzx, DAI, accounts):
    with reverts("unauthorized"):
        bzx.withdrawLendingFees([DAI], accounts[0])

def test_withdrawLendingFeesZeroBalance(Constants, bzx, DAI, accounts):
    bzx.setFeesController(accounts[0])
    amounts = bzx.withdrawLendingFees.call([DAI], accounts[0])
    assert(amounts[0] == 0)

def test_withdrawTradingFees(Constants, bzx, DAI, accounts):
    with reverts("unauthorized"):
        bzx.withdrawTradingFees([DAI], accounts[0])

def test_withdrawTradingFeesZeroBalance(Constants, bzx, DAI, accounts):
    bzx.setFeesController(accounts[0])
    amounts = bzx.withdrawTradingFees.call([DAI], accounts[0])
    assert(amounts[0] == 0)

def test_withdrawBorrowingFees(Constants, bzx, DAI, accounts):
    with reverts("unauthorized"):
        bzx.withdrawTradingFees([DAI], accounts[0])

def test_withdrawBorrowingFeesZeroBalance(Constants, bzx, DAI, accounts):
    bzx.setFeesController(accounts[0])
    amounts = bzx.withdrawBorrowingFees.call([DAI], accounts[0])
    assert(amounts[0] == 0)
