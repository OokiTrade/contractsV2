#!/usr/bin/python3

import pytest
from brownie import network, Contract, Wei, chain, reverts
import time


@pytest.fixture(scope="module")
def requireMainnetFork():
    assert (network.show_active() == "mainnet-fork" or network.show_active() == "mainnet-fork-alchemy")


def resetdelegators(VOTE_DELEGATOR, acct):
    VOTE_DELEGATOR.delegate(ZERO_ADDRESS, {'from': acct})
    chain.mine(10)

def mint_ooki(OOKI,STAKINGv2, acct, amount, stake):
    if amount>0:
        OOKI.mint(acct, amount, {"from": OOKI.owner()})

    OOKI.approve(STAKINGv2, 2**256-1, {'from': acct})
    if stake:
        STAKINGv2.stake([OOKI], [OOKI.balanceOf(acct)], {'from': acct})

    chain.mine(10)

PROPOSER = "0xfedc4dd5247b93feb41e899a09c44cfabec29cbc"
ZERO_ADDRESS="0x0000000000000000000000000000000000000000"
def testStake_VoteDelegateWF1(requireMainnetFork, STAKINGv2, DAO,  TIMELOCK, accounts,VOTE_DELEGATOR, OOKI, iUSDC, vBZRX, BZX):
    acct1 = accounts[0]
    acct2 = accounts[1]
    acct3 = accounts[3]
    DAO.__setProposalThresholdPercentage(1e18, {'from': TIMELOCK})
    assert int(DAO.proposalThreshold()/1e19) == int(OOKI.totalSupply() * 0.01/1e19)
    mint_ooki(OOKI,STAKINGv2, acct1,  60000000 * 1e18, True)
    mint_ooki(OOKI,STAKINGv2, acct2,  60000000 * 1e18, True)
    mint_ooki(OOKI,STAKINGv2, acct3,  0, False)
    OOKI.approve(STAKINGv2, 2**256-1, {'from': PROPOSER})
    STAKINGv2.stake([OOKI], [OOKI.balanceOf(PROPOSER)], {'from': PROPOSER})
    chain.mine()
    vb1 = STAKINGv2.votingBalanceOfNow(acct1)
    vb2 = STAKINGv2.votingBalanceOfNow(acct2)
    vb3 = STAKINGv2.votingBalanceOfNow(acct3)
    VOTE_DELEGATOR.delegate(acct3, {'from': acct1})
    time.sleep(3)
    chain.mine(10)
    assert STAKINGv2.votingBalanceOfNow(acct1) == 0
    assert STAKINGv2.votingBalanceOfNow(acct3) == vb1
    assert STAKINGv2.votingBalanceOfNow(acct2) == vb2
    VOTE_DELEGATOR.delegate(acct3, {'from': acct2})
    time.sleep(3)
    chain.mine(10)
    assert STAKINGv2.votingBalanceOfNow(acct1) == 0
    assert STAKINGv2.votingBalanceOfNow(acct3) == vb1+vb2
    assert STAKINGv2.votingBalanceOfNow(acct2) == 0

    STAKINGv2.unstake([OOKI], [1000e18], {'from': acct1})
    chain.mine(10)
    assert STAKINGv2.votingBalanceOfNow(acct3) == vb1+vb2-1000e18

    DAO.propose([iUSDC.address],[0],[""],[""],"asdf", {"from": PROPOSER})
    proposalId = DAO.proposalCount()
    proposal = DAO.proposals(DAO.proposalCount())

    chain.mine(proposal[3] - chain.height +1)
    vp1 = STAKINGv2.votingBalanceOf(acct3, proposalId)
    STAKINGv2.unstake([OOKI], [100e18], {'from': acct1})
    chain.mine(10)
    assert STAKINGv2.votingBalanceOf(acct3, proposalId) == vp1
    VOTE_DELEGATOR.delegate(ZERO_ADDRESS, {'from': acct1})
    VOTE_DELEGATOR.delegate(ZERO_ADDRESS, {'from': acct2})
    chain.mine(10)
    assert STAKINGv2.votingBalanceOfNow(acct1) > 0
    assert STAKINGv2.votingBalanceOfNow(acct3) == 0
    assert STAKINGv2.votingBalanceOf(acct3, proposalId) == vp1
    VOTE_DELEGATOR.delegate(acct3, {'from': PROPOSER})
    chain.mine(10)
    assert STAKINGv2.votingBalanceOfNow(PROPOSER) == 0
    assert STAKINGv2.votingBalanceOfNow(acct3) > 0
    assert STAKINGv2.votingBalanceOf(acct3, proposalId) == vp1
    DAO.cancel(proposalId, {"from": acct3})
    assert True

