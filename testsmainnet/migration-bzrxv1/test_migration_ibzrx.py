#!/usr/bin/python3

import pytest
from brownie import network, Contract, Wei, chain, reverts
from brownie import *
import time


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
    return Contract.from_abi("OOKI", address="0xC5c66f91fE2e395078E0b872232A20981bc03B15", abi=OokiToken.abi)


@pytest.fixture(scope="module")
def iBZRX(LoanTokenLogicStandard, accounts, LoanToken):
    # # upgrade
    # timelock = "0xfedC4dD5247B93feb41e899A09C44cFaBec29Cbc"
    # loanTokenLogicStandard = accounts[0].deploy(LoanTokenLogicStandard, timelock)
    # loanTokenProxy = Contract.from_abi(name="loanTokenProxy", address="0x32E4c68B3A4a813b710595AebA7f6B7604Ab9c15", abi=LoanToken.abi)
    # loanTokenProxy.setTarget(loanTokenLogicStandard, {'from': timelock})

    return Contract.from_abi("iBZRX", address="0x18240BD9C07fA6156Ce3F3f61921cC82b2619157", abi=LoanTokenLogicStandard.abi)


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


@pytest.fixture(scope="class")
def BZX(accounts, interface):
    return Contract.from_abi("bzx", address="0xD8Ee69652E4e4838f2531732a46d1f7F584F0b7f", abi=interface.IBZx.abi)


@pytest.fixture(scope="module")
def USDC(accounts, TestToken):
    return Contract.from_abi("bzx", address="0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48", abi=TestToken.abi)


@pytest.fixture(scope="module")
def iUSDC(accounts, LoanTokenLogicStandard):
    return Contract.from_abi("iUSDC", address="0x32E4c68B3A4a813b710595AebA7f6B7604Ab9c15", abi=LoanTokenLogicStandard.abi)


def test_migration_ibzrx(requireMainnetFork, BZRX, OOKI, MIGRATOR, accounts, MINT_COORDINATOR, iBZRX, LoanTokenMigration, BZX, USDC, iUSDC, LoanTokenLogicStandard):
    loanTokenMigration = accounts[0].deploy(LoanTokenMigration)

    # record balance before
    balanceOfBZRX = BZRX.balanceOf(iBZRX)

    calldata = loanTokenMigration.migrate.encode_input(MIGRATOR)
    iBZRX.updateSettings(loanTokenMigration, calldata, {"from": iBZRX.owner()})

    balanceOfOOKI = OOKI.balanceOf(iBZRX)
    assert balanceOfBZRX == balanceOfOOKI
    assert iBZRX.loanTokenAddress() == OOKI
    assert True
    
    # # TODO migrate loan params, this will be in the governance proposal
    # poolList = BZX.getLoanPoolsList(0, 20)
    # hashBorrow = web3.soliditySha3(["address", "bool"], [BZRX.address, True])
    # hashTrade = web3.soliditySha3(["address", "bool"], [BZRX.address, False])
    # for pool in poolList:
    #     if pool == iBZRX or pool == "0xaB45Bf58c6482b87DA85D6688C4d9640E093BE98": # LEND
    #         continue
    #     iToken = Contract.from_abi("iToken", address=pool, abi=LoanTokenLogicStandard.abi)
    #     print(iToken)
    #     loanParamIdBorrow = iToken.loanParamsIds(hashBorrow)
    #     time.sleep(1)
    #     loanParamIdTrade = iToken.loanParamsIds(hashTrade)
    #     time.sleep(1)
    #     loanParamsBorrow = BZX.loanParams(loanParamIdBorrow)
    #     time.sleep(1)
    #     loanParamsTrade = BZX.loanParams(loanParamIdTrade)
    #     print(loanParamsBorrow)
    #     print(loanParamsTrade)
    #     time.sleep(1)
    
