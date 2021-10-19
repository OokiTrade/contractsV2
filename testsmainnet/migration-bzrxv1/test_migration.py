#!/usr/bin/python3

import pytest
from brownie import network, Contract, Wei, chain, reverts


@pytest.fixture(scope="module")
def requireMainnetFork():
    assert (network.show_active() == "mainnet-fork" or network.show_active() == "mainnet-fork-alchemy")


@pytest.fixture(scope="module")
def BZRX(accounts, TestToken):
    
    bzrx = Contract.from_abi("BZRX", address="0x56d811088235F11C8920698a204A5010a788f4b3", abi=TestToken.abi)
    bzrx.transfer(accounts[0], 1000*10**18, {'from': bzrx.address})
    
    return bzrx

@pytest.fixture(scope="module")
def OOKI(accounts, OokiToken):
    return Contract.from_abi("OOKI", address="0x0De05F6447ab4D22c8827449EE4bA2D5C288379B", abi=OokiToken.abi)

@pytest.fixture(scope="module")
def MIGRATOR(accounts, BZRXv2Converter, MINT_COORDINATOR):
    MIGRATOR = accounts[9].deploy(BZRXv2Converter)
    MIGRATOR.initialize(MINT_COORDINATOR)
    MINT_COORDINATOR.addMinter(MIGRATOR)
    return MIGRATOR

@pytest.fixture(scope="module")
def MINT_COORDINATOR(accounts, MintCoordinator, OOKI):
    mint_coordinator = accounts[9].deploy(MintCoordinator)
    OOKI.transferOwnership(mint_coordinator, {"from": OOKI.owner()})
    return mint_coordinator

def test_migration_BZRX(requireMainnetFork, BZRX, OOKI, MIGRATOR, accounts, MINT_COORDINATOR):
    balanceBZRXv1 = BZRX.balanceOf(accounts[0])
    assert balanceBZRXv1 > 0

    convertBalanceBZRXv1 = 10*10**18
    BZRX.approve(MIGRATOR, 2**256-1, {'from': accounts[0]})
    MIGRATOR.convert(accounts[0], convertBalanceBZRXv1, {'from': accounts[0]})

    balanceBZRXv2 = OOKI.balanceOf(accounts[0])
    balanceBZRXv1after = BZRX.balanceOf(accounts[0])

    assert convertBalanceBZRXv1 * 10 == balanceBZRXv2
    assert balanceBZRXv1after + convertBalanceBZRXv1 == balanceBZRXv1

    assert True

def test_migration_BZRX_different_receiver(requireMainnetFork, BZRX, OOKI, MIGRATOR, accounts):
    balanceBZRXv1 = BZRX.balanceOf(accounts[0])
    assert balanceBZRXv1 > 0

    convertBalanceBZRXv1 = 10*10**18
    BZRX.approve(MIGRATOR, 2**256-1, {'from': accounts[0]})
    MIGRATOR.convert(accounts[1], convertBalanceBZRXv1, {'from': accounts[0]})

    balanceBZRXv2 = OOKI.balanceOf(accounts[0])
    balanceBZRXv1after = BZRX.balanceOf(accounts[0])

    assert convertBalanceBZRXv1 * 10== balanceBZRXv2
    assert balanceBZRXv1after + convertBalanceBZRXv1 == balanceBZRXv1

    assert True

def test_migration_minter_burners(requireMainnetFork, BZRX, OOKI, MIGRATOR, accounts, MINT_COORDINATOR):
    balanceBZRXv1 = BZRX.balanceOf(accounts[0])
    assert balanceBZRXv1 > 0

    convertBalanceBZRXv1 = 10*10**18
    BZRX.approve(MIGRATOR, 2**256-1, {'from': accounts[0]})
 
    MIGRATOR.convert(accounts[1], convertBalanceBZRXv1, {'from': accounts[0]})


    OOKI.approve(MINT_COORDINATOR, 2**256-1, {'from': accounts[1]})

    balanceOOKIBefore = OOKI.balanceOf(accounts[1])

    balanceOOKIAfter = OOKI.balanceOf(accounts[1])

    assert balanceOOKIAfter == balanceOOKIBefore


    assert True