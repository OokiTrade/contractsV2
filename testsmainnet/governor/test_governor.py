#!/usr/bin/python3

import pytest
from brownie import network, Contract, Wei, chain, reverts


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


@pytest.fixture(scope="module")
def iUSDC(LoanTokenLogicStandard):
    iUSDC = loadContractFromAbi(
        "0x32E4c68B3A4a813b710595AebA7f6B7604Ab9c15", "iUSDC", LoanTokenLogicStandard.abi)
    return iUSDC

@pytest.fixture(scope="module")
def TOKEN_SETTINGS(LoanTokenSettings):
    return Contract.from_abi(
        "loanToken", address="0x11ba2b39bc80464c14b7eea54d2ec93d8f60e7b8", abi=LoanTokenSettings.abi)

@pytest.fixture(scope="function", autouse=True)
def isolate(fn_isolation):
    pass


def loadContractFromAbi(address, alias, abi):
    try:
        return Contract(alias)
    except ValueError:
        contract = Contract.from_abi(alias, address=address, abi=abi)
        return contract


def testGovernance(requireMainnetFork, GOVERNANCE_DELEGATOR, TIMELOCK, STAKING, TOKEN_SETTINGS, iUSDC, accounts):  
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

    # make a proposal to change iUSDC name
    newName = iUSDC.name() + "1"
    calldata = TOKEN_SETTINGS.initialize.encode_input(iUSDC.loanTokenAddress(), newName, iUSDC.symbol())
    calldata2 = iUSDC.updateSettings.encode_input(TOKEN_SETTINGS, calldata)

    tx = GOVERNANCE_DELEGATOR.propose([iUSDC.address],[0],[""],[calldata2],"asdf", {"from": bzxOwner})
    proposalCount = GOVERNANCE_DELEGATOR.proposalCount()
    proposal = GOVERNANCE_DELEGATOR.proposals(proposalCount)
    id = proposal[0]
    eta = proposal[2]
    startBlock = proposal[3]
    endBlock = proposal[4]
    forVotes = proposal[5]
    againstVotes = proposal[6]
    abstainVotes = proposal[7]
    canceled = proposal[8]
    assert GOVERNANCE_DELEGATOR.state.call(id) == 0
    chain.mine()

    # after first vote state is active
    tx = GOVERNANCE_DELEGATOR.castVote(id,1, {"from" : bzxOwner})
    assert GOVERNANCE_DELEGATOR.state.call(id) == 1

    chain.mine(endBlock - chain.height)
    assert GOVERNANCE_DELEGATOR.state.call(id) == 1
    chain.mine()
    assert GOVERNANCE_DELEGATOR.state.call(id) == 4
    
    GOVERNANCE_DELEGATOR.queue(id)

    proposal = GOVERNANCE_DELEGATOR.proposals(proposalCount)
    eta = proposal[2]
    chain.sleep(eta - chain.time())
    chain.mine()

    iUSDC.transferOwnership(TIMELOCK, {"from": bzxOwner})
    GOVERNANCE_DELEGATOR.execute(id)

    assert True


def testGovernanceProposeCancel(requireMainnetFork, GOVERNANCE_DELEGATOR, TIMELOCK, STAKING, TOKEN_SETTINGS, iUSDC, accounts):  
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

    # make a proposal to change iUSDC name
    newName = iUSDC.name() + "1"
    calldata = TOKEN_SETTINGS.initialize.encode_input(iUSDC.loanTokenAddress(), newName, iUSDC.symbol())
    calldata2 = iUSDC.updateSettings.encode_input(TOKEN_SETTINGS, calldata)

    tx = GOVERNANCE_DELEGATOR.propose([iUSDC.address],[0],[""],[calldata2],"asdf", {"from": bzxOwner})
    proposalCount = GOVERNANCE_DELEGATOR.proposalCount()
    proposal = GOVERNANCE_DELEGATOR.proposals(proposalCount)
    id = proposal[0]
    eta = proposal[2]
    startBlock = proposal[3]
    endBlock = proposal[4]
    forVotes = proposal[5]
    againstVotes = proposal[6]
    abstainVotes = proposal[7]
    canceled = proposal[8]
   
    tx = GOVERNANCE_DELEGATOR.cancel(id, {"from": bzxOwner})
    proposal = GOVERNANCE_DELEGATOR.proposals(proposalCount)
    canceled = proposal[8]
    assert canceled == True



