from brownie import *
import pytest

@pytest.fixture(scope="module")
def BZX(interface):
    return interface.IBZx("0x059D60a9CEfBc70b9Ea9FFBb9a041581B1dFA6a8")

@pytest.fixture(scope="module")
def WMATIC(interface):
    return interface.IERC20("0x0d500B1d8E8eF31E21C99d1Db9A6444d3ADf1270")

@pytest.fixture(scope="module")
def USDC(interface):
    return interface.IERC20("0x2791Bca1f2de4661ED88A30C99A7a9449Aa84174")

@pytest.fixture(scope="module")
def upgrade(BZX, SwapsExternal, VolumeTracker):
    accounts[0].deploy(VolumeTracker)
    se = SwapsExternal.deploy({"from":accounts[0]})
    BZX.replaceContract(se, {"from":BZX.owner()})

def test_case_exact_amount_out(accounts, BZX, upgrade, WMATIC, USDC):
    #get some WMATIC and approvals
    WMATIC.transfer(accounts[0], 2e18, {"from":"0xadbf1854e5883eb8aa7baf50705338739e558e5b"})
    WMATIC.approve(BZX, 0, {"from":accounts[0]})
    WMATIC.approve(BZX, 2e18, {"from":accounts[0]})

    prevBal = WMATIC.balanceOf(accounts[0])
    prevBalReceiving = USDC.balanceOf(accounts[0])
    receivedAmount, usedAmount = BZX.swapExternal(WMATIC, USDC, accounts[0], accounts[0], 1e18, 5e5, b'', {"from":accounts[0]}).return_value
    assert(receivedAmount == 5e5)
    assert(usedAmount < 1e18)
    assert(USDC.balanceOf(accounts[0])-prevBalReceiving == receivedAmount)
    assert(prevBal-WMATIC.balanceOf(accounts[0]) == usedAmount)

def test_case_exact_amount_in(accounts, BZX, upgrade, WMATIC, USDC):
    #get some WMATIC and approvals
    WMATIC.transfer(accounts[0], 2e18, {"from":"0xadbf1854e5883eb8aa7baf50705338739e558e5b"})
    WMATIC.approve(BZX, 0, {"from":accounts[0]})
    WMATIC.approve(BZX, 2e18, {"from":accounts[0]})

    prevBal = WMATIC.balanceOf(accounts[0])
    prevBalReceiving = USDC.balanceOf(accounts[0])
    receivedAmount, usedAmount = BZX.swapExternal(WMATIC, USDC, accounts[0], accounts[0], 1e18, 0, b'', {"from":accounts[0]}).return_value
    assert(usedAmount == 1e18)
    assert(USDC.balanceOf(accounts[0])-prevBalReceiving == receivedAmount)
    assert(prevBal-WMATIC.balanceOf(accounts[0]) == usedAmount)