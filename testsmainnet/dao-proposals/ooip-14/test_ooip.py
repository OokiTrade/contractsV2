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
    return Contract.from_abi("governorBravoDelegator", address="0x3133b4f4dcffc083724435784fefad510fa659c6", abi=GovernorBravoDelegate.abi)


@pytest.fixture(scope="module")
def TIMELOCK(Timelock, accounts):
    return Contract.from_abi("TIMELOCK", address="0xfedC4dD5247B93feb41e899A09C44cFaBec29Cbc", abi=Timelock.abi, owner=accounts[0])


@pytest.fixture(scope="module")
def BZX(Timelock, accounts):
    return Contract.from_abi("BZX", "0xD8Ee69652E4e4838f2531732a46d1f7F584F0b7f", interface.IBZx.abi)

@pytest.fixture(scope="module")
def OOKI(accounts, TestToken):
    return Contract.from_abi("OOKI", address="0x0De05F6447ab4D22c8827449EE4bA2D5C288379B", abi=TestToken.abi)

@pytest.fixture(scope="module")
def BZRX(accounts, TestToken):
    return Contract.from_abi("BZRX", address="0x0De05F6447ab4D22c8827449EE4bA2D5C288379B", abi=TestToken.abi)

def testGovernanceProposal(requireMainnetFork, accounts, DAO, TIMELOCK, BZX, OOKI, BZRX):
    proposerAddress = "0x02c6819c2cb8519ab72fd1204a8a0992b5050c6e"
    voter1 = "0x3fDA2D22e7853f548C3a74df3663a9427FfbB362"
    voter2 = "0x9030B78A312147DbA34359d1A8819336fD054230"

   
    
    exec(open("./scripts/dao-proposals/OOIP-14-compensation-allocation/proposal.py").read())

    proposalCount = DAO.proposalCount()
    proposal = DAO.proposals(proposalCount)
    id = proposal[0]
    startBlock = proposal[3]
    endBlock = proposal[4]
    forVotes = proposal[5]
    againstVotes = proposal[6]

    assert DAO.state.call(id) == 0
    chain.mine(startBlock - chain.height + 1)
    assert DAO.state.call(id) == 1

    tx = DAO.castVote(id, 1, {"from": proposerAddress})
    tx = DAO.castVote(id, 1, {"from": voter1})
    tx = DAO.castVote(id, 1, {"from": voter2})

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

    beforeBalance = USDT.balanceOf("0x9B43a385E08EE3e4b402D4312dABD11296d09E93")
    USDT_AMOUNT = USDT.balanceOf(TIMELOCK)

    DAO.execute(id, {"from": proposerAddress})
    
    assert USDT.balanceOf(TIMELOCK)  == 0
    afterBalance = USDT.balanceOf("0x9B43a385E08EE3e4b402D4312dABD11296d09E93")
    assert beforeBalance + USDT_AMOUNT == afterBalance
    assert True