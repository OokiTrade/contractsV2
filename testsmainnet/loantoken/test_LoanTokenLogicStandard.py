#!/usr/bin/python3

import pytest
from brownie import network, Contract


@pytest.fixture(scope="module")
def requireMainnetFork():
    assert (network.show_active() == "mainnet-fork" or network.show_active() == "mainnet-fork-alchemy")


@pytest.fixture(scope="module")
def iDAI(accounts, LoanTokenLogicStandard):
    return Contract.from_abi("iDAI", address="0x6b093998d36f2c7f0cc359441fbb24cc629d5ff0",  abi=LoanTokenLogicStandard.abi, owner=accounts[0])


# def testMint(requireMainnetFork, iDAI, accounts):
#     tx = iDAI.mint(accounts[1], '1 ether')
#     tx.info();

#     assert False
