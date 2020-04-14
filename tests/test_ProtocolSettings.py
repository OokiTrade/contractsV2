#!/usr/bin/python3

import pytest

#from brownie import Wei, reverts

def test_setCoreParams(Constants, bzx, settings):

    settings.setCoreParams(
        Constants["ONE_ADDRESS"], # protocolTokenAddress
        Constants["ONE_ADDRESS"], # feedsController
        Constants["ONE_ADDRESS"], # feedsController
    )

    assert bzx.protocolTokenAddress() == Constants["ONE_ADDRESS"]
    assert bzx.feedsController() == Constants["ONE_ADDRESS"]
    assert bzx.feedsController() == Constants["ONE_ADDRESS"]

def test_setProtocolManagers(Constants, settings, accounts):

    assert(not settings.protocolManagers(accounts[1]))
    assert(not settings.protocolManagers(accounts[2]))

    settings.setProtocolManagers(
        [
            accounts[1],
            accounts[2]
        ],
        [
            True,
            True
        ]
    )

    assert(settings.protocolManagers(accounts[1]))
    assert(settings.protocolManagers(accounts[2]))

    settings.setProtocolManagers(
        [
            accounts[1],
            accounts[2]
        ],
        [
            False,
            False
        ]
    )

    assert(not settings.protocolManagers(accounts[1]))
    assert(not settings.protocolManagers(accounts[2]))

'''
@pytest.mark.parametrize('idx', [0, 1, 2])
def test_transferFrom_reverts(token, accounts, idx):
    with brownie.reverts("Insufficient allowance"):
        token.transferFrom(accounts[0], accounts[2], 1e18, {'from': accounts[idx]})
'''