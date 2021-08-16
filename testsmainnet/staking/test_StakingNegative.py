#!/usr/bin/python3

import pytest

from brownie import network, Contract, Wei, reverts


@pytest.fixture(scope="module")
def requireMainnetFork():
    assert (network.show_active() == "mainnet-fork" or network.show_active() == "mainnet-fork-alchemy")


def testStakeCountMismatch(requireMainnetFork, stakingV1_1, bzx, BZRX, vBZRX, iBZRX):
    with reverts("count mismatch"):
        stakingV1_1.stake([BZRX], [1, 2])


def testUnStakeCountMismatch(requireMainnetFork, stakingV1_1, bzx, BZRX, vBZRX, iBZRX):
    with reverts("count mismatch"):
        stakingV1_1.unstake([BZRX], [1, 2])


def testStakeInvalidToken(requireMainnetFork, stakingV1_1, bzx, BZRX, vBZRX, iBZRX):
    with reverts("count mismatch"):
        stakingV1_1.stake([stakingV1_1], [1, 2])



def testStake_UnStake_NothingStaked(requireMainnetFork, stakingV1_1, bzx, BZRX, vBZRX, iBZRX, accounts):
    # tx =
    # tx.info()
    balanceOfBZRX = BZRX.balanceOf(accounts[0])
    balanceOfvBZRX = vBZRX.balanceOf(accounts[0])
    balanceOfiBZRX = iBZRX.balanceOf(accounts[0])

    BZRX.approve(stakingV1_1, 2 * balanceOfBZRX, {'from': accounts[0]})
    vBZRX.approve(stakingV1_1, 2 * balanceOfvBZRX, {'from': accounts[0]})
    iBZRX.approve(stakingV1_1, 2 * balanceOfiBZRX, {'from': accounts[0]})
    tokens = [BZRX, vBZRX, iBZRX]
    amounts = [balanceOfBZRX, balanceOfvBZRX, balanceOfiBZRX]

    tx = stakingV1_1.unstake(tokens, amounts)

    assert(len(tx.events) == 0)
    assert True


def testStake_StakeOld(requireMainnetFork, stakingV1_1, bzx, BZRX, vBZRX, iBZRX, LPT_OLD, accounts):

    LPT_OLD.transfer(accounts[1], 1e18, { 'from': "0xe95ebce2b02ee07def5ed6b53289801f7fc137a4"})

    balanceOfBZRX = BZRX.balanceOf(accounts[1])
    balanceOfvBZRX = vBZRX.balanceOf(accounts[1])
    balanceOfiBZRX = iBZRX.balanceOf(accounts[1])
    balanceOfLPT = LPT_OLD.balanceOf(accounts[1])

    BZRX.approve(stakingV1_1, balanceOfBZRX, {'from': accounts[1]})
    vBZRX.approve(stakingV1_1, balanceOfvBZRX, {'from': accounts[1]})
    iBZRX.approve(stakingV1_1, balanceOfiBZRX, {'from': accounts[1]})
    LPT_OLD.approve(stakingV1_1, balanceOfLPT, {'from': accounts[1]})

    tokens = [LPT_OLD]
    amounts = [1]
    with reverts("invalid token"):
        tx = stakingV1_1.stake(tokens, amounts, {'from': accounts[1]})

