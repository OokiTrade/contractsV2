#!/usr/bin/python3

import pytest
from brownie import network, Contract, Wei, chain


@pytest.fixture(scope="module")
def requireMainnetFork():
    assert (network.show_active() == "mainnet-fork" or network.show_active() == "mainnet-fork-alchemy")


def testStake_VoteDelegate(requireMainnetFork, stakingV1_1, governance,LPT, accounts,stakingVoteDelegator, BZRX, iUSDC, vBZRX):
    proposer = "0x95BeeC2457838108089fcD0E059659A4E60B091A"
    acct = '0xd28aaacaa524f50da5c6025ca5a5e1a8cbf84647'
    vp1 = stakingV1_1.votingBalanceOfNow(acct)
    stakingVoteDelegator.delegate(accounts[0], {'from': acct})
    chain.mine()
    assert stakingV1_1.votingBalanceOfNow(acct) == 0
    assert stakingV1_1.votingBalanceOfNow(accounts[0]) >= vp1
    chain.mine()
    assert stakingV1_1.votingBalanceOfNow(proposer) > 0

    governance.propose([iUSDC.address],[0],[""],[""],"asdf", {"from": proposer})
    proposalId = governance.proposalCount()
    proposal = governance.proposals(governance.proposalCount())

    chain.mine(proposal[3] - chain.height +1)
    vp1 = stakingV1_1.votingBalanceOf(accounts[0], proposalId)
    stakingV1_1.unstake([BZRX], [100e18], {'from': acct})
    chain.mine()
    assert stakingV1_1.votingBalanceOf(accounts[0], proposalId) == vp1

    stakingVoteDelegator.delegate(acct, {'from': acct})
    chain.mine()
    assert stakingV1_1.votingBalanceOfNow(acct) > 0
    assert stakingV1_1.votingBalanceOfNow(accounts[0]) == 0
    assert stakingV1_1.votingBalanceOf(accounts[0], proposalId) == vp1
    stakingVoteDelegator.delegate(accounts[0], {'from': proposer})
    chain.mine()
    assert stakingV1_1.votingBalanceOfNow(proposer) == 0
    assert stakingV1_1.votingBalanceOfNow(accounts[0]) > 0
    assert stakingV1_1.votingBalanceOf(accounts[0], proposalId) == vp1

    assert True