#!/usr/bin/python3

import pytest
from brownie import network, Contract, Wei, chain


@pytest.fixture(scope="module")
def requireMainnetFork():
    assert (network.show_active() == "mainnet-fork" or network.show_active() == "mainnet-fork-alchemy")


@pytest.fixture(scope="module", autouse=True)
def stakingV1_1(bzx, StakingProxy, StakingV1_1, POOL3Gauge, accounts, POOL3, stakingAdminSettings, stakingVoteDelegator):
    # overrides config
    return 0;

def isNear(val0, val1):
    return abs(val0 - val1) <= 1

def testClaimUnvested(requireMainnetFork, StakingV1_1, bzx,  BZRX, vBZRX, iBZRX, accounts, TestToken, StakingProxy):
    # tx =
    # tx.info()
    acc = "0xE487A866b0f6b1B663b4566Ff7e998Af6116fbA9"

    CRV3 = Contract.from_abi("CRV3", "0x6c3F90f043a72FA612cbac8115EE7e52BDe6E490", TestToken.abi)
    stakingV1 = Contract.from_abi("proxy", "0xe95Ebce2B02Ee07dEF5Ed6B53289801F7Fc137A4", StakingV1_1.abi)
    bzrxBalanceBefore = BZRX.balanceOf(acc)
    crv3BalanceBefore = CRV3.balanceOf(acc)
    earnedBalanceBefore = stakingV1.earned(acc)

    stakingProxy = Contract.from_abi("proxy", "0xe95Ebce2B02Ee07dEF5Ed6B53289801F7Fc137A4", StakingProxy.abi)
    stakingImpl = StakingV1_1.deploy({'from': stakingProxy.owner()})
    stakingProxy.replaceImplementation(stakingImpl, {'from': stakingProxy.owner()})
    stakingV1_1 = Contract.from_abi("StakingV1_1", stakingProxy.address, StakingV1_1.abi, owner=accounts[9])


    earnedBalanceAfter = stakingV1_1.earned(acc)
    stakingV1_1.exit({"from": acc})

    print(earnedBalanceBefore)
    print(earnedBalanceAfter)

    bzrxBalanceAfter = BZRX.balanceOf(acc)
    crv3BalanceAfter = CRV3.balanceOf(acc)
    assert stakingV1_1.earned(acc) == (0, 0, 0, 0, 0)

    # we check that transfer amount match the earn amount displayed
    assert isNear(earnedBalanceAfter[0], bzrxBalanceAfter - bzrxBalanceBefore)
    assert isNear(earnedBalanceAfter[1], crv3BalanceAfter - crv3BalanceBefore)

    # we check that new amounts are the result of previous claimable + vesting
    assert isNear(earnedBalanceAfter[0], earnedBalanceBefore[0] + earnedBalanceBefore[2]) # for BZRX
    assert isNear(earnedBalanceAfter[1], earnedBalanceBefore[1] + earnedBalanceBefore[3]) # for CRV3
    
    #assert False
