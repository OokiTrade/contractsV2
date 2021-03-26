#!/usr/bin/python3

import pytest
from brownie import reverts

from conftest import initBalance

testdata = [
    ('BUSD', 'iBUSD', 2)
]

INITIAL_LP_TOKEN_ACCOUNT_AMOUNT = 0.001 * 10 ** 18;

@pytest.mark.parametrize("tokenName, lpTokenName, pid", testdata)
def testFarming_deposit(requireBscFork, tokens, tokenName, lpTokenName, pid, accounts, masterChef, bgovToken):
    # Precondition
    lpToken = tokens[lpTokenName]
    token = tokens[tokenName]
    account1 = accounts[4]
    initBalance(account1, token, lpToken, INITIAL_LP_TOKEN_ACCOUNT_AMOUNT)

    # Deposit more than approved
    lpToken.approve(masterChef, INITIAL_LP_TOKEN_ACCOUNT_AMOUNT - 1, {'from': account1})
    with reverts("14"):
        masterChef.deposit(pid, INITIAL_LP_TOKEN_ACCOUNT_AMOUNT, {'from': account1})

    # Deposit more than balance
    lpToken.approve(masterChef, INITIAL_LP_TOKEN_ACCOUNT_AMOUNT + 1, {'from': account1})
    with reverts("16"):
        masterChef.deposit(pid, INITIAL_LP_TOKEN_ACCOUNT_AMOUNT + 1, {'from': account1})

    # Deposit more invalid pool
    with reverts("Index out of range"):
        masterChef.deposit(1000, INITIAL_LP_TOKEN_ACCOUNT_AMOUNT, {'from': account1})


@pytest.mark.parametrize("tokenName, lpTokenName, pid", testdata)
def testFarming_withdrawal(requireBscFork, tokens, tokenName, lpTokenName, pid, accounts, masterChef, bgovToken):
    lpToken = tokens[lpTokenName]
    token = tokens[tokenName]
    account1 = accounts[4]
    initBalance(account1, token, lpToken, INITIAL_LP_TOKEN_ACCOUNT_AMOUNT)
    lpBalance1 = lpToken.balanceOf(account1)
    depositAmount = lpBalance1 - 10000
    lpToken.approve(masterChef, lpBalance1, {'from': account1})
    tx1 = masterChef.deposit(pid, depositAmount, {'from': account1})
    masterChef.updatePool(pid)  # trigger calculate pending tokens
    assert masterChef.pendingBgov(pid, account1) > 0
    lpToken.approve(masterChef, INITIAL_LP_TOKEN_ACCOUNT_AMOUNT + 1, {'from': account1})

    # withdraw more than have
    with reverts("withdraw: not good"):
        masterChef.withdraw(pid, depositAmount + 1, {'from': account1})

    # withdraw invalid pool
    with reverts("invalid opcode"):
        masterChef.withdraw(1000, depositAmount, {'from': account1})


def testFarming_changedev(requireBscFork, accounts, masterChef):
    account1 = accounts[4]
    with reverts("dev: wut?"):
        masterChef.dev(account1, {'from': account1})