def testStake_VoteDelegateCreateProposal(requireMainnetFork, STAKINGv2, DAO, accounts,VOTE_DELEGATOR, OOKI, iUSDC):
    acct1 = accounts[0]
    acct2 = accounts[1]
    acct3 = accounts[3]
    mint_ooki(OOKI,STAKINGv2, acct1,  60000000 * 1e18, True)
    mint_ooki(OOKI,STAKINGv2, acct2,  60000000 * 1e18, True)
    mint_ooki(OOKI,STAKINGv2, acct3,  0, False)
    OOKI.approve(STAKINGv2, 2**256-1, {'from': PROPOSER})
    STAKINGv2.stake([OOKI], [OOKI.balanceOf(PROPOSER)], {'from': PROPOSER})

    STAKINGv2.unstake([OOKI], [1000e18], {'from': PROPOSER})
    time.sleep(3)
    chain.mine(10)

    vp1 = STAKINGv2.votingBalanceOfNow(PROPOSER)
    VOTE_DELEGATOR.delegate(acct3, {'from': PROPOSER})
    chain.mine(10)
    assert STAKINGv2.votingBalanceOfNow(PROPOSER) == 0
    assert STAKINGv2.votingBalanceOfNow(acct3) >= vp1
    chain.mine(10)

    with reverts("GovernorBravo::propose: proposer votes below proposal threshold"):
        DAO.propose([iUSDC.address],[0],[""],[""],"asdf", {"from": PROPOSER})

    DAO.propose([iUSDC.address],[0],[""],[""],"asdf", {"from": acct3})
    proposalId = DAO.proposalCount()
    DAO.cancel(proposalId, {"from":acct3})
    assert True

def testStake_VoteDelegateCancel(requireMainnetFork, STAKINGv2, DAO,accounts,VOTE_DELEGATOR, OOKI, iUSDC):
    acct1 = accounts[0]
    acct2 = accounts[1]
    acct3 = accounts[3]
    mint_ooki(OOKI,STAKINGv2, acct1,  60000000 * 1e18, True)
    mint_ooki(OOKI,STAKINGv2, acct2,  60000000 * 1e18, True)
    mint_ooki(OOKI,STAKINGv2, acct3,  0, False)
    OOKI.approve(STAKINGv2, 2**256-1, {'from': PROPOSER})
    STAKINGv2.stake([OOKI], [OOKI.balanceOf(PROPOSER)], {'from': PROPOSER})

    time.sleep(3)
    chain.mine(10)

    VOTE_DELEGATOR.delegate(acct3, {'from': acct1})
    chain.mine(10)
    DAO.propose([iUSDC.address],[0],[""],[""],"asdf", {"from": acct3})
    proposalId = DAO.proposalCount()
    proposal = DAO.proposals(DAO.proposalCount())

    with reverts("GovernorBravo::cancel: proposer above threshold"):
        DAO.cancel(proposalId,{'from': acct2})

    unstakeAmount =  STAKINGv2.balanceOfByAsset(OOKI, PROPOSER) - 1e24
    STAKINGv2.unstake([OOKI], [unstakeAmount], {'from': PROPOSER})
    VOTE_DELEGATOR.delegate(ZERO_ADDRESS, {'from': acct1})
    chain.mine(10)
    DAO.cancel(proposalId,{'from': acct3})
    assert DAO.proposals(DAO.proposalCount())[8] == True
    assert True


