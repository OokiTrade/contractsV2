#!/usr/bin/python3

import pytest

def test_setCoreParams(Constants, bzx):

    bzx.setPriceFeedContract(
        Constants["ONE_ADDRESS"]
    )

    bzx.setSwapsImplContract(
        Constants["ONE_ADDRESS"]
    )

    assert bzx.priceFeeds() == Constants["ONE_ADDRESS"]
    assert bzx.swapsImpl() == Constants["ONE_ADDRESS"]

def test_setLoanPool(Constants, bzx, accounts):

    assert(bzx.loanPoolToUnderlying(accounts[6]) == Constants["ZERO_ADDRESS"])
    assert(bzx.underlyingToLoanPool(accounts[7]) == Constants["ZERO_ADDRESS"])

    assert(not bzx.isLoanPool(accounts[6]))
    assert(not bzx.isLoanPool(accounts[8]))

    bzx.setLoanPool(
        [
            accounts[6],
            accounts[8]
        ],
        [
            accounts[7],
            accounts[9]
        ]
    )

    assert(bzx.loanPoolToUnderlying(accounts[6]) == accounts[7])
    assert(bzx.underlyingToLoanPool(accounts[7]) == accounts[6])

    assert(bzx.loanPoolToUnderlying(accounts[8]) == accounts[9])
    assert(bzx.underlyingToLoanPool(accounts[9]) == accounts[8])

    assert(bzx.isLoanPool(accounts[6]))
    assert(bzx.isLoanPool(accounts[8]))

    #print(bzx.getloanPoolsList(0, 100))

    bzx.setLoanPool(
        [
            accounts[6]
        ],
        [
            Constants["ZERO_ADDRESS"]
        ]
    )

    assert(bzx.loanPoolToUnderlying(accounts[6]) == Constants["ZERO_ADDRESS"])
    assert(bzx.underlyingToLoanPool(accounts[7]) == Constants["ZERO_ADDRESS"])

    assert(not bzx.isLoanPool(accounts[6]))

    #print(bzx.getloanPoolsList(0, 100))

    #assert(False)
'''
@pytest.mark.parametrize('idx', [0, 1, 2])
def test_transferFrom_reverts(token, accounts, idx):
    with brownie.reverts("Insufficient allowance"):
        token.transferFrom(accounts[0], accounts[2], 1e18, {'from': accounts[idx]})
'''