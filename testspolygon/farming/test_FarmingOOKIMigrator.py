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
    ookiBalance = 30000000e18;
    OOKI = TestToken.deploy("OOKI", "OOKI",18, ookiBalance, {'from':  owner})
    govOokiConnverter = FixedSwapTokenConverter.deploy(govToken, OOKI, 20e6, {'from':  owner})
    OOKI.transfer(govOokiConnverter, ookiBalance, {'from': owner})

    #More than approved
    BZRX.approve(govOokiConnverter, 99e18, {'from': user})
    with reverts("ERC20: transfer amount exceeds allowance"):
        govOokiConnverter.convert(govToken, 100e18, {'from': user})

    assert 0 == OOKI.balanceOf(owner)
    deadBalance = govToken.balanceOf(DEAD);
    govToken.approve(govOokiConnverter, 2**256-1, {'from': user})
    govOokiConnverter.convert(user, 100e18, {'from': user}) #100 / 20 = 5
    assert OOKI.balanceOf(user)/1e18 == 5
    assert govToken.balanceOf(govOokiConnverter) == 0
    assert (govToken.balanceOf(DEAD) - deadBalance)/1e18 == 100


    #More than have
    govOokiConnverter.convert(user, 200e18, {'from': user}) #100 / 20 = 5
    assert OOKI.balanceOf(user)/1e18 == 10
    assert govOokiConnverter.totalConverted() == 200e18


    with reverts("Ownable: caller is not the owner"):
        govOokiConnverter.rescue(user, OOKI.balanceOf(govOokiConnverter), OOKI, {'from': user})

    govOokiConnverter.rescue(user, OOKI.balanceOf(govOokiConnverter), OOKI, {'from': owner})
    assert OOKI.balanceOf(govOokiConnverter) == 0
    assert OOKI.balanceOf(owner) == 0
    assert OOKI.balanceOf(user) > 0

    with reverts("Ownable: caller is not the owner"):
        govOokiConnverter.setSwapRate(1e18, {'from': user})
    with reverts("Ownable: caller is not the owner"):
        govOokiConnverter.setTokens(BZRX, USDT, {'from': user})
    govOokiConnverter.setSwapRate(1e18, {'from': owner})
    assert govOokiConnverter.swapRate() == 1e18
    govOokiConnverter.setTokens(BZRX, USDT, {'from': owner})
    assert govOokiConnverter.tokenOut() == USDT
    assert govOokiConnverter.tokenIn() == BZRX