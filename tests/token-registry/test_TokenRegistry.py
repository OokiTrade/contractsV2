#!/usr/bin/python3

import pytest
from brownie import Contract, network
from helpers import setupLoanPool

def test_getTokens(Constants, bzx, accounts, TokenRegistry):
    setupLoanPool(Constants, bzx, accounts[1], accounts[2])
    setupLoanPool(Constants, bzx, accounts[3], accounts[4])
    setupLoanPool(Constants, bzx, accounts[3], accounts[5])  # this will overrider asset account[4]
    trproxy = accounts[0].deploy(TokenRegistry, bzx.address)
    tr = Contract.from_abi("tr", address=trproxy.address, abi=TokenRegistry.abi, owner=accounts[0])

    print("accounts", accounts)
    print("loanPoolToUnderlying", bzx.loanPoolToUnderlying(accounts[1]))
    tokenList = tr.getTokens(0, 10)
    print(tokenList)

    assert(tokenList[0][0] == accounts[1])
    assert(tokenList[0][1] == accounts[2])

    assert(tokenList[1][0] == accounts[3])
    assert(tokenList[1][1] == accounts[5])

    assert (len(tokenList) == 2)
