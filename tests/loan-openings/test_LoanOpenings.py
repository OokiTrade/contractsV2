#!/usr/bin/python3

import pytest
from brownie import Wei, reverts


def test_getBorrowAmount(Constants, bzx, accounts, DAI, LINK):

    margin = 20**18
    borrowAmount = 10**20

    amount = bzx.getBorrowAmount(DAI, LINK, borrowAmount, margin, True)
    print("amount", amount)
    assert(amount == 380981071063589633)