def testStake_VoteDelegate2Delegates0(requireMainnetFork, STAKINGv2, DAO, accounts,VOTE_DELEGATOR, OOKI):
    acct1 = accounts[0]
    acct2 = accounts[1]
    acct3 = accounts[3]
    mint_ooki(OOKI,STAKINGv2, acct1,  60000000 * 1e18, True)
    mint_ooki(OOKI,STAKINGv2, acct2,  60000000 * 1e18, True)
    mint_ooki(OOKI,STAKINGv2, acct3,  0, False)
    OOKI.approve(STAKINGv2, 2**256-1, {'from': PROPOSER})
    STAKINGv2.stake([OOKI], [OOKI.balanceOf(PROPOSER)], {'from': PROPOSER})
    time.sleep(3)
    chain.mine(10)
    vp1 = STAKINGv2.votingBalanceOfNow(acct1)
    vp2 = STAKINGv2.votingBalanceOfNow(PROPOSER)

    VOTE_DELEGATOR.delegate(acct1, {'from': PROPOSER})
    VOTE_DELEGATOR.delegate(acct3, {'from': acct1})
    chain.mine(10)
    assert STAKINGv2.votingBalanceOfNow(PROPOSER) == 0
    assert int(STAKINGv2.votingBalanceOfNow(acct1) / vp2 * 10000) == 10000
    assert int(STAKINGv2.votingBalanceOfNow(acct3) / vp1 * 10000) == 10000
    assert True


def testStake_VoteDelegateClaim0(requireMainnetFork, STAKINGv2, DAO, accounts,VOTE_DELEGATOR, OOKI, vBZRX):
    acct1 = accounts[0]
    acct2 = accounts[1]
    acct3 = accounts[3]
    vBZRX.approve(STAKINGv2, 2**256-1, {'from': acct1})
    vBZRX.approve(STAKINGv2, 2**256-1, {'from': acct2})
    vBZRX.transferFrom("0xe95Ebce2B02Ee07dEF5Ed6B53289801F7Fc137A4", acct1, 10000 *
                       1e18, {"from": "0xe95Ebce2B02Ee07dEF5Ed6B53289801F7Fc137A4"})
    vBZRX.transferFrom("0xe95Ebce2B02Ee07dEF5Ed6B53289801F7Fc137A4", acct2, 10000 *
                      1e18, {"from": "0xe95Ebce2B02Ee07dEF5Ed6B53289801F7Fc137A4"})

    STAKINGv2.stake([vBZRX], [vBZRX.balanceOf(acct1)], {'from': acct1})
    STAKINGv2.stake([vBZRX], [vBZRX.balanceOf(acct2)], {'from': acct2})
    time.sleep(3)
    chain.mine(20)
    vp1 = STAKINGv2.votingBalanceOfNow(acct1)
    vp2 = STAKINGv2.votingBalanceOfNow(acct2)
    cliffDuration = 15768000
    vestingDuration = 126144000
    vestingStartTimestamp = 1594648800
    vestingCliffTimestamp = vestingStartTimestamp + cliffDuration
    vestingEndTimestamp = vestingStartTimestamp + vestingDuration
    assert int(10000 * 1e18 *10 * (vestingEndTimestamp-chain.time())/(vestingEndTimestamp-vestingCliffTimestamp)/1e19) ==  int(vp1/1e19)
    assert vp1>0 and vp2>0
    VOTE_DELEGATOR.delegate(acct3, {'from': acct2})
    VOTE_DELEGATOR.delegate(acct3, {'from': acct1})
    chain.mine(10)

    vp0 = STAKINGv2.votingBalanceOfNow(acct3)
    assert int(vp0 / (vp1 + vp2) * 10000) == 10000
    STAKINGv2.claim(False, {'from': acct2})

    chain.mine(10)
    vp00 = STAKINGv2.votingBalanceOfNow(acct3);
    assert vp0 > vp00

    STAKINGv2.unstake([OOKI], [100e18], {'from': acct1})
    STAKINGv2.claim(True, {'from': acct1})
    chain.mine(10)
    vp01 = STAKINGv2.votingBalanceOfNow(acct3);
    assert vp00 <= vp01

    assert True