def testGovernanceProposeVotingActiveCancel(requireMainnetFork, GOVERNANCE_DELEGATOR, TIMELOCK, STAKING, TOKEN_SETTINGS, iUSDC, accounts):  
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

    # make a proposal to change iUSDC name
    newName = iUSDC.name() + "1"
    calldata = TOKEN_SETTINGS.initialize.encode_input(iUSDC.loanTokenAddress(), newName, iUSDC.symbol())
    calldata2 = iUSDC.updateSettings.encode_input(TOKEN_SETTINGS, calldata)

    tx = GOVERNANCE_DELEGATOR.propose([iUSDC.address],[0],[""],[calldata2],"asdf", {"from": bzxOwner})
    proposalCount = GOVERNANCE_DELEGATOR.proposalCount()
    proposal = GOVERNANCE_DELEGATOR.proposals(proposalCount)
    id = proposal[0]
    eta = proposal[2]
    startBlock = proposal[3]
    endBlock = proposal[4]
    forVotes = proposal[5]
    againstVotes = proposal[6]
    abstainVotes = proposal[7]
    canceled = proposal[8]

    chain.mine()
    tx = GOVERNANCE_DELEGATOR.castVote(id,1, {"from" : bzxOwner})
    assert GOVERNANCE_DELEGATOR.state.call(id) == 1
   
    tx = GOVERNANCE_DELEGATOR.cancel(id, {"from": bzxOwner})
    proposal = GOVERNANCE_DELEGATOR.proposals(proposalCount)
    canceled = proposal[8]
    assert canceled == True


def testGovernanceProposeVotingActiveVotingEndsDefeated(requireMainnetFork, GOVERNANCE_DELEGATOR, TIMELOCK, STAKING, TOKEN_SETTINGS, iUSDC, accounts):  
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

    # make a proposal to change iUSDC name
    newName = iUSDC.name() + "1"
    calldata = TOKEN_SETTINGS.initialize.encode_input(iUSDC.loanTokenAddress(), newName, iUSDC.symbol())
    calldata2 = iUSDC.updateSettings.encode_input(TOKEN_SETTINGS, calldata)

    tx = GOVERNANCE_DELEGATOR.propose([iUSDC.address],[0],[""],[calldata2],"asdf", {"from": bzxOwner})
    proposalCount = GOVERNANCE_DELEGATOR.proposalCount()
    proposal = GOVERNANCE_DELEGATOR.proposals(proposalCount)
    id = proposal[0]
    eta = proposal[2]
    startBlock = proposal[3]
    endBlock = proposal[4]
    forVotes = proposal[5]
    againstVotes = proposal[6]
    abstainVotes = proposal[7]
    canceled = proposal[8]

    chain.mine()
    tx = GOVERNANCE_DELEGATOR.castVote(id,0, {"from" : bzxOwner})
    assert GOVERNANCE_DELEGATOR.state.call(id) == 1
   

    chain.mine(endBlock - chain.height)
    assert GOVERNANCE_DELEGATOR.state.call(id) == 1
    chain.mine()
    assert GOVERNANCE_DELEGATOR.state.call(id) == 3
    with reverts("GovernorBravo::queue: proposal can only be queued if it is succeeded"):
        GOVERNANCE_DELEGATOR.queue(id)

    tx = GOVERNANCE_DELEGATOR.cancel(id, {"from": bzxOwner})
    proposal = GOVERNANCE_DELEGATOR.proposals(proposalCount)
    canceled = proposal[8]
    assert canceled == True

