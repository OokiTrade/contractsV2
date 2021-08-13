#!/usr/bin/python3

import pytest
from brownie import network, Contract, Wei, chain


@pytest.fixture(scope="module")
def requireMainnetFork():
    assert (network.show_active() == "mainnet-fork" or network.show_active() == "mainnet-fork-alchemy")


def loadContractFromAbi(address, alias, abi):
    try:
        return Contract(alias)
    except ValueError:
        contract = Contract.from_abi(alias, address=address, abi=abi)
        return contract


# TODO add LPToken
def testStake_UnStake(requireMainnetFork, stakingV1_1, bzx,LPT,SUSHI, setFeesController, BZRX, vBZRX, iBZRX, accounts):
    account1 = accounts[9]
    account2 = "0xd28aaacaa524f50da5c6025ca5a5e1a8cbf84647"
    stakingV1_1.pendingSushiRewards(accounts[9])
    user2pending = stakingV1_1.pendingSushiRewards(account2)
    assert user2pending > 0
    stakingV1_1.unstake([LPT], [1],True, {'from': account2})
    assert stakingV1_1.pendingSushiRewards(account2) == 0
    assert SUSHI.balanceOf(account2) > user2pending
    assert stakingV1_1.pendingSushiRewards(account1) > 0

    stakingV1_1.unstake([LPT], [1],False, {'from': account1})
    assert stakingV1_1.pendingSushiRewards(account1) > 0
    stakingV1_1.unstake([LPT], [1],True, {'from': account1})
    assert stakingV1_1.pendingSushiRewards(account1) == 0
    stakingV1_1.unstake([LPT], [1],False, {'from': account1})
    assert stakingV1_1.pendingSushiRewards(account1) > 0

    assert True