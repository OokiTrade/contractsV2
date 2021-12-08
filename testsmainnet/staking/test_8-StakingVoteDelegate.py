#!/usr/bin/python3

import pytest
from brownie import network, Contract, Wei, chain, reverts
import time


@pytest.fixture(scope="module")
def requireMainnetFork():
    assert (network.show_active() == "mainnet-fork" or network.show_active() == "mainnet-fork-alchemy")


proposer = "0x7a1d27e928CCFeAa2C5182031aeb6F2ECB07eA13"
acct = "0x4c323ea8cd7b3287060cd42def3266a76881a6ac"


def resetdelegators(stakingVoteDelegator):
    stakingVoteDelegator.delegate(proposer, {'from': proposer})
    stakingVoteDelegator.delegate(acct, {'from': acct})
    chain.mine()



def testStake_VoteDelegateWF1(requireMainnetFork, stakingV1_1, governance,LPT, accounts,stakingVoteDelegator, BZRX, iUSDC, vBZRX, bzx):
    BZRX.transfer(proposer,  BZRX.balanceOf(bzx), {'from': bzx})
    resetdelegators(stakingVoteDelegator)
    stakingV1_1.unstake([BZRX], [1000e18], {'from': proposer})
    time.sleep(3)
    chain.mine()

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
    stakingV1_1.unstake([BZRX], [1000e18], {'from': proposer})
    time.sleep(3)
    chain.mine()

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


def testStake_VoteDelegateCancel(requireMainnetFork, stakingV1_1, governance,LPT, accounts,stakingVoteDelegator, BZRX, iUSDC, vBZRX, bzx):
    BZRX.transfer(proposer,  BZRX.balanceOf(bzx), {'from': bzx})
    resetdelegators(stakingVoteDelegator)
    stakingV1_1.unstake([BZRX], [1000e18], {'from': proposer})
    time.sleep(3)
    chain.mine()
    
    stakingVoteDelegator.delegate(proposer, {'from': acct})
    chain.mine()
    governance.propose([iUSDC.address],[0],[""],[""],"asdf", {"from": proposer})
    proposalId = governance.proposalCount()
    proposal = governance.proposals(governance.proposalCount())

    with reverts("GovernorBravo::cancel: proposer above threshold"):
        governance.cancel(proposalId,{'from': accounts[0]})

    unstakeAmount =  stakingV1_1.balanceOfByAsset(BZRX, proposer) - 1e24
    stakingV1_1.unstake([BZRX], [unstakeAmount], {'from': proposer})
    stakingVoteDelegator.delegate(acct, {'from': acct})
    chain.mine()
    governance.cancel(proposalId,{'from': accounts[0]})
    assert governance.proposals(governance.proposalCount())[8] == True
    assert True




def testStake_VoteDelegate2Delegates0(requireMainnetFork, stakingV1_1, governance,LPT, accounts,stakingVoteDelegator, BZRX, iUSDC, vBZRX, bzx):
    BZRX.transfer(proposer,  BZRX.balanceOf(bzx), {'from': bzx})
    resetdelegators(stakingVoteDelegator)

    stakingV1_1.stake([BZRX], [BZRX.balanceOf(proposer)], {'from': proposer})
    time.sleep(3)
    chain.mine()
    vp1 = stakingV1_1.votingBalanceOfNow(acct)
    vp2 = stakingV1_1.votingBalanceOfNow(proposer)

    stakingVoteDelegator.delegate(acct, {'from': proposer})
    stakingVoteDelegator.delegate(accounts[1], {'from': acct})
    chain.mine()
    assert stakingV1_1.votingBalanceOfNow(proposer) == 0
    assert int(stakingV1_1.votingBalanceOfNow(acct) / vp2 * 10000) == 10000
    assert int(stakingV1_1.votingBalanceOfNow(accounts[1]) / vp1 * 10000) == 10000
    assert True


