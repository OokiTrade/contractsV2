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
def OOKI(accounts, TestToken, BZRXv2Token):
    return Contract.from_abi("OOKI", address="0xC5c66f91fE2e395078E0b872232A20981bc03B15", abi=BZRXv2Token.abi)


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


@pytest.fixture(scope="module")
def SLP_MIGRATOR(accounts, TestToken, SLPMigrator, BZRX_CONVERTER):
    slpmigrator = accounts[0].deploy(SLPMigrator, BZRX_CONVERTER)
    return slpmigrator


@pytest.fixture(scope="module")
def BZRX_CONVERTER(accounts, TestToken, BZRXv2Converter, OOKI):
    converter = accounts[0].deploy(BZRXv2Converter)
    converter.initialize(OOKI)
    return converter


@pytest.fixture(scope="module")
def STAKING(StakingV1_1, accounts, StakingProxy):

    bzxOwner = "0xfedC4dD5247B93feb41e899A09C44cFaBec29Cbc"
    stakingAddress = "0xe95Ebce2B02Ee07dEF5Ed6B53289801F7Fc137A4"
    proxy = Contract.from_abi("staking", address=stakingAddress, abi=StakingProxy.abi)
    impl = accounts[0].deploy(StakingV1_1)
    proxy.replaceImplementation(impl, {"from": bzxOwner})
    return Contract.from_abi("staking", address=stakingAddress, abi=StakingV1_1.abi)


def test_migration_staking(requireMainnetFork, accounts, BZRX, OOKI, STAKING, BZRX_CONVERTER, SLP_MIGRATOR, SLP, SUSHI_MASTERCHEF, SUSHI_FACTORY, WETH, interface):
    STAKING.setMigrator(SLP_MIGRATOR, {"from": STAKING.owner()})
    OOKI.transferOwnership(BZRX_CONVERTER, {'from': OOKI.owner()})

    tx = STAKING.migrateSLP({"from": STAKING.owner()})
    pair = SUSHI_FACTORY.getPair(OOKI, WETH)
    assert pair != "0x0000000000000000000000000000000000000000"
    PAIR = Contract.from_abi("PAIR", address=pair, abi=interface.IUniswapV2Pair.abi)
    assert PAIR.balanceOf(STAKING) == PAIR.totalSupply() - 1000 # 1000 minting fee

    OLDPAIR = Contract.from_abi("OLDPAIR", address="0xa30911e072A0C88D55B5D0A0984B66b0D04569d0", abi=interface.IUniswapV2Pair.abi)
    assert OLDPAIR.balanceOf(STAKING) == 0
    
    assert False
