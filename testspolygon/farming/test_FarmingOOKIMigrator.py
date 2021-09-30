#!/usr/bin/python3

import pytest

from conftest import initBalance, requireFork
from brownie import chain, reverts




def testFarming_migrate(requireFork, FixedSwapTokenConverter, accounts, masterChef,BZRX,TestToken, USDT,BZX, govToken):
    owner = accounts[0]
    user = accounts[1]
    DEAD = '0x000000000000000000000000000000000000dEaD'
    #get some balance
    govToken.transfer(user, 200e18, {'from': masterChef})
    BZRX.transfer(user, 200e18, {'from': BZX})
    ookiBalance = 30000000e18;
    OOKI = TestToken.deploy("OOKI", "OOKI",18, ookiBalance, {'from':  owner})
    govOokiConnverter = FixedSwapTokenConverter.deploy(
        [govToken, BZRX],
        [1e6/2, 10e6], #20 gov == 1 bzrx == 10 ooki, 1 bzrx = 10 ooki
        OOKI,
        {'from':  owner}
    )


    OOKI.transfer(govOokiConnverter, ookiBalance, {'from': owner})

    #More than approved
    govToken.approve(govOokiConnverter, 99e18, {'from': user})
    with reverts("ERC20: transfer amount exceeds allowance"):
        govOokiConnverter.convert(govToken, user, 100e18, {'from': user})

    assert 0 == OOKI.balanceOf(owner)
    deadBalance = govToken.balanceOf(DEAD);
    govToken.approve(govOokiConnverter, 2**256-1, {'from': user})
    BZRX.approve(govOokiConnverter, 2**256-1, {'from': user})

    govOokiConnverter.convert(govToken, user, 2e18, {'from': user})
    expectedBalance = 1
    assert OOKI.balanceOf(user)/1e18 == expectedBalance
    assert govToken.balanceOf(govOokiConnverter) == 0
    govOokiConnverter.convert(BZRX, user, 100e18, {'from': user}) #100 / 20 = 5
    expectedBalance = expectedBalance + 100 * 10;
    assert OOKI.balanceOf(user)/1e18 == expectedBalance


    #More than have
    govOokiConnverter.convert(govToken, user, 200e18, {'from': user}) #100 / 20 = 5
    assert OOKI.balanceOf(user)/1e18 == 100 * 10 + 200/2
    assert govOokiConnverter.totalConverted(govToken) == 200e18


    with reverts("Ownable: caller is not the owner"):
        govOokiConnverter.rescue(user, OOKI.balanceOf(govOokiConnverter), OOKI, {'from': user})

    govOokiConnverter.rescue(user, OOKI.balanceOf(govOokiConnverter), OOKI, {'from': owner})
    assert OOKI.balanceOf(govOokiConnverter) == 0
    assert OOKI.balanceOf(owner) == 0
    assert OOKI.balanceOf(user) > 0

    with reverts("Ownable: caller is not the owner"):
        govOokiConnverter.setTokenIn(USDT, 100e18, {'from': user})
    govOokiConnverter.setTokenIn(USDT, 100e18, {'from': owner})
    assert govOokiConnverter.tokenIn(USDT) == 100e18
    govOokiConnverter.setTokenOut(BZRX, {'from': owner})
    assert govOokiConnverter.tokenOut() == BZRX