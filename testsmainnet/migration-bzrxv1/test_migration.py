#!/usr/bin/python3

import pytest
from brownie import network, Contract, Wei, chain


@pytest.fixture(scope="module")
def requireMainnetFork():
    assert (network.show_active() == "mainnet-fork" or network.show_active() == "mainnet-fork-alchemy")


@pytest.fixture(scope="module")
def BZRXv1(accounts, TestToken):
    BZRX = loadContractFromAbi(
        "0x56d811088235F11C8920698a204A5010a788f4b3", "BZRX", TestToken.abi)
    BZRX.transfer(accounts[0], 1000*10**18, {'from': BZRX.address})
    return BZRX

@pytest.fixture(scope="module")
def vBZRXv1(accounts, TestToken):
    vBZRX = loadContractFromAbi(
        "0xB72B31907C1C95F3650b64b2469e08EdACeE5e8F", "vBZRX", TestToken.abi)
    vBZRX.transfer(accounts[0], 1000*10**18, {'from': vBZRX.address})
    return vBZRX


@pytest.fixture(scope="module")
def BZRXv2(accounts, BZRXv2Token):
    BZRXv2 = accounts[9].deploy(BZRXv2Token);
    return BZRXv2

@pytest.fixture(scope="module")
def MIGRATOR(accounts, BZRXv2Converter, BZRXv2, vBZRXv2):
    MIGRATOR = accounts[9].deploy(BZRXv2Converter);
    BZRXv2.mint(MIGRATOR, 1000*10**18)
    MIGRATOR.initialize(BZRXv2, vBZRXv2)
    return MIGRATOR

@pytest.fixture(scope="module")
def vBZRXv2(accounts, VBZRXv2VestingToken):     
    return accounts[9].deploy(VBZRXv2VestingToken)

def loadContractFromAbi(address, alias, abi):
    try:
        return Contract(alias)
    except ValueError:
        contract = Contract.from_abi(alias, address=address, abi=abi)
        return contract



def test_migration_BZRX(requireMainnetFork, BZRXv1, vBZRXv1, BZRXv2, vBZRXv2, MIGRATOR, accounts):
    balanceBZRXv1 = BZRXv1.balanceOf(accounts[0])
    assert balanceBZRXv1 > 0

    convertBalanceBZRXv1 = 10*10**18
    BZRXv1.approve(MIGRATOR, 2**256-1, {'from': accounts[0]})
    MIGRATOR.convert(convertBalanceBZRXv1, {'from': accounts[0]})

    balanceBZRXv2 = BZRXv2.balanceOf(accounts[0])
    balanceBZRXv1after = BZRXv1.balanceOf(accounts[0])

    assert convertBalanceBZRXv1 == balanceBZRXv2
    assert balanceBZRXv1after + convertBalanceBZRXv1 == balanceBZRXv1

    assert True

def test_migration_vBZRX(requireMainnetFork, BZRXv1, vBZRXv1, BZRXv2, vBZRXv2, MIGRATOR, accounts):
    balancevBZRXv1 = vBZRXv1.balanceOf(accounts[0])
    assert balancevBZRXv1 > 0

    convertBalancevBZRXv1 = 10*10**18
    vBZRXv1.approve(MIGRATOR, 2**256-1, {'from': accounts[0]})
    vBZRXv1.approve(vBZRXv2, 2**256-1, {'from': accounts[0]})
    MIGRATOR.convertvBZRX(convertBalancevBZRXv1, {'from': accounts[0]})

    balancevBZRXv2 = vBZRXv2.balanceOf(accounts[0])
    balancevBZRXv1after = vBZRXv1.balanceOf(accounts[0])

    assert convertBalancevBZRXv1 == balancevBZRXv2
    assert balancevBZRXv1after + convertBalancevBZRXv1 == balancevBZRXv1

    assert True