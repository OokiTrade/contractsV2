#!/usr/bin/python3

import pytest
from brownie import *



@pytest.fixture(scope="module")
def requireMainnetFork():
    assert network.show_active() == "mainnet-fork"

@pytest.fixture(scope="module")
def setFeesController(bzx, stakingV1):
    bzx.setFeesController(stakingV1, {"from": bzx.owner()})



def testRepStakedTokensEvent(requireMainnetFork, stakingV1, bzx, setFeesController):
    assert False

def testStakedEvent(requireMainnetFork):
    assert False

def testUnstakedEvent(requireMainnetFork):
    assert False

def testRewardAddedEvent(requireMainnetFork):
    assert False


def testRewardPaidEvent(requireMainnetFork):
    assert False

def testDelegateChangedEvent(requireMainnetFork):
    assert False