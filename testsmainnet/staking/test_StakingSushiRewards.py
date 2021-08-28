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



def testStake_Sushi(requireMainnetFork, stakingV1_1, bzx,LPT,SUSHI, accounts, SUSHI_CHEF):
    account1 = accounts[9]
    #this accounnt has never claimed sushi yet, good to calculate proportions
    account2 = "0xd28aaacaa524f50da5c6025ca5a5e1a8cbf84647"
    LPT.approve(stakingV1_1, 2**256-1, {'from': account1})
    LPT.approve(stakingV1_1, 2**256-1, {'from': account2})

    #From first account

    lpBalanceBefore = SUSHI_CHEF.userInfo(188,stakingV1_1)[0]
    stakingV1_1.stake([LPT], [2e18], {'from': account1})
    assert lpBalanceBefore + 2e18 == SUSHI_CHEF.userInfo(188,stakingV1_1)[0]


    lpBalanceBefore = SUSHI_CHEF.userInfo(188,stakingV1_1)[0]
    stakingV1_1.claimSushi({'from': account1}) # Triggers sushi send rewards to staking
    assert lpBalanceBefore == SUSHI_CHEF.userInfo(188,stakingV1_1)[0]

    initialPendingSushi = stakingV1_1.pendingSushiRewards(account2)
    poolShare = stakingV1_1.balanceOfByAsset(LPT, account2)/stakingV1_1.totalSupplyByAsset(LPT)
    sushiShare = initialPendingSushi/SUSHI.balanceOf(stakingV1_1)

    assert (int)(poolShare*100) == (int)(sushiShare*100)
    chain.mine(1000)
    stakingV1_1.claimSushi({'from': account2})
    sushiBalance = SUSHI.balanceOf(account2)
    sushiShare = sushiBalance/SUSHI.balanceOf(stakingV1_1)
    assert (int)(poolShare*100) == (int)(sushiShare*100)
    chain.mine();
    assert initialPendingSushi > stakingV1_1.pendingSushiRewards(account2)
    assert stakingV1_1.pendingSushiRewards(account2) > 0



    chain.mine()
    assert stakingV1_1.pendingSushiRewards(account2) == stakingV1_1.earned(account2)[4]

    lpBalanceBefore = SUSHI_CHEF.userInfo(188,stakingV1_1)[0]
    stakingV1_1.unstake([LPT], [2e18], {'from': account2})
    assert lpBalanceBefore - 2e18 == SUSHI_CHEF.userInfo(188,stakingV1_1)[0]

    LPT.transfer(account1, 2e18, {'from': account2})
    pendingBefore1 = stakingV1_1.pendingSushiRewards(account1)
    stakingV1_1.stake([LPT], [2e18], {'from': account1})
    pendingBefore2 = stakingV1_1.pendingSushiRewards(account1)
    assert pendingBefore2 > pendingBefore1

    stakingV1_1.unstake([LPT], [1e18], {'from': account1})
    pendingBefore3 = stakingV1_1.pendingSushiRewards(account1)
    assert pendingBefore3 > pendingBefore2
    sushiBalanceBefore = SUSHI.balanceOf(account1)
    stakingV1_1.claim(True, {'from': account1})
    chain.mine()
    assert stakingV1_1.pendingSushiRewards(account1) < pendingBefore1
    assert SUSHI.balanceOf(account1) > sushiBalanceBefore

    stakingV1_1.claimSushi({'from': account2})
    sushiShare =SUSHI.balanceOf(account2)/SUSHI.balanceOf(stakingV1_1)
    assert (int)(poolShare*100) == (int)(sushiShare*100)

    assert True