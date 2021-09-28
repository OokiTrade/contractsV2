#!/usr/bin/python3

import pytest

from conftest import initBalance, requireFork
from brownie import chain, reverts




def testFarming_migrate(requireFork, FixedSwapTokenMigrator, accounts, masterChef,BZRX,TestToken, USDT,BZX, govToken):
    owner = accounts[0]
    user = accounts[1]

    #get some balance
    govToken.transfer(user, 200e18, {'from': masterChef})
    BZRX.transfer(user, 200e18, {'from': BZX})
    ookiBalance = 30000000e18;
    OOKI = TestToken.deploy("OOKI", "OOKI",18, ookiBalance, {'from':  owner})
    migrator = FixedSwapTokenMigrator.deploy(OOKI, [BZRX, govToken], [10e6, 1e6/20], {'from':  owner})
    OOKI.transfer(migrator, ookiBalance, {'from': owner})
    assert 0 == OOKI.balanceOf(owner)
    govToken.approve(migrator, 2**256-1, {'from': user})
    BZRX.approve(migrator, 2**256-1, {'from': user})
    migrator.migrate(govToken, 100e18, {'from': user}) #100 / 20 = 5
    assert OOKI.balanceOf(user)/1e18 == 5
    migrator.migrate(BZRX, 100e18, {'from': user}) #100 * 10 = 10000
    assert OOKI.balanceOf(user)/1e18 == 1005

    #More than have
    with reverts("Token low balance"):
        migrator.migrate(BZRX, 101e18, {'from': user})

    #More than approved
    BZRX.approve(migrator, 99e18, {'from': user})
    with reverts("ERC20: transfer amount exceeds allowance"):
        migrator.migrate(BZRX, 100e18, {'from': user})


    with reverts("Ownable: caller is not the owner"):
        migrator.withdraw(OOKI, OOKI.balanceOf(migrator), {'from': user})

    migrator.withdraw(OOKI, OOKI.balanceOf(migrator), {'from': owner})
    assert OOKI.balanceOf(migrator) == 0
    assert OOKI.balanceOf(owner) > 0

    with reverts("Ownable: caller is not the owner"):
        migrator.setSwapRate(USDT, 1e18, {'from': user})
    with reverts("Ownable: caller is not the owner"):
        migrator.setTokenOut(USDT, {'from': user})
    migrator.setSwapRate(USDT, 1e18, {'from': owner})
    assert migrator.swapRate(USDT) == 1e18
    migrator.setTokenOut(USDT, {'from': owner})
    assert migrator.tokenOut() == USDT