#!/usr/bin/python3

import pytest
from brownie import network, Contract, Wei, chain, reverts


@pytest.fixture(scope="module")
def requireMainnetFork():
    assert (network.show_active() == "mainnet-fork" or network.show_active() == "mainnet-fork-alchemy")


@pytest.fixture(scope="module")
def BZRX(accounts, TestToken):
    return Contract.from_abi("BZRX", address="0x56d811088235F11C8920698a204A5010a788f4b3", abi=TestToken.abi)


@pytest.fixture(scope="module")
def OOKI(accounts, TestToken, OokiToken):
    return Contract.from_abi("OOKI", address="0x0De05F6447ab4D22c8827449EE4bA2D5C288379B", abi=OokiToken.abi)


@pytest.fixture(scope="module")
def WETH(accounts, TestToken):
    return Contract.from_abi("WETH", address="0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2", abi=TestToken.abi)


@pytest.fixture(scope="module")
def SLP(accounts, TestToken):
    return Contract.from_abi("SLP", address="0xa30911e072A0C88D55B5D0A0984B66b0D04569d0", abi=TestToken.abi)


@pytest.fixture(scope="module")
def SUSHI_MASTERCHEF(accounts, TestToken, interface):
    return Contract.from_abi("SUSHI_MASTERCHEF", address="0xc2EdaD668740f1aA35E4D8f227fB8E17dcA888Cd", abi=interface.IMasterChefSushi.abi)


@pytest.fixture(scope="module")
def SUSHI_FACTORY(accounts, TestToken, interface):
    return Contract.from_abi("SUSHI_FACTORY", address="0xC0AEe478e3658e2610c5F7A4A2E1777cE9e4f2Ac", abi=interface.IUniswapV2Factory.abi)


@pytest.fixture(scope="module")
def ADMIN_SETTINGS(StakingAdminSettings, accounts):
    admin = accounts[0].deploy(StakingAdminSettings)
    return admin


@pytest.fixture(scope="function", autouse=True)
def isolate(fn_isolation):
    pass


def test_migration_staking_balances(requireMainnetFork, accounts, BZRX, OOKI, SLP, SUSHI_MASTERCHEF, WETH, interface, ADMIN_SETTINGS, TestToken, StakingV1_1, StakingProxy, BZRXv2Converter):

    bzxOwner = "0xfedC4dD5247B93feb41e899A09C44cFaBec29Cbc"
    stakingAddress = "0xe95Ebce2B02Ee07dEF5Ed6B53289801F7Fc137A4"
    # STAKING = Contract.from_abi("staking", address=stakingAddress, abi=interface.IStaking.abi)
    STAKING = Contract.from_explorer(stakingAddress) # this is loading from etherscan so it uses original unmodified contract interfaces. specifically `earned` function was changed

    #  record before values
    account = "0xE487A866b0f6b1B663b4566Ff7e998Af6116fbA9"
    balanceOfByAssets = STAKING.balanceOfByAssets(account)
    balanceOfStored = STAKING.balanceOfStored(account)
    votingBalanceOfNow = STAKING.votingBalanceOfNow(account)
    earned = STAKING.earned.call(account, {"from": account})
    balanceOfBZRXBefore = BZRX.balanceOf(STAKING)

    # replace contract
    proxy = Contract.from_abi("staking", address=stakingAddress, abi=StakingProxy.abi)
    impl = accounts[0].deploy(StakingV1_1)
    proxy.replaceImplementation(impl, {"from": bzxOwner})
    STAKING = Contract.from_abi("staking", address=stakingAddress, abi=StakingV1_1.abi) # loading upgraded interface

    converter = accounts[0].deploy(BZRXv2Converter)
    converter.initialize(OOKI)

    calldata = ADMIN_SETTINGS.setConverter.encode_input(converter)
    STAKING.updateSettings(ADMIN_SETTINGS, calldata, {"from": STAKING.owner()})

    OOKI.transferOwnership(converter, {'from': OOKI.owner()})
    
    calldata = ADMIN_SETTINGS.migrateSLP.encode_input()
    tx = STAKING.updateSettings(ADMIN_SETTINGS, calldata, {"from": STAKING.owner()})

    assert STAKING.isUserMigrated(account) == False
    STAKING.migrateUserBalances({"from": account})
    assert STAKING.isUserMigrated(account) == True

    # checking after migration state remins the same

    assert balanceOfByAssets == STAKING.balanceOfByAssets(account)
    assert balanceOfStored == STAKING.balanceOfStored(account)
    # assert votingBalanceOfNow == STAKING.votingBalanceOfNow(account) voting change due to lp total supply change

    assert balanceOfBZRXBefore == OOKI.balanceOf(STAKING)
    # assert earned == STAKING.earned.call(account) # all balances mismatche because time change, lp change

    # STAKING.claimAltRewards() TODO this does not work yet because sushi lp not in masterchief. pendign request to sushi team

    
    assert True
