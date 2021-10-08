#!/usr/bin/python3

import pytest
from brownie import network, Contract, Wei, chain, reverts


@pytest.fixture(scope="module")
def requireMainnetFork():
    assert (network.show_active() == "mainnet-fork" or network.show_active() == "mainnet-fork-alchemy")

@pytest.fixture(scope="module", autouse=True)
def STAKING(bzx, StakingProxy, StakingV1_1):
    
    stakingProxy = Contract.from_abi("proxy", "0xe95Ebce2B02Ee07dEF5Ed6B53289801F7Fc137A4", StakingProxy.abi)
    stakingImpl = StakingV1_1.deploy({'from': stakingProxy.owner()})
    stakingProxy.replaceImplementation(stakingImpl, {'from': stakingProxy.owner()})

    return Contract.from_abi("STAKING", stakingProxy.address, StakingV1_1.abi);

def test_staking_external_admin(requireMainnetFork, STAKING, accounts, StakingAdminSettings):

    admin = accounts[0].deploy(StakingAdminSettings)
    calldata = admin.setGovernor.encode_input(accounts[0])
    with reverts("Ownable: caller is not the owner"):
        STAKING.updateSettings(admin, calldata, {"from": accounts[0]})

    STAKING.updateSettings(admin, calldata, {"from": STAKING.owner()})
    
    assert STAKING.governor() == accounts[0]
    assert True