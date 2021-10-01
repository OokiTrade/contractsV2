#!/usr/bin/python3

import pytest

from conftest import initBalance, requireFork
from brownie import chain

testdata = [
    ('MATIC', 'iMATIC', 8)
]

INITIAL_LP_TOKEN_ACCOUNT_AMOUNT = 10 * 10 ** 18;
GOV_POOL_PID = 0




@pytest.mark.parametrize("tokenName, lpTokenName, pid", testdata)
def testFarming_alt_reward1(requireFork, tokens, tokenName, lpTokenName, pid, accounts, masterChef, govToken):
    # Precondition
    lpToken = tokens[lpTokenName]
    token = tokens[tokenName]
    account1 = accounts[1]
    account2 = accounts[2]
    initBalance(account1, token, lpToken, INITIAL_LP_TOKEN_ACCOUNT_AMOUNT)
    initBalance(account2, token, lpToken, INITIAL_LP_TOKEN_ACCOUNT_AMOUNT)

    masterChef.setLocked(pid, True, {'from': masterChef.owner()})

    for account in [account1, account2]:
        lpBalance = lpToken.balanceOf(account)
        lpToken.approve(masterChef, 2**256-1, {'from': account})
        depositAmount = lpBalance/2
        govToken.approve(masterChef, 2**256-1, {'from': account})
        masterChef.deposit(pid, depositAmount, {'from': account})
        chain.sleep(60 * 60 * 24)
        chain.mine()
        masterChef.compoundReward(pid,  {'from': account})
        chain.sleep(60 * 60 * 24)
        chain.mine()
        masterChef.compoundReward(GOV_POOL_PID,  {'from': account})

    chain.mine()
    value = 10e18

    masterChefBalanceBefore = masterChef.balance()
    tx1 = masterChef.addAltReward({'from': account1, 'value': value})

    pendingAltReward = masterChef.pendingAltRewards(account1)
    balanceBefore = account1.balance()
    assert masterChef.balance() - value - masterChefBalanceBefore == 0
    assert pendingAltReward > 10000
    assert masterChef.getOptimisedUserInfos(account1)[GOV_POOL_PID][3] == pendingAltReward
    withdrawAmount1 = masterChef.getOptimisedUserInfos(account1)[GOV_POOL_PID][0];
    masterChefBalanceBefore = masterChef.balance()
    tx2 = masterChef.withdraw(GOV_POOL_PID, withdrawAmount1, {'from': account1})
    assert account1.balance() > balanceBefore
    assert masterChef.balance() < masterChefBalanceBefore

    balanceBefore = account2.balance()
    withdrawAmount2 = masterChef.getOptimisedUserInfos(account2)[GOV_POOL_PID][0];
    masterChefBalanceBefore = masterChef.balance()
    tx2 = masterChef.withdraw(GOV_POOL_PID, withdrawAmount2, {'from': account2})
    assert account2.balance() > balanceBefore
    assert masterChef.balance() < masterChefBalanceBefore



@pytest.mark.parametrize("tokenName, lpTokenName, pid", testdata)
def testFarming_alt_reward2(requireFork, tokens, tokenName, lpTokenName, pid, accounts, masterChef, govToken):
    # Precondition
    lpToken = tokens[lpTokenName]
    token = tokens[tokenName]
    account1 = accounts[1]
    initBalance(account1, token, lpToken, INITIAL_LP_TOKEN_ACCOUNT_AMOUNT)

    masterChef.setLocked(pid, False, {'from': masterChef.owner()})

    lpBalance = lpToken.balanceOf(account1)
    lpToken.approve(masterChef, 2**256-1, {'from': account1})
    depositAmount = lpBalance/2
    govToken.approve(masterChef, 2**256-1, {'from': account1})

    masterChef.deposit(pid, depositAmount, {'from': account1})
    chain.sleep(60 * 60 * 24)
    chain.mine()
    masterChef.compoundReward(pid,  {'from': account1})

    chain.sleep(60 * 60 * 24)
    chain.mine()
    masterChef.compoundReward(GOV_POOL_PID,  {'from': account1})

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
    account1 = accounts[1]
    initBalance(account1, token, lpToken, INITIAL_LP_TOKEN_ACCOUNT_AMOUNT)

    masterChef.setLocked(pid, False, {'from': masterChef.owner()})
    masterChef.setLocked(GOV_POOL_PID, True, {'from': masterChef.owner()})

    lpBalance = lpToken.balanceOf(account1)
    lpToken.approve(masterChef, 2**256-1, {'from': account1})
    depositAmount = lpBalance/2
    govToken.approve(masterChef, 2**256-1, {'from': account1})

    masterChef.deposit(pid, depositAmount, {'from': account1})
    chain.sleep(60 * 60 * 24)
    chain.mine()
    masterChef.compoundReward(pid,  {'from': account1})
    chain.sleep(60 * 60 * 24)
    chain.mine()
    masterChef.compoundReward(GOV_POOL_PID,  {'from': account1})

    chain.mine()

    tx1 = masterChef.addAltReward({'from': account1, 'value': 10e18})

    balanceBefore = account1.balance()

    masterChefBalanceBefore = masterChef.balance()
    deposited = masterChef.getOptimisedUserInfos(account1)[GOV_POOL_PID][0];
    masterChef.withdraw(GOV_POOL_PID, deposited, {'from': account1})
    print(balanceBefore);
    print(account1.balance());
    assert account1.balance() > balanceBefore
    assert masterChef.balance() < masterChefBalanceBefore

    chain.sleep(60 * 60 * 24)
    chain.mine()
    balanceBefore = account1.balance()
    masterChefBalanceBefore = masterChef.balance()
    masterChef.compoundReward(pid,  {'from': account1})
    masterChef.compoundReward(GOV_POOL_PID,  {'from': account1})
    masterChef.withdraw(GOV_POOL_PID, deposited, {'from': account1})
    print(balanceBefore);
    print(account1.balance());
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