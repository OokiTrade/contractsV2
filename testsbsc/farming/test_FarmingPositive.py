#!/usr/bin/python3

import pytest
from brownie import network
from conftest import BUSD, iBUSD,masterChef, requireBscFork

def testFarming_deposit(requireBscFork, BUSD,iBUSD, accounts, masterChef, bgovToken, chain):
    account1 = accounts[8]
    account2 = accounts[9]
    masterChefLPBalanceBefore = iBUSD.balanceOf(masterChef);

    #Precondition
    amount = 10000*10**18;
    depositAmount = 10*10**18
    approveAmount = 100*10**18;
    BUSD.transfer(account1, amount, {'from': "0x7c9e73d4c71dae564d41f78d56439bb4ba87592f"})
    BUSD.approve(iBUSD, approveAmount, {'from': account1})
    iBUSD.mint(account1, approveAmount, {'from': account1})
    iBUSD.approve(masterChef,iBUSD.balanceOf(account1), {'from': account1})
    ibusdBalance1 = iBUSD.balanceOf(account1)

    BUSD.transfer(account2, amount, {'from': "0x7c9e73d4c71dae564d41f78d56439bb4ba87592f"})
    BUSD.approve(iBUSD, approveAmount, {'from': account2})
    iBUSD.mint(account2, approveAmount, {'from': account2})
    iBUSD.approve(masterChef,iBUSD.balanceOf(account2), {'from': account2})
    ibusdBalance2 = iBUSD.balanceOf(account2)

    #Test procedure
    tx1 = masterChef.deposit(2,depositAmount,{'from':account1})
    assert tx1.status.name == 'Confirmed'

    #Once user deposit LP tokens, we expect that LP token balance is changed
    assert iBUSD.balanceOf(account1) == ibusdBalance1 - depositAmount
    #pendingBgovs will be 0 because we are the first who deposit LP tokens
    #and it will be changed after the second deposit/withdraw transaction (for any user)
    #bgovToken.balanceOf(account1) will be 0 and will be also changed if this user deposit again

    #The second deposit transaction for user2, this will trigger on calculation of pendingBgovs (pool.accBgovPerShare will be > 0)
    tx2 = masterChef.deposit(2,depositAmount,{'from':account2})
    masterChef.updatePool(2) #trigger calculate pending tokens
    assert masterChef.pendingBgov(2,account1) > 0
    assert tx2.status.name == 'Confirmed'
    assert iBUSD.balanceOf(account2) == ibusdBalance2 - depositAmount
    assert masterChef.pendingBgov(2,account2) > 0
    assert masterChef.poolInfo(2)[3] > 0 #accBgovPerShare > 0
    assert iBUSD.balanceOf(masterChef) > masterChefLPBalanceBefore



def testFarming_withdraw(requireBscFork, BUSD, iBUSD, accounts, masterChef, bgovToken, chain):
    account1 = accounts[8]
    bgovBalanceInitial =  bgovToken.balanceOf(account1);

    #Precondition
    amount = 10000*10**18;
    depositAmount = 10*10**18
    approveAmount = 100*10**18;
    BUSD.transfer(account1, amount, {'from': "0x7c9e73d4c71dae564d41f78d56439bb4ba87592f"})
    BUSD.approve(iBUSD, approveAmount, {'from': account1})
    iBUSD.mint(account1, approveAmount, {'from': account1})
    iBUSD.approve(masterChef,iBUSD.balanceOf(account1), {'from': account1})
    tx1 = masterChef.deposit(2,depositAmount,{'from':account1})
    masterChefLPBalanceBefore = iBUSD.balanceOf(masterChef);
    ibusdBalanceBefore1 = iBUSD.balanceOf(account1)
    masterChef.updatePool(2) #trigger calculate pending tokens
    assert masterChef.pendingBgov(2,account1) > 0
    expectedBgovBalance = bgovBalanceInitial + masterChef.pendingBgov(2,account1);

    #Test procedure
    masterChef.withdraw(2,  depositAmount, {'from': account1})
    assert bgovToken.balanceOf(account1) >= expectedBgovBalance
    assert iBUSD.balanceOf(masterChef) < masterChefLPBalanceBefore
    assert masterChef.pendingBgov(2,account1) == 0
    assert iBUSD.balanceOf(account1) == ibusdBalanceBefore1 + depositAmount


def testFarming_claim_reward(requireBscFork, BUSD, iBUSD, accounts, masterChef, bgovToken, chain):
    account1 = accounts[8]
    bgovBalanceInitial =  bgovToken.balanceOf(account1);

    #Precondition
    amount = 10000*10**18;
    depositAmount = 10*10**18
    approveAmount = 100*10**18;
    BUSD.transfer(account1, amount, {'from': "0x7c9e73d4c71dae564d41f78d56439bb4ba87592f"})
    BUSD.approve(iBUSD, approveAmount, {'from': account1})
    iBUSD.mint(account1, approveAmount, {'from': account1})
    iBUSD.approve(masterChef,iBUSD.balanceOf(account1), {'from': account1})
    tx1 = masterChef.deposit(2,depositAmount,{'from':account1})
    masterChefLPBalanceBefore = iBUSD.balanceOf(masterChef);
    ibusdBalanceBefore1 = iBUSD.balanceOf(account1)
    masterChef.updatePool(2) #trigger calculate pending tokens
    assert masterChef.pendingBgov(2,account1) > 0
    expectedBgovBalance = bgovBalanceInitial + masterChef.pendingBgov(2,account1);

    #Test procedure
    masterChef.claimReward(2, {'from': account1})
    assert bgovToken.balanceOf(account1) >= expectedBgovBalance
    assert iBUSD.balanceOf(masterChef) == masterChefLPBalanceBefore
    assert masterChef.pendingBgov(2,account1) == 0
    assert iBUSD.balanceOf(account1) == ibusdBalanceBefore1