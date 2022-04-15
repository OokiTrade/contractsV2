#!/usr/bin/python3

import pytest
from brownie import *
import pdb



@pytest.fixture(scope="module")
def requireMainnetFork():
    assert (network.show_active() ==
            "mainnet-fork" or network.show_active() == "mainnet-fork-alchemy")

def test_IAPE(requireMainnetFork, accounts):
    exec(open("./scripts/dao-proposals/OOIP-10-iAPE/proposal.py").read())
    exec(open("./scripts/env/set-eth.py").read())
    proposerAddress = "0x02c6819c2cb8519ab72fd1204a8a0992b5050c6e"
    voter1 = "0x3fDA2D22e7853f548C3a74df3663a9427FfbB362"
    voter2 = "0x9030B78A312147DbA34359d1A8819336fD054230"

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

    APE.transfer(accounts[0], 1000e18, {'from': '0xa56cf001966d179751ba1c7fb5d137b4c5f344cc'})
    APE.approve(iAPE, 2**256-1, {'from': accounts[0]})
    iAPE.mint(accounts[0], 100e18, {'from': accounts[0]})
    iAPE.borrow("", 50e18, 7884000, 1e18, '0x0000000000000000000000000000000000000000', accounts[0], accounts[0], b"", {'from': accounts[0], 'value':1e18})
    trades = BZX.getUserLoans(accounts[0], 0,10, 0,0,0)
    APE.approve(BZX, 2**256-1, {'from': accounts[0]})
    BZX.closeWithDeposit(trades[0][0],accounts[0],trades[0][4],{'from':accounts[0]})
    assert False