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
def iLINK(accounts, LoanTokenLogicStandard):
    return Contract.from_abi("iLINK", address="0x463538705E7d22aA7f03Ebf8ab09B067e1001B54", abi=LoanTokenLogicStandard.abi)

@pytest.fixture(scope="module")
def DAI(accounts, TestToken):
    return Contract.from_abi("DAI", address="0x6B175474E89094C44Da98b954EedeAC495271d0F", abi=TestToken.abi)


@pytest.fixture(scope="module")
def iUSDC(accounts, LoanTokenLogicStandard):
    return Contract.from_abi("iUSDC", address="0x32E4c68B3A4a813b710595AebA7f6B7604Ab9c15", abi=LoanTokenLogicStandard.abi)

@pytest.fixture(scope="module")
def LINK(accounts, TestToken):
    return Contract.from_abi("iUSDC", address="0x514910771AF9Ca656af840dff83E8264EcF986CA", abi=TestToken.abi)


def testGovernanceProposal(requireMainnetFork, accounts, DAO, TIMELOCK, iLINK, iUSDC, LINK, BZX, DAI):
    proposerAddress = "0x02c6819c2cb8519ab72fd1204a8a0992b5050c6e"
    voter1 = "0x3fDA2D22e7853f548C3a74df3663a9427FfbB362"
    voter2 = "0x9030B78A312147DbA34359d1A8819336fD054230"


    
    
    exec(open("./scripts/dao-proposals/OOIP-8-itoken-collateral/proposal.py").read())

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

    DAO.execute(id, {"from": proposerAddress})

    GUARDIAN_MULTISIG = "0x9B43a385E08EE3e4b402D4312dABD11296d09E93"
    DAI.transferFrom("0xbebc44782c7db0a1a60cb6fe97d0b483032ff1c7", GUARDIAN_MULTISIG, 100e18, {"from": "0xbebc44782c7db0a1a60cb6fe97d0b483032ff1c7"})
    DAI.approve(BZX, 2**256-1, {"from": GUARDIAN_MULTISIG})
    
    loan = BZX.getLoan("0xe7910c565431160a3d6cdac821dc78ae069c9901907004fb3d4deec30f4fcbad")
    assert loan[4] > 0

    BZX.cleanupLoans("0x6B175474E89094C44Da98b954EedeAC495271d0F", ["0xe7910c565431160a3d6cdac821dc78ae069c9901907004fb3d4deec30f4fcbad"], {"from": GUARDIAN_MULTISIG})

    loan = BZX.getLoan("0xe7910c565431160a3d6cdac821dc78ae069c9901907004fb3d4deec30f4fcbad")
    assert loan[4] == 0
    assert loan[5] == 0

    assert False