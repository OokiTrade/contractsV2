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
def BZRX(accounts, TestToken):
    return Contract.from_abi("BZRX", address="0x56d811088235F11C8920698a204A5010a788f4b3", abi=TestToken.abi)
    
@pytest.fixture(scope="module")
def GOVERNANCE_DELEGATOR(accounts, GovernorBravoDelegator, STAKING, TIMELOCK, GovernorBravoDelegate, BZRX):

    gov = Contract.from_abi("governorBravoDelegator", address="0x9da41f7810c2548572f4Fa414D06eD9772cA9e6E", abi=GovernorBravoDelegate.abi)

    bzxOwner = STAKING.owner()
    gov.__setPendingLocalAdmin(TIMELOCK, {'from': bzxOwner})
    # gov.__acceptLocalAdmin({'from': TIMELOCK})
    # gov.__acceptAdmin({'from': bzxOwner})


    BZRX.transferFrom("0xBE0eB53F46cd790Cd13851d5EFf43D12404d33E8", bzxOwner, 50*1e6*1e18, {'from': "0xBE0eB53F46cd790Cd13851d5EFf43D12404d33E8"})
    STAKING.stake([BZRX], [BZRX.balanceOf(bzxOwner)], {'from': bzxOwner})
    return gov

@pytest.fixture(scope="module")
def STAKING(StakingV1_1, accounts, StakingProxy):

    stakingAddress = "0xe95Ebce2B02Ee07dEF5Ed6B53289801F7Fc137A4"
    return Contract.from_abi("staking", address=stakingAddress,abi=StakingV1_1.abi)

@pytest.fixture(scope="module")
def TIMELOCK(Timelock, accounts):
    timelock = Contract.from_abi("TIMELOCK", address="0xfedC4dD5247B93feb41e899A09C44cFaBec29Cbc", abi=Timelock.abi, owner=accounts[0])
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

def testGovernanceAcceptLocalAdmin(requireMainnetFork, GOVERNANCE_DELEGATOR, TIMELOCK, STAKING, TOKEN_SETTINGS, iUSDC, accounts,TestToken, LoanTokenLogicStandard, TokenRegistry, LoanToken, LoanTokenSettings, interface, PriceFeeds, ProtocolSettings, LoanTokenSettingsLowerAdmin, BZRX):  
    proposer = "0x95BeeC2457838108089fcD0E059659A4E60B091A"
    bzxOwner = accounts.at("0xB7F72028D9b502Dc871C444363a7aC5A52546608", force=True)

    # FIRST
    # begining of building calldata arrays 

    # calldataArray = getTransactionListToDeployITokens(accounts)
    calldataArray = []
    targets = []

    calldata = GOVERNANCE_DELEGATOR.__acceptLocalAdmin.encode_input()

    calldataArray.append(calldata)
    targets.append(GOVERNANCE_DELEGATOR.address)


    tx = GOVERNANCE_DELEGATOR.propose(
        targets,
        [0] * len(calldataArray),
        [""] * len(calldataArray),
        calldataArray,
        "DAO.__acceptLocalAdmin()", 
        {"from": proposer})
    

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
    chain.mine(startBlock - chain.height)

    # after first vote state is active
    tx = GOVERNANCE_DELEGATOR.castVote(id, 1, {"from" : bzxOwner})
    assert GOVERNANCE_DELEGATOR.state.call(id) == 1

    chain.mine(endBlock - chain.height)
    assert GOVERNANCE_DELEGATOR.state.call(id) == 1
    chain.mine()
    assert GOVERNANCE_DELEGATOR.state.call(id) == 4
    
    GOVERNANCE_DELEGATOR.queue(id, {"from" : bzxOwner})

    proposal = GOVERNANCE_DELEGATOR.proposals(proposalCount)
    eta = proposal[2]
    chain.sleep(eta - chain.time())
    chain.mine()

    GOVERNANCE_DELEGATOR.execute(id, {"from" : bzxOwner})

    # at this point gov and timelock owns each other.
    assert GOVERNANCE_DELEGATOR.admin() == TIMELOCK
    assert TIMELOCK.admin() == GOVERNANCE_DELEGATOR
    
    assert True