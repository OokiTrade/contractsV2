#!/usr/bin/python3

import pytest
from brownie import *



@pytest.fixture(scope="module")
def requireMainnetFork():
    assert network.show_active() == "mainnet-fork"

@pytest.fixture(scope="module")
def setFeesController(bzx, stakingV1):
    bzx.setFeesController(stakingV1, {"from": bzx.owner()})