def testStake_VoteDelegateClaim0(requireMainnetFork, stakingV1_1, governance,LPT, accounts,stakingVoteDelegator, BZRX, iUSDC, vBZRX, bzx):
    BZRX.transfer(proposer,  BZRX.balanceOf(bzx), {'from': bzx})
    resetdelegators(stakingVoteDelegator)
    vp1 = stakingV1_1.votingBalanceOfNow(acct)
    stakingV1_1.stake([BZRX], [BZRX.balanceOf(proposer)], {'from': proposer})
    time.sleep(3)
    chain.mine()
    chain.mine()
    vp2 = stakingV1_1.votingBalanceOfNow(proposer)
    print ("vp2", vp2)
    chain.mine()
    vp2 = stakingV1_1.votingBalanceOfNow(proposer)
    print ("vp2", vp2)

    stakingVoteDelegator.delegate(accounts[0], {'from': proposer})
    stakingVoteDelegator.delegate(accounts[0], {'from': acct})
    chain.mine()

    vp0 = stakingV1_1.votingBalanceOfNow(accounts[0])
    assert int(vp0 / (vp1 + vp2) * 10000) == 10000
    stakingV1_1.claim(False, {'from': proposer})

    chain.mine()
    vp00 = stakingV1_1.votingBalanceOfNow(accounts[0]);
    assert vp0 > vp00

    stakingV1_1.claim(True, {'from': acct})
    chain.mine()
    vp01 = stakingV1_1.votingBalanceOfNow(accounts[0]);
    assert vp00 <= vp01

    assert True



def testStake_VoteDelegatePause(requireMainnetFork, stakingV1_1, governance,LPT, accounts,stakingVoteDelegator, BZRX, iUSDC, vBZRX, bzx):

    stakingVoteDelegator.changeGuardian('0x8f6a694fe9d99f4913501e6592438598da415c9e', {'from': stakingVoteDelegator.owner()})
    resetdelegators(stakingVoteDelegator)
    vp1 = stakingV1_1.votingBalanceOfNow(acct)
    vp2 = stakingV1_1.votingBalanceOfNow(proposer)

    stakingVoteDelegator.delegate(accounts[0], {'from': acct})
    stakingVoteDelegator.delegate(accounts[0], {'from': proposer})
    chain.mine()
    vp0 = stakingV1_1.votingBalanceOfNow(accounts[0])
    assert int(vp0 / (vp1 + vp2) * 10000) == 10000

    nbCheckpoint0 = stakingVoteDelegator.numCheckpoints(accounts[0])
    checkpoint0 = stakingVoteDelegator.checkpoints(accounts[0],nbCheckpoint0-1)[1]

    stakingVoteDelegator.toggleFunctionPause(stakingVoteDelegator.delegate.signature,{'from': stakingVoteDelegator.owner()})

    with reverts("paused"):
        stakingVoteDelegator.delegate(accounts[0], {'from': proposer})

    assert stakingV1_1.votingBalanceOfNow(accounts[0]) == 0
    assert int(stakingV1_1.votingBalanceOfNow(acct) / vp1 * 10000) == 10000
    assert int(stakingV1_1.votingBalanceOfNow(proposer) / vp2 * 10000) == 10000

    stakingV1_1.unstake([BZRX], [10000e18], {'from': proposer})
    time.sleep(3)
    chain.mine()
    assert int(stakingV1_1.votingBalanceOfNow(proposer) / (vp2 - 10000e18) * 10000) == 10000
    stakingV1_1.claim(False, {'from': proposer})
    chain.mine()

    nbCheckpoint1 = stakingVoteDelegator.numCheckpoints(accounts[0])
    checkpoint1 = stakingVoteDelegator.checkpoints(accounts[0],nbCheckpoint1-1)[1]

    assert nbCheckpoint1>nbCheckpoint0
    assert checkpoint0 - checkpoint1 > 10000e18

    vp0 = stakingV1_1.votingBalanceOfNow(accounts[0])

    stakingVoteDelegator.toggleFunctionUnPause(stakingVoteDelegator.delegate.signature,{'from': stakingVoteDelegator.owner()})

    assert stakingV1_1.votingBalanceOfNow(accounts[0]) > vp0
    vp0 = stakingV1_1.votingBalanceOfNow(accounts[0])

    stakingVoteDelegator.delegate(accounts[0], {'from': proposer})
    chain.mine()
    assert stakingV1_1.votingBalanceOfNow(accounts[0]) == vp0






