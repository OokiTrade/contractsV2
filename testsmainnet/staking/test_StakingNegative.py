#!/usr/bin/python3

import pytest

from brownie import network, Contract, Wei, reverts


@pytest.fixture(scope="module")
def requireMainnetFork():
    assert network.show_active() == "mainnet-fork"


@pytest.fixture(scope="module")
def setFeesController(bzx, stakingV1):
    bzx.setFeesController(stakingV1, {"from": bzx.owner()})


@pytest.fixture(scope="module")
def vBZRX(accounts, TestToken):
    vBZRX = loadContractFromAbi(
        "0xb72b31907c1c95f3650b64b2469e08edacee5e8f", "vBZRX", TestToken.abi)
    vBZRX.transfer(accounts[0], 1000*10**18, {'from': vBZRX.address})
    return vBZRX


@pytest.fixture(scope="module")
def BZRX(accounts, TestToken):
    BZRX = loadContractFromAbi(
        "0x56d811088235F11C8920698a204A5010a788f4b3", "BZRX", TestToken.abi)
    BZRX.transfer(accounts[0], 1000*10**18, {'from': BZRX.address})
    return BZRX


@pytest.fixture(scope="module")
def iBZRX(accounts, BZRX, LoanTokenLogicStandard):
    iBZRX = loadContractFromAbi(
        "0x18240BD9C07fA6156Ce3F3f61921cC82b2619157", "iBZRX", LoanTokenLogicStandard.abi)

    BZRX.approve(iBZRX, 10*10**50, {'from': accounts[0]})
    iBZRX.mint(accounts[0], 100*10**18, {'from': accounts[0]})
    return iBZRX

def loadContractFromAbi(address, alias, abi):
    try:
        return Contract(alias)
    except ValueError:
        contract = Contract.from_abi(alias, address=address, abi=abi)
        return contract

# def loadContractFromEtherscan(address, alias):
#     try:
#         return Contract(alias)
#     except ValueError:
#         contract = Contract.from_explorer(address)
#         contract.set_alias(alias)
#         return contract


def testStakeCountMismatch(requireMainnetFork, stakingV1, bzx, setFeesController, BZRX, vBZRX, iBZRX):
    with reverts("count mismatch"):
        stakingV1.stake([BZRX], [1, 2])


def testUnStakeCountMismatch(requireMainnetFork, stakingV1, bzx, setFeesController, BZRX, vBZRX, iBZRX):
    with reverts("count mismatch"):
        stakingV1.unstake([BZRX], [1, 2])


def testStakeInvalidToken(requireMainnetFork, stakingV1, bzx, setFeesController, BZRX, vBZRX, iBZRX):
    with reverts("count mismatch"):
        stakingV1.stake([stakingV1], [1, 2])



def testStake_UnStake_NothingStaked(requireMainnetFork, stakingV1, bzx, setFeesController, BZRX, vBZRX, iBZRX, accounts):
    # tx =
    # tx.info()
    balanceOfBZRX = BZRX.balanceOf(accounts[0])
    balanceOfvBZRX = vBZRX.balanceOf(accounts[0])
    balanceOfiBZRX = iBZRX.balanceOf(accounts[0])

    BZRX.approve(stakingV1, 2 * balanceOfBZRX, {'from': accounts[0]})
    vBZRX.approve(stakingV1, 2 * balanceOfvBZRX, {'from': accounts[0]})
    iBZRX.approve(stakingV1, 2 * balanceOfiBZRX, {'from': accounts[0]})
    tokens = [BZRX, vBZRX, iBZRX]
    amounts = [balanceOfBZRX, balanceOfvBZRX, balanceOfiBZRX]

    tx = stakingV1.unstake(tokens, amounts)

    assert(len(tx.events) == 0)
    assert True