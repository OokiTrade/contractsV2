#!/usr/bin/python3

import pytest
from brownie import network, Contract, Wei, chain, reverts


@pytest.fixture(scope="module")
def requireMainnetFork():
    assert (network.show_active() == "mainnet-fork" or network.show_active() == "mainnet-fork-alchemy")

proposer = "0x95BeeC2457838108089fcD0E059659A4E60B091A"
acct = '0xd28aaacaa524f50da5c6025ca5a5e1a8cbf84647'


def resetdelegators(stakingVoteDelegator):
    stakingVoteDelegator.delegate(proposer, {'from': proposer})
    stakingVoteDelegator.delegate(acct, {'from': acct})


def testStake_VoteDelegateWF1(requireMainnetFork, stakingV1_1, governance,LPT, accounts,stakingVoteDelegator, BZRX, iUSDC, vBZRX, bzx):
    BZRX.transfer(proposer,  BZRX.balanceOf(bzx), {'from': bzx})
    resetdelegators(stakingVoteDelegator)
    stakingV1_1.stake([BZRX], [BZRX.balanceOf(proposer)], {'from': proposer})
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
    governance.cancel(proposalId, {"from": accounts[0]})
    assert True

def testStake_VoteDelegateCreateProposal(requireMainnetFork, stakingV1_1, governance,LPT, accounts,stakingVoteDelegator, BZRX, iUSDC, vBZRX,bzx):
    BZRX.transfer(proposer,  BZRX.balanceOf(bzx), {'from': bzx})
    resetdelegators(stakingVoteDelegator)
    stakingV1_1.stake([BZRX], [BZRX.balanceOf(proposer)], {'from': proposer})
    vp1 = stakingV1_1.votingBalanceOfNow(proposer)
    stakingVoteDelegator.delegate(accounts[0], {'from': proposer})
    chain.mine()
    assert stakingV1_1.votingBalanceOfNow(proposer) == 0
    assert stakingV1_1.votingBalanceOfNow(accounts[0]) >= vp1
    chain.mine()

    with reverts("GovernorBravo::propose: proposer votes below proposal threshold"):
        governance.propose([iUSDC.address],[0],[""],[""],"asdf", {"from": proposer})

    governance.propose([iUSDC.address],[0],[""],[""],"asdf", {"from": accounts[0]})
    proposalId = governance.proposalCount()
    governance.cancel(proposalId, {"from": accounts[0]})

    assert True

def testStake_VoteDelegate2Delegates(requireMainnetFork, stakingV1_1, governance,LPT, accounts,stakingVoteDelegator, BZRX, iUSDC, vBZRX, bzx):
    BZRX.transfer(proposer,  BZRX.balanceOf(bzx), {'from': bzx})
    resetdelegators(stakingVoteDelegator)
    stakingV1_1.stake([BZRX], [BZRX.balanceOf(proposer)], {'from': proposer})
    vp1 = stakingV1_1.votingBalanceOfNow(acct)
    vp2 = stakingV1_1.votingBalanceOfNow(proposer)
    stakingVoteDelegator.delegate(proposer, {'from': proposer})
    stakingVoteDelegator.delegate(acct, {'from': acct})

    stakingVoteDelegator.delegate(acct, {'from': proposer})
    stakingVoteDelegator.delegate(accounts[1], {'from': acct})
    chain.mine()
    assert stakingV1_1.votingBalanceOfNow(proposer) == 0
    assert stakingV1_1.votingBalanceOfNow(acct) > vp2
    vp3 = stakingV1_1.votingBalanceOfNow(accounts[1]);
    assert vp3 >= vp1 and vp3 < vp1 + vp2
    assert True


def testStake_VoteDelegateCancel(requireMainnetFork, stakingV1_1, governance,LPT, accounts,stakingVoteDelegator, BZRX, iUSDC, vBZRX, bzx):
    BZRX.transfer(proposer,  BZRX.balanceOf(bzx), {'from': bzx})
    resetdelegators(stakingVoteDelegator)
    stakingV1_1.stake([BZRX], [BZRX.balanceOf(proposer)], {'from': proposer})
    stakingVoteDelegator.delegate(proposer, {'from': acct})
    governance.propose([iUSDC.address],[0],[""],[""],"asdf", {"from": proposer})
    proposalId = governance.proposalCount()
    proposal = governance.proposals(governance.proposalCount())

    with reverts("GovernorBravo::cancel: proposer above threshold"):
        governance.cancel(proposalId,{'from': accounts[0]})

    unstakeAmount =  stakingV1_1.balanceOfByAsset(BZRX, proposer) - 1e24
    stakingV1_1.unstake([BZRX], [unstakeAmount], {'from': proposer})
    governance.cancel(proposalId,{'from': accounts[0]})
    assert governance.proposals(governance.proposalCount())[8] == True
    assert True
