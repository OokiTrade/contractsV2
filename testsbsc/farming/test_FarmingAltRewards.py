#!/usr/bin/python3

import pytest

from conftest import initBalance, requireFork
from brownie import chain
testdata = [
    ('BNB', 'iBNB', 0)
]

INITIAL_LP_TOKEN_ACCOUNT_AMOUNT = 10 * 10 ** 18;
GOV_POOL_PID = 7

@pytest.mark.parametrize("tokenName, lpTokenName, pid", testdata)
def testFarming_alt_reward1(requireFork, tokens, tokenName, lpTokenName, pid, accounts, masterChef, govToken):
    # Precondition
    assert False
    lpToken = tokens[lpTokenName]
    token = tokens[tokenName]
    account1 = accounts[1]
    account2 = accounts[2]
    initBalance(account1, token, lpToken, INITIAL_LP_TOKEN_ACCOUNT_AMOUNT)
    initBalance(account2, token, lpToken, INITIAL_LP_TOKEN_ACCOUNT_AMOUNT)

    masterChef.togglePause(True, {'from': masterChef.owner()})
    masterChef.togglePause(False, {'from': masterChef.owner()})

    masterChef.setLocked(pid, True, {'from': masterChef.owner()})

    for account in [account1, account2]:
        govToken.transfer(account, 1000e18, {'from': '0xf8E026dC4C0860771f691EcFFBbdfe2fa51c77CF'})
        govToken.approve(masterChef, 2**256-1, {'from': account})
        masterChef.deposit(GOV_POOL_PID, govToken.balanceOf(account), {'from': account})

    chain.mine()
    value = 10e18

    masterChefBalanceBefore = masterChef.balance()
    tx1 = masterChef.addAltReward({'from': account1, 'value': value})

    pendingAltReward = masterChef.pendingAltRewards(account1)
    balanceBefore = account1.balance()
    assert masterChef.balance() - masterChefBalanceBefore == value
    assert masterChef.balance() > masterChefBalanceBefore
    assert pendingAltReward > 10000
    assert masterChef.getOptimisedUserInfos(account1)[GOV_POOL_PID][3] == pendingAltReward

    masterChefBalanceBefore = masterChef.balance()
    tx2 = masterChef.deposit(GOV_POOL_PID, 0, {'from': account1})
    assert account1.balance() > balanceBefore
    assert masterChef.balance() < masterChefBalanceBefore

    balanceBefore = account2.balance()
    masterChefBalanceBefore = masterChef.balance()
    tx2 = masterChef.deposit(GOV_POOL_PID, 0, {'from': account2})
    assert account2.balance() > balanceBefore
    assert masterChef.balance() < masterChefBalanceBefore



@pytest.mark.parametrize("tokenName, lpTokenName, pid", testdata)
def testFarming_alt_reward2(requireFork, tokens, tokenName, lpTokenName, pid, accounts, masterChef, govToken):
    # Precondition
    lpToken = tokens[lpTokenName]
    token = tokens[tokenName]
    account1 = accounts[1]
    initBalance(account1, token, lpToken, INITIAL_LP_TOKEN_ACCOUNT_AMOUNT)
    govToken.transfer(account1, 1000e18, {'from': '0xf8E026dC4C0860771f691EcFFBbdfe2fa51c77CF'})
    govToken.approve(masterChef, 2**256-1, {'from': account1})
    masterChef.deposit(GOV_POOL_PID, govToken.balanceOf(account1), {'from': account1})
    masterChef.togglePause(True, {'from': masterChef.owner()})
    masterChef.togglePause(False, {'from': masterChef.owner()})

    masterChef.setLocked(pid, False, {'from': masterChef.owner()})
    chain.mine()

    tx1 = masterChef.addAltReward({'from': account1, 'value': 10e18})

    deposited = masterChef.getOptimisedUserInfos(account1)[GOV_POOL_PID][0];
    deposited1 = deposited * 0.2;
    deposited2 = deposited * 0.8;
    masterChef.withdraw(GOV_POOL_PID, deposited1, {'from': account1})
    masterChef.withdraw(GOV_POOL_PID, deposited2, {'from': account1})
    masterChef.getOptimisedUserInfos(account1)[GOV_POOL_PID][0]

@pytest.mark.parametrize("tokenName, lpTokenName, pid", testdata)
def testFarming_alt_reward3(requireFork, tokens, tokenName, lpTokenName, pid, accounts, masterChef, govToken):
    # Precondition
    lpToken = tokens[lpTokenName]
    token = tokens[tokenName]
    account1 = accounts[3]
    initBalance(account1, token, lpToken, INITIAL_LP_TOKEN_ACCOUNT_AMOUNT)
    govToken.transfer(account1, 1000e18, {'from': '0xf8E026dC4C0860771f691EcFFBbdfe2fa51c77CF'})
    govToken.approve(masterChef, 2**256-1, {'from': account1})
    masterChef.deposit(GOV_POOL_PID, govToken.balanceOf(account1), {'from': account1})
    masterChef.togglePause(True, {'from': masterChef.owner()})
    masterChef.togglePause(False, {'from': masterChef.owner()})

    masterChef.setLocked(pid, False, {'from': masterChef.owner()})
    masterChef.setLocked(GOV_POOL_PID, False, {'from': masterChef.owner()})

    chain.mine()
    tx1 = masterChef.addAltReward({'from': account1, 'value': 10e18})

    balanceBefore = account1.balance()
    masterChefBalanceBefore = masterChef.balance()
    masterChef.deposit(GOV_POOL_PID, 0, {'from': account1})
    assert account1.balance() > balanceBefore
    assert masterChef.balance() < masterChefBalanceBefore

    balanceBefore = account1.balance()
    masterChefBalanceBefore = masterChef.balance()
    masterChef.deposit(GOV_POOL_PID, 0, {'from': account1})
    assert account1.balance() == balanceBefore
    assert masterChef.balance() == masterChefBalanceBefore

    tx1 = masterChef.addAltReward({'from': account1, 'value': 10e18})
    chain.sleep(60 * 60 * 24)
    chain.mine()
    balanceBefore = account1.balance()
    masterChefBalanceBefore = masterChef.balance()
    masterChef.compoundReward(pid,  {'from': account1})
    masterChef.compoundReward(GOV_POOL_PID,  {'from': account1})

    deposited = masterChef.getOptimisedUserInfos(account1)[GOV_POOL_PID][0]
    masterChef.withdraw(GOV_POOL_PID, deposited, {'from': account1})
    print(balanceBefore);
    print(account1.balance());
    assert account1.balance() > balanceBefore
    assert masterChef.balance() < masterChefBalanceBefore