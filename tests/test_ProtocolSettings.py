#!/usr/bin/python3

import pytest

def test_setCoreParams(Constants, bzx):

    bzx.setCoreParams(
        Constants["ONE_ADDRESS"], # protocolTokenAddress
        Constants["ONE_ADDRESS"], # priceFeeds
        Constants["ONE_ADDRESS"], # swapsImpl
        5e18 # protocolFeePercent
    )

    assert bzx.protocolTokenAddress() == Constants["ONE_ADDRESS"]
    assert bzx.priceFeeds() == Constants["ONE_ADDRESS"]
    assert bzx.swapsImpl() == Constants["ONE_ADDRESS"]
    assert bzx.protocolFeePercent() == 5e18

def test_setProtocolManagers(Constants, bzx, accounts):

    assert(not bzx.protocolManagers(accounts[1]))
    assert(not bzx.protocolManagers(accounts[2]))

    bzx.setProtocolManagers(
        [
            accounts[1],
            accounts[2]
        ],
        [
            True,
            True
        ]
    )

    assert(bzx.protocolManagers(accounts[1]))
    assert(bzx.protocolManagers(accounts[2]))

    bzx.setProtocolManagers(
        [
            accounts[1],
            accounts[2]
        ],
        [
            False,
            False
        ]
    )

    assert(not bzx.protocolManagers(accounts[1]))
    assert(not bzx.protocolManagers(accounts[2]))

def test_setLoanPoolToUnderlying(Constants, bzx, accounts):

    assert(bzx.loanPoolToUnderlying(accounts[6]) == Constants["ZERO_ADDRESS"])
    assert(bzx.underlyingToLoanPool(accounts[7]) == Constants["ZERO_ADDRESS"])

    bzx.setLoanPoolToUnderlying(
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

    #print(bzx.getloanPoolsList(0, 100))

    bzx.setLoanPoolToUnderlying(
        [
            accounts[6]
        ],
        [
            Constants["ZERO_ADDRESS"]
        ]
    )

    assert(bzx.loanPoolToUnderlying(accounts[6]) == Constants["ZERO_ADDRESS"])
    assert(bzx.underlyingToLoanPool(accounts[7]) == Constants["ZERO_ADDRESS"])

    #print(bzx.getloanPoolsList(0, 100))

    #assert(False)
'''
@pytest.mark.parametrize('idx', [0, 1, 2])
def test_transferFrom_reverts(token, accounts, idx):
    with brownie.reverts("Insufficient allowance"):
        token.transferFrom(accounts[0], accounts[2], 1e18, {'from': accounts[idx]})
'''