#!/usr/bin/python3

import pytest
from brownie import network, Contract, Wei, chain


@pytest.fixture(scope="module")
def requireMainnetFork():
    assert (network.show_active() == "mainnet-fork" or network.show_active() == "mainnet-fork-alchemy")

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

@pytest.fixture(scope="module")
def GOVERNANCE_DELEGATOR(accounts, GovernorBravoDelegator, STAKING, TIMELOCK, GovernorBravoDelegate):
    ADMIN = accounts[0]
    MIN_VOTINGPEROD = 5760
    MIN_VOTING_DELAY = 1
    MIN_PROPOSAL_THRESHOLD = 50000e18
    impl = accounts[0].deploy(GovernorBravoDelegate)
    governorBravoDelegator = accounts[0].deploy(GovernorBravoDelegator, TIMELOCK, STAKING, ADMIN, impl, MIN_VOTINGPEROD, MIN_VOTING_DELAY, MIN_PROPOSAL_THRESHOLD) 
    return Contract.from_abi("governorBravoDelegator", address=governorBravoDelegator, abi=GovernorBravoDelegate.abi, owner=accounts[0])

@pytest.fixture(scope="module")
def STAKING(StakingV1_1, accounts, StakingProxy):
    bzxOwner = "0xB7F72028D9b502Dc871C444363a7aC5A52546608"
    stakingAddress = "0xe95Ebce2B02Ee07dEF5Ed6B53289801F7Fc137A4"
    proxy = Contract.from_abi("staking", address=stakingAddress,abi=StakingProxy.abi)
    impl = accounts[0].deploy(StakingV1_1)
    proxy.replaceImplementation(impl, {"from": bzxOwner})
    return Contract.from_abi("staking", address=stakingAddress,abi=StakingV1_1.abi)

@pytest.fixture(scope="module")
def TIMELOCK(Timelock, accounts):
    hours12 = 12*60*60
    timelock = accounts[0].deploy(Timelock, accounts[0], hours12)
    return timelock

def loadContractFromAbi(address, alias, abi):
    try:
        return Contract(alias)
    except ValueError:
        contract = Contract.from_abi(alias, address=address, abi=abi)
        return contract

def testGovernance(requireMainnetFork, GOVERNANCE_DELEGATOR, TIMELOCK, STAKING):
    bzxOwner = "0xB7F72028D9b502Dc871C444363a7aC5A52546608"
    
    # init timelock below
    calldata = TIMELOCK.setPendingAdmin.encode_input(GOVERNANCE_DELEGATOR.address)
    eta = chain.time()+TIMELOCK.delay() + 10
    TIMELOCK.queueTransaction(TIMELOCK, 0, b"", calldata, eta)
    chain.sleep(eta-chain.time())
    chain.mine()
    TIMELOCK.executeTransaction(TIMELOCK, 0, b"", calldata, eta)

    # set staking with governor
    STAKING.setGovernor(GOVERNANCE_DELEGATOR, {"from": bzxOwner})

    # init governance
    GOVERNANCE_DELEGATOR._initiate()
    tx = GOVERNANCE_DELEGATOR.propose([],[],[],[],"asdf")
    assert False