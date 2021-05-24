#!/usr/bin/python3

import pytest
from brownie import network, Contract, Wei, chain


@pytest.fixture(scope="module")
def requireMainnetFork():
    assert (network.show_active() == "mainnet-fork" or network.show_active() == "mainnet-fork-alchemy")

@pytest.fixture(scope="module")
def EXECUTOR(GovernanceExecutor, accounts):
    return GovernanceExecutor.deploy({'from': '0xB7F72028D9b502Dc871C444363a7aC5A52546608'}) # bzx owner
    

@pytest.fixture(scope="module")
def iUSDC(accounts, LoanTokenLogicStandard):
    iUSDC = loadContractFromAbi(
        "0x32E4c68B3A4a813b710595AebA7f6B7604Ab9c15", "iUSDC", LoanTokenLogicStandard.abi)
    return iUSDC

@pytest.fixture(scope="module")
def BZX(accounts, LoanTokenLogicStandard, interface):
    BZX = loadContractFromAbi(
        "0xD8Ee69652E4e4838f2531732a46d1f7F584F0b7f", "BZX", abi=interface.IBZx.abi)
    return BZX

def loadContractFromAbi(address, alias, abi):
    try:
        return Contract(alias)
    except ValueError:
        contract = Contract.from_abi(alias, address=address, abi=abi)
        return contract

def testGovernanceExecutor(requireMainnetFork, EXECUTOR, BZX, iUSDC, LoanTokenSettings):
    bzxOwner = '0xB7F72028D9b502Dc871C444363a7aC5A52546608'
    loanTokenSettings = Contract.from_abi(
        "loanToken", address="0xcd273a029fB6aaa89ca9A7101C5901b1f429d457", abi=LoanTokenSettings.abi, owner=bzxOwner)
    
    assert iUSDC.name() == 'Fulcrum USDC iToken'
    newName = iUSDC.name() + "1"
    
    calldata = loanTokenSettings.initialize.encode_input(iUSDC.loanTokenAddress(), newName, iUSDC.symbol())
    calldata2 = iUSDC.updateSettings.encode_input(loanTokenSettings, calldata)


    EXECUTOR.executeBatch([iUSDC], [calldata2])


    assert iUSDC.name() + "1" == newName
    assert False