def testStake_VoteDelegatePause(requireMainnetFork, STAKINGv2, DAO, accounts,VOTE_DELEGATOR, OOKI):

    acct1 = accounts[0]
    acct2 = accounts[1]
    acct3 = accounts[3]
    mint_ooki(OOKI,STAKINGv2, acct1,  60000000 * 1e18, True)
    mint_ooki(OOKI,STAKINGv2, acct2,  60000000 * 1e18, True)
    mint_ooki(OOKI,STAKINGv2, acct3,  0, False)
    OOKI.approve(STAKINGv2, 2**256-1, {'from': PROPOSER})
    STAKINGv2.stake([OOKI], [OOKI.balanceOf(PROPOSER)], {'from': PROPOSER})
    time.sleep(3)
    chain.mine(10)

    vp1 = STAKINGv2.votingBalanceOfNow(acct1)
    vp2 = STAKINGv2.votingBalanceOfNow(PROPOSER)
    assert vp1>0 and vp2>0

    VOTE_DELEGATOR.delegate(acct3, {'from': acct1})
    VOTE_DELEGATOR.delegate(acct3, {'from': PROPOSER})
    chain.mine(10)
    vp0 = STAKINGv2.votingBalanceOfNow(acct3)
    assert int(vp0 / (vp1 + vp2) * 10000) == 10000

    nbCheckpoint0 = VOTE_DELEGATOR.numCheckpoints(acct3)
    checkpoint0 = VOTE_DELEGATOR.checkpoints(acct3,nbCheckpoint0-1)[1]
    VOTE_DELEGATOR.delegate(ZERO_ADDRESS, {'from': acct1})

    VOTE_DELEGATOR.toggleFunctionPause(VOTE_DELEGATOR.delegate.signature,{'from': VOTE_DELEGATOR.owner()})
    with reverts("paused"):
        VOTE_DELEGATOR.delegate(acct3, {'from': PROPOSER})

    chain.mine(3)
    assert STAKINGv2.votingBalanceOfNow(acct3) == 0
    assert int(STAKINGv2.votingBalanceOfNow(acct1)) == vp1
    assert int(STAKINGv2.votingBalanceOfNow(PROPOSER)) == vp2

    STAKINGv2.unstake([OOKI], [10000e18], {'from': acct1})
    time.sleep(3)
    chain.mine(10)
    assert int(STAKINGv2.votingBalanceOfNow(PROPOSER) / (vp2 - 10000e18) * 10000) == 10000
    STAKINGv2.claim(False, {'from': PROPOSER})
    chain.mine(10)

    nbCheckpoint1 = VOTE_DELEGATOR.numCheckpoints(acct3)
    checkpoint1 = VOTE_DELEGATOR.checkpoints(acct3,nbCheckpoint1-1)[1]

    assert nbCheckpoint1>nbCheckpoint0
    assert checkpoint0 - checkpoint1 > 10000e18
    VOTE_DELEGATOR.toggleFunctionUnPause(VOTE_DELEGATOR.delegate.signature,{'from': VOTE_DELEGATOR.owner()})
    assert STAKINGv2.votingBalanceOfNow(acct3) > 0
    VOTE_DELEGATOR.delegate(acct3, {'from': acct1})
    chain.mine(10)
    assert STAKINGv2.votingBalanceOfNow(acct3) > 0
    assert STAKINGv2.votingBalanceOfNow(acct1) == 0
    assert STAKINGv2.votingBalanceOfNow(PROPOSER) == 0



