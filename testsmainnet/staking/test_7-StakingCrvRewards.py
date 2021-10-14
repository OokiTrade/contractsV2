#!/usr/bin/python3

import pytest
from brownie import network, Contract, Wei, chain


@pytest.fixture(scope="module")
def requireMainnetFork():
    assert (network.show_active() == "mainnet-fork" or network.show_active() == "mainnet-fork-alchemy")



@pytest.fixture(scope="module", autouse=True)
def POOL3Gauge(bzx, interface, accounts):
    res = Contract.from_abi("POOL3Gauge", "0xbFcF63294aD7105dEa65aA58F8AE5BE2D9d0952A", interface.ICurve3PoolGauge.abi, owner=accounts[9])
    return res;

@pytest.fixture(scope="module", autouse=True)
def POOL3(TestToken):
    return Contract.from_abi("CURVE3CRV", "0x6c3F90f043a72FA612cbac8115EE7e52BDe6E490", TestToken.abi)


def testStake_Crv(requireMainnetFork, stakingV1_1, fees_extractor, accounts, SUSHI_CHEF, POOL3Gauge, POOL3, stakingAdminSettings, CRV):
    account1 = accounts[8]
    account2 = "0xd28aaacaa524f50da5c6025ca5a5e1a8cbf84647"
    #This will trigger deposit 3crv
    stakingV1_1.claimCrv({'from': account1})

    chain.mine(timedelta=7200)
    claimable = POOL3Gauge.claimable_tokens.call(stakingV1_1, {'from': stakingV1_1})
    earnedCrv = stakingV1_1.pendingCrvRewards.call(account2)
    earned3crv = stakingV1_1.earned(account2)[1]
    total = POOL3Gauge.balanceOf(stakingV1_1)
    assert int((earnedCrv/claimable)* 10000) == int((earned3crv/total) * 10000)

    balance = CRV.balanceOf(account2)
    stakingV1_1.claimCrv({'from': account2})
    crvRatio = ((CRV.balanceOf(account2) -  balance )/ earnedCrv)
    assert crvRatio >= 0.99 and crvRatio <=1.01

    assert stakingV1_1.pendingCrvRewards.call(account2) == 0
    chain.mine()

    pool3Balance = stakingV1_1.pendingCrvRewards.call(account2);
    assert pool3Balance > 0
    stakingV1_1.claim3Crv({'from': account2})
    assert stakingV1_1.pendingCrvRewards.call(account2) >= pool3Balance

    assert True