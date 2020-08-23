#!/usr/bin/python3

import pytest
from brownie import Wei, reverts


def test_getBorrowAmount(Constants, bzx, accounts, DAI, LINK):

    amount = bzx.getBorrowAmount(DAI, LINK, 1, 100, True)
    print("amount", amount)
    assert(amount == 9)

    amount = bzx.getBorrowAmount(DAI, LINK, 1, 100, False)
    print("amount", amount)
    assert(amount == 10000000000000000000)

    amount = bzx.getBorrowAmount(DAI, DAI, 1, 100, False)
    print("amount", amount)
    assert(amount == 1000000000000000000)