def testStake_VoteDelegateFullWF(requireMainnetFork,  STAKINGv2, DAO,  accounts,VOTE_DELEGATOR, OOKI, iUSDC, vBZRX, BZX, TOKEN_SETTINGS):
    acct1 = accounts[0]
    acct2 = accounts[1]
    acct3 = accounts[3]
    mint_ooki(OOKI,STAKINGv2, acct1,  60000000 * 1e18, True)
    mint_ooki(OOKI,STAKINGv2, acct2,  60000000 * 1e18, True)
    mint_ooki(OOKI,STAKINGv2, acct3,  60000000 * 1e18, True)
    newName = iUSDC.name() + "1"
    calldata = TOKEN_SETTINGS.initialize.encode_input(iUSDC.loanTokenAddress(), newName, iUSDC.symbol())
    calldata2 = iUSDC.updateSettings.encode_input(TOKEN_SETTINGS, calldata)

    tx = DAO.propose([iUSDC.address],[0],[""],[calldata2],"asdf", {"from": acct1})
    proposalId = DAO.proposalCount()
    proposal = DAO.proposals(DAO.proposalCount())

    id = proposal[0]
    eta = proposal[2]
    startBlock = proposal[3]
    endBlock = proposal[4]
    forVotes = proposal[5]
    againstVotes = proposal[6]
    abstainVotes = proposal[7]
    canceled = proposal[8]
    assert DAO.state.call(id) == 0
    chain.mine()
    chain.mine(startBlock - chain.height)

    # after first vote state is active
    tx = DAO.castVote(id,1, {"from" : acct2})
    assert DAO.state.call(id) == 1
    tx = DAO.castVote(id,1, {"from" : acct1})
    chain.mine(endBlock - chain.height)
    assert DAO.state.call(id) == 1
    chain.mine()
    assert DAO.state.call(id) == 4

    DAO.queue(id, {"from" : acct3})

    proposal = DAO.proposals(proposalId)
    eta = proposal[2]
    chain.sleep(eta - chain.time())
    chain.mine()

    tx = DAO.execute(id, {"from" : acct3})
    chain.mine()
    assert iUSDC.name() == newName
    assert True

    def testStake_VoteDelegateFullWF(requireMainnetFork,  STAKINGv2, DAO,  accounts,VOTE_DELEGATOR, OOKI, iUSDC, vBZRX, BZX, TOKEN_SETTINGS):
        acct1 = accounts[0]
    acct2 = accounts[1]
    acct3 = accounts[3]
    mint_ooki(OOKI,STAKINGv2, acct1,  60000000 * 1e18, True)
    mint_ooki(OOKI,STAKINGv2, acct2,  60000000 * 1e18, True)
    mint_ooki(OOKI,STAKINGv2, acct3,  60000000 * 1e18, True)
    VOTE_DELEGATOR.delegate(acct3, {'from': acct1})
    newName = iUSDC.name() + "1"
    calldata = TOKEN_SETTINGS.initialize.encode_input(iUSDC.loanTokenAddress(), newName, iUSDC.symbol())
    calldata2 = iUSDC.updateSettings.encode_input(TOKEN_SETTINGS, calldata)

    tx = DAO.propose([iUSDC.address],[0],[""],[calldata2],"asdf", {"from": acct3})
    proposalId = DAO.proposalCount()
    proposal = DAO.proposals(DAO.proposalCount())

    id = proposal[0]
    eta = proposal[2]
    startBlock = proposal[3]
    endBlock = proposal[4]
    assert DAO.state.call(id) == 0
    chain.mine()
    chain.mine(startBlock - chain.height)

    # after first vote state is active
    tx = DAO.castVote(id,1, {"from" : acct2})
    assert DAO.state.call(id) == 1
    chain.mine()
    assert DAO.state.call(id) != 4
    with reverts("GovernorBravo::queue: proposal can only be queued if it is succeeded"):
        DAO.queue(id, {"from" : acct3})
    assert True