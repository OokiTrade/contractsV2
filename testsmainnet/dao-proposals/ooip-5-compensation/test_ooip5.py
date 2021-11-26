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

@pytest.fixture(scope="module")
def vBZRX(accounts, TestToken):
    return Contract.from_abi("vBZRX", address="0xB72B31907C1C95F3650b64b2469e08EdACeE5e8F", abi=TestToken.abi)

@pytest.fixture(scope="class")
def BZX(accounts, interface):
    return Contract.from_abi("bzx", address="0xD8Ee69652E4e4838f2531732a46d1f7F584F0b7f", abi=interface.IBZx.abi)

def testGovernanceProposal(requireMainnetFork, accounts, DAO, BZRX, TIMELOCK, BZX, BZRX, vBZRX):
    proposerAddress = "0x4c323ea8cd7b3287060cd42def3266a76881a6ac"
    voter1 = "0x9B43a385E08EE3e4b402D4312dABD11296d09E93"
    voter2 = "0x83b9e8a7fd1373022172ba571cd4e1f6463998c9"
    voter3 = "0x077b89835d729283bDCcE39840dF5B063bC1159f"
    voter4 = "0x42a3fdad947807f9fa84b8c869680a3b7a46bee7"
    voter5 = "0x212ce93b949cC68897d901e7Ef6266513840f30D"
    voter6 = "0x02c6819c2cb8519ab72fd1204a8a0992b5050c6e"
    
    exec(open("./scripts/dao-proposals/OOIP-5-compensation/proposal.py").read())

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
    tx = DAO.castVote(id, 1, {"from": voter3})
    tx = DAO.castVote(id, 1, {"from": voter4})
    tx = DAO.castVote(id, 1, {"from": voter5})
    tx = DAO.castVote(id, 1, {"from": voter6})

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
    
    
    # Validations here
    GUARDIAN_MULTISIG = "0x9B43a385E08EE3e4b402D4312dABD11296d09E93"
    TEAM_WALLET = "0x489F1af9579c63E06E20948EB68A526EAf51BF83"
    TEAM_WALLET_AMOUNT = 32101738 * 10**18
    COMPENSATION_AMOUNT = 30000000 * 10**18 # 30m

    assert vBZRX.balanceOf(TEAM_WALLET) == TEAM_WALLET_AMOUNT
    assert BZRX.balanceOf(GUARDIAN_MULTISIG) == COMPENSATION_AMOUNT
    assert False
