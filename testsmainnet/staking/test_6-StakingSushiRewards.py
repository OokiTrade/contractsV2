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
    account2 = "0xd28aaacaa524f50da5c6025ca5a5e1a8cbf84647"

    account3 = accounts[8]

    stakingV1_1.unstake([LPT], [stakingV1_1.balanceOfByAsset(LPT, account2)], {'from': account2})
    LPT.transfer(account3, LPT.balanceOf(account2), {'from': account2})

    LPT.approve(stakingV1_1, 2**256-1, {'from': account1})
    LPT.approve(stakingV1_1, 2**256-1, {'from': account3})

    #From first account

    lpBalanceBefore = SUSHI_CHEF.userInfo(188,stakingV1_1)[0]

    stakingV1_1.stake([LPT], [2e18], {'from': account1})
    assert lpBalanceBefore + 2e18 == SUSHI_CHEF.userInfo(188,stakingV1_1)[0]

    lpBalanceBefore = SUSHI_CHEF.userInfo(188,stakingV1_1)[0]
    stakingV1_1.claimSushi({'from': account1}) # Triggers sushi send rewards to staking
    assert lpBalanceBefore == SUSHI_CHEF.userInfo(188,stakingV1_1)[0]

    stakingV1_1.stake([LPT], [LPT.balanceOf(account3)], {'from': account3})
    chain.mine(1000)
    initialPendingSushi = stakingV1_1.earned(account3)[4]
    poolShare = stakingV1_1.balanceOfByAsset(LPT, account3)/stakingV1_1.totalSupplyByAsset(LPT)
    sushiShare =  initialPendingSushi/SUSHI_CHEF.pendingSushi(188,stakingV1_1)

    assert (int)(poolShare*100) == (int)(sushiShare * 100)
    sushiBalanceStaking = SUSHI.balanceOf(stakingV1_1)
    sushiBalance1 = SUSHI.balanceOf(account3)
    stakingV1_1.claimSushi({'from': account3})
    sushiBalance = SUSHI.balanceOf(account3) - sushiBalance1
    assert (initialPendingSushi/sushiBalance) > 0.99
    chain.mine(100);
    assert initialPendingSushi > stakingV1_1.earned(account3)[4]
    assert stakingV1_1.earned(account3)[4] > 0



    chain.mine()
    assert stakingV1_1.earned(account3)[4] == stakingV1_1.earned.call(account3)[4]

    lpBalanceBefore = SUSHI_CHEF.userInfo(188,stakingV1_1)[0]
    stakingV1_1.unstake([LPT], [2e18], {'from': account3})
    assert lpBalanceBefore - 2e18 == SUSHI_CHEF.userInfo(188,stakingV1_1)[0]

    LPT.transfer(account1, 2e18, {'from': account3})
    pendingBefore1 = stakingV1_1.earned(account1)[4]
    stakingV1_1.stake([LPT], [2e18], {'from': account1})
    pendingBefore2 = stakingV1_1.earned(account1)[4]
    assert pendingBefore2 > pendingBefore1

    stakingV1_1.unstake([LPT], [1e18], {'from': account1})
    pendingBefore3 = stakingV1_1.earned(account1)[4]
    assert pendingBefore3 > pendingBefore2
    sushiBalanceBefore = SUSHI.balanceOf(account1)
    stakingV1_1.claimAltRewards({'from': account1})
    assert SUSHI.balanceOf(account1) > sushiBalanceBefore

    chain.mine(1000)
    pendingBefore1 = stakingV1_1.earned(account3)[4]
    sushiBalanceBefore1 = SUSHI.balanceOf(account3);
    sushiBalanceBefore2 = SUSHI.balanceOf(stakingV1_1);
    stakingV1_1.claimSushi({'from': account3})
    assert pendingBefore1/(SUSHI.balanceOf(account3) - sushiBalanceBefore1) > 0.99

    assert True