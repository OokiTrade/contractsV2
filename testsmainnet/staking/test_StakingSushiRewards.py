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



def testStake_Sushi(requireMainnetFork, stakingV1_1, bzx,LPT,SUSHI, accounts):
    account1 = accounts[9]
    account2 = "0xd28aaacaa524f50da5c6025ca5a5e1a8cbf84647"
    LPT.approve(stakingV1_1, 2**256-1, {'from': account1})
    LPT.approve(stakingV1_1, 2**256-1, {'from': account2})

    stakingV1_1.stake([LPT], [2e18],True, {'from': account1})

    poolShare = stakingV1_1.balanceOfByAsset(LPT, account2)/stakingV1_1.totalSupplyByAsset(LPT)
    sushiShare = stakingV1_1.pendingSushiRewards(account2)/SUSHI.balanceOf(stakingV1_1)
    assert (int)(poolShare*100) == (int)(sushiShare*100)

    stakingV1_1.unstake([LPT], [2e18],True, {'from': account2})

    assert stakingV1_1.pendingSushiRewards(account1) > 0


    LPT.transfer(account1, 2e18, {'from': account2})
    stakingV1_1.stake([LPT], [2e18],False, {'from': account1})
    stakingV1_1.unstake([LPT], [2e18],True, {'from': account1})
    assert  SUSHI.balanceOf(account1) > 0
    assert True