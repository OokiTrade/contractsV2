#!/usr/bin/python3

import pytest
from brownie import *
import pdb


@pytest.fixture(scope="module")
def requireMainnetFork():
    assert (network.show_active() ==
            "mainnet-fork" or network.show_active() == "mainnet-fork-alchemy")


@pytest.fixture(scope="module")
def DAO(GovernorBravoDelegate):
    return Contract.from_abi("governorBravoDelegator", address="0x9da41f7810c2548572f4Fa414D06eD9772cA9e6E", abi=GovernorBravoDelegate.abi)


@pytest.fixture(scope="module")
def TIMELOCK(Timelock, accounts):
    return Contract.from_abi("TIMELOCK", address="0xfedC4dD5247B93feb41e899A09C44cFaBec29Cbc", abi=Timelock.abi, owner=accounts[0])


@pytest.fixture(scope="module")
def BZRX(accounts, TestToken):
    return Contract.from_abi("BZRX", address="0x56d811088235F11C8920698a204A5010a788f4b3", abi=TestToken.abi)

@pytest.fixture(scope="class")
def BZX(accounts, interface):
    return Contract.from_abi("bzx", address="0xD8Ee69652E4e4838f2531732a46d1f7F584F0b7f", abi=interface.IBZx.abi)

def testGovernanceProposal(requireMainnetFork, accounts, DAO, BZRX, TIMELOCK, BZX):
    proposerAddress = "0x54e88185eb636c0a75d67dccc70e9abe169ba55e"
    voter1 = "0x59150a3d034B435327C1A95A116C80F3bE2e4B5E"
    voter2 = "0x963c5d3a7712e014b46472d145ea6e0424ddb665"
    voter3 = "0x95BeeC2457838108089fcD0E059659A4E60B091A"
    
    exec(open("./scripts/dao-proposals/OOIP-3-governance-batch-operation/proposal.py").read())

    proposalCount = DAO.proposalCount()
    proposal = DAO.proposals(proposalCount)
    id = proposal[0]
    startBlock = proposal[3]
    endBlock = proposal[4]

    assert DAO.state.call(id) == 0
    chain.mine(startBlock - chain.height + 1)
    assert DAO.state.call(id) == 1

    tx = DAO.castVote(id, 1, {"from": proposerAddress})
    tx = DAO.castVote(id, 1, {"from": voter1})
    tx = DAO.castVote(id, 1, {"from": voter2})
    tx = DAO.castVote(id, 1, {"from": voter3})

    assert DAO.state.call(id) == 1

    chain.mine(endBlock - chain.height)
    assert DAO.state.call(id) == 1
    chain.mine()
    assert DAO.state.call(id) == 4

    DAO.queue(id, {"from": proposerAddress})

    proposal = DAO.proposals(proposalCount)
    eta = proposal[2]
    chain.sleep(eta - chain.time())
    chain.mine()

    DAO.execute(id, {"from": proposerAddress})
    
    # upgrade DAO implementation
    implementation = DAO.implementation()
    # assert implementation == daoImpl
    assert DAO.proposalMaxOperations() == 100
    assert DAO.quorumVotes() <= 41200000e18
    
    # upgrade STAKING implementation
    # assert stakingProxy.implementation() == stakingImpl

    # BZX.setTargets(...) to disable CHI modules
    target = BZX.getTarget("swapExternalWithGasToken(address,address,address,address,address,uint256,uint256,bytes)")
    assert target == "0x0000000000000000000000000000000000000000"

    # BZX.setLoanPool(...) to disable LEND pool
    assert BZX.loanPoolToUnderlying(iLEND) == "0x0000000000000000000000000000000000000000"

    # BZRX.transferFrom(Timelock, 0x2a599cEba64CAb8C88549c2c7314ea02A161fC70)
    assert BZRX.balanceOf("0x2a599cEba64CAb8C88549c2c7314ea02A161fC70") == 250000 * 1e18 + 21904856 * 1e18 # dao guardians multisig

    # BZBZX.replaceContract to deploy ProtocolPausableGuardian module
    # assert BZX.getTarget("toggleFunctionPause(bytes4)") == pausableGuardianImpl
    assert False
