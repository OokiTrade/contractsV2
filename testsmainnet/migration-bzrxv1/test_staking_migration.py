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
    return Contract.from_abi("OOKI", address="0xC5c66f91fE2e395078E0b872232A20981bc03B15", abi=OokiToken.abi)


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

# @pytest.fixture(scope="module")
# def SUSHI_FACTORY(accounts, TestToken, interface):
#     return Contract.from_abi("SUSHI_FACTORY", address="0xC0AEe478e3658e2610c5F7A4A2E1777cE9e4f2Ac", abi=interface.IUniswapV2Factory.abi)


# @pytest.fixture(scope="module")
# def SLP_MIGRATOR(accounts, TestToken, SLPMigrator, BZRX_CONVERTER):
#     slpmigrator = accounts[0].deploy(SLPMigrator, BZRX_CONVERTER)
#     return slpmigrator


@pytest.fixture(scope="module")
def BZRX_CONVERTER(accounts, BZRXv2Converter, OOKI, ADMIN_SETTINGS, STAKING):
    converter = accounts[0].deploy(BZRXv2Converter)
    converter.initialize(OOKI)

    calldata = ADMIN_SETTINGS.setConverter.encode_input(converter)
    STAKING.updateSettings(ADMIN_SETTINGS, calldata, {"from": STAKING.owner()})

    OOKI.transferOwnership(converter, {'from': OOKI.owner()})
    return converter


@pytest.fixture(scope="module")
def STAKING(StakingV1_1, accounts, StakingProxy, interface, TestToken):

    bzxOwner = "0xfedC4dD5247B93feb41e899A09C44cFaBec29Cbc"
    stakingAddress = "0xe95Ebce2B02Ee07dEF5Ed6B53289801F7Fc137A4"
    proxy = Contract.from_abi("staking", address=stakingAddress, abi=StakingProxy.abi)
    impl = accounts[0].deploy(StakingV1_1)
    proxy.replaceImplementation(impl, {"from": bzxOwner})

    # # buypass stake crv zero bag TODO Eugen
    # POOL3 = Contract.from_abi("CURVE3CRV", "0x6c3F90f043a72FA612cbac8115EE7e52BDe6E490", TestToken.abi)
    # POOL3Gauge = Contract.from_abi("3POOLGauge", "0xbFcF63294aD7105dEa65aA58F8AE5BE2D9d0952A", interface.ICurve3PoolGauge.abi)
    # POOL3.approve(POOL3Gauge, 2**256-1, {'from': stakingAddress})
    # POOL3Gauge.deposit(POOL3.balanceOf(stakingAddress),{'from': stakingAddress})

    return Contract.from_abi("staking", address=stakingAddress, abi=StakingV1_1.abi)

@pytest.fixture(scope="module")
def ADMIN_SETTINGS(StakingAdminSettings, accounts):
    admin = accounts[0].deploy(StakingAdminSettings)
    return admin

@pytest.fixture(scope="function", autouse=True)
def isolate(fn_isolation):
    pass


# def test_migration_staking(requireMainnetFork, accounts, BZRX, OOKI, STAKING, BZRX_CONVERTER, SLP, SUSHI_MASTERCHEF, SUSHI_FACTORY, WETH, interface, ADMIN_SETTINGS):

#     balanceOfBZRXBefore = BZRX.balanceOf(STAKING)
#     calldata = ADMIN_SETTINGS.migrateSLP.encode_input()
#     tx = STAKING.updateSettings(ADMIN_SETTINGS, calldata, {"from": STAKING.owner()})

#     assert OOKI.balanceOf(STAKING) == balanceOfBZRXBefore
#     assert BZRX.balanceOf(STAKING) == 0 # all bzrx was migrated
#     assert SLP.balanceOf(STAKING) == 0 # all slp was migrated

#     pair = SUSHI_FACTORY.getPair(OOKI, WETH)
#     assert pair != "0x0000000000000000000000000000000000000000"
#     PAIR = Contract.from_abi("PAIR", address=pair, abi=interface.IUniswapV2Pair.abi)
#     assert PAIR.balanceOf(STAKING) == PAIR.totalSupply() - 1000 # 1000 minting fee

#     OLDPAIR = Contract.from_abi("OLDPAIR", address="0xa30911e072A0C88D55B5D0A0984B66b0D04569d0", abi=interface.IUniswapV2Pair.abi)
#     assert OLDPAIR.balanceOf(STAKING) == 0
    
#     assert True


def test_migration_staking_balances(requireMainnetFork, BZRX, OOKI, STAKING, SLP, ADMIN_SETTINGS):
    account = "0xE487A866b0f6b1B663b4566Ff7e998Af6116fbA9"
 

    balanceOfBZRXBefore = BZRX.balanceOf(STAKING)
    calldata = ADMIN_SETTINGS.migrateSLP.encode_input()
    tx = STAKING.updateSettings(ADMIN_SETTINGS, calldata, {"from": STAKING.owner()})



    assert STAKING.isUserMigrated(account) == False
    STAKING.migrateUserBalances({"from": account})
    assert STAKING.isUserMigrated(account) == True
 
 
    assert balanceOfBZRXBefore == OOKI.balanceOf(STAKING)
 

    assert False