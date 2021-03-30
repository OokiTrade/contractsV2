import pytest
from brownie import Contract, network, reverts

INITIAL_LP_TOKEN_ACCOUNT_AMOUNT = 100 * 10 ** 18;

@pytest.fixture(scope="module")
def requireMainnetFork():
    assert (network.show_active() == "mainnet-fork" or network.show_active() == "mainnet-fork-alchemy")

@pytest.fixture(scope="module")
def bzrx(accounts, interface):
    return Contract.from_abi("bzrx", address="0x56d811088235F11C8920698a204A5010a788f4b3", abi=interface.ERC20.abi, owner=accounts[0])

@pytest.fixture(scope="module")
def vbzrx(accounts, BZRXVestingToken):
    return  Contract.from_abi("bzrx", address="0xb72b31907c1c95f3650b64b2469e08edacee5e8f", abi=BZRXVestingToken.abi, owner=accounts[0])

@pytest.fixture(scope="module")
def wrapper(accounts, VBZRXWrapper):
    return  VBZRXWrapper.deploy({"from": accounts[0]})



vbzrxMajorAddress = "0x29dce6d3039644c66c456998de3bd723b141ff16";

def test_mainflow(requireMainnetFork, bzrx, vbzrx, chain, accounts, wrapper):
    account1 = accounts[1]
    account2 = accounts[2]
    vbzrxBalanceBefore = vbzrx.balanceOf(account1)
    bzrxBalanceBefore = bzrx.balanceOf(account1)
    tx1 = vbzrx.transfer(account1, INITIAL_LP_TOKEN_ACCOUNT_AMOUNT, {"from": vbzrxMajorAddress})
    vbzrxBalanceAfter = vbzrxBalanceBefore + INITIAL_LP_TOKEN_ACCOUNT_AMOUNT
    assert vbzrx.balanceOf(account1) == vbzrxBalanceAfter
    assert vbzrx.vestedBalanceOf(account1)  == 0
    assert bzrxBalanceBefore == 0
    chain.mine()

    vbzrx.approve(wrapper, vbzrx.balanceOf(account1), {"from": account1})
    depositAmount = vbzrx.balanceOf(account1);
    vestedBalance = vbzrx.vestedBalanceOf(account1);
    assert vestedBalance  > 0

    tx2 = wrapper.deposit(depositAmount, {"from": account1})
    assert vbzrx.vestedBalanceOf(account1)  == 0
    assert bzrx.balanceOf(account1)  >= vestedBalance
    assert bzrx.balanceOf(account1) > 0
    assert wrapper.claimable(account1) == 0
    chain.mine()
    assert wrapper.claimable(account1) > 0

    tx3 = wrapper.transfer(account2, depositAmount, {"from": account1})
    assert wrapper.balanceOf(account1)  == 0
    assert wrapper.balanceOf(account2) == INITIAL_LP_TOKEN_ACCOUNT_AMOUNT
    assert wrapper.claimable(account1) == 0
    assert wrapper.claimable(account2) > 0
    assert vbzrx.vestedBalanceOf(account2)  == 0
    assert vbzrx.vestedBalanceOf(account1)  == 0
    wrapper.claim({"from": account2});
    assert bzrx.balanceOf(account2)  > 0

    tx4 = wrapper.withdraw(depositAmount,  {"from": account2})
    assert vbzrx.balanceOf(account2) == INITIAL_LP_TOKEN_ACCOUNT_AMOUNT
    assert vbzrx.vestedBalanceOf(account2)  == 0
    chain.mine()
    assert vbzrx.vestedBalanceOf(account2)  > 0
    assert wrapper.claimable(account2) == 0


def test_exit(requireMainnetFork, bzrx, vbzrx, chain, accounts, wrapper):
    account1 = accounts[3]
    vbzrxBalanceBefore = vbzrx.balanceOf(account1)
    bzrxBalanceBefore = bzrx.balanceOf(account1)
    tx1 = vbzrx.transfer(account1, INITIAL_LP_TOKEN_ACCOUNT_AMOUNT, {"from": vbzrxMajorAddress})
    vbzrx.approve(wrapper, vbzrx.balanceOf(account1), {"from": account1})
    depositAmount = vbzrx.balanceOf(account1);
    tx2 = wrapper.deposit(depositAmount, {"from": account1})
    assert bzrx.balanceOf(account1) > 0
    assert vbzrx.balanceOf(account1) == 0
    assert wrapper.balanceOf(account1) == INITIAL_LP_TOKEN_ACCOUNT_AMOUNT
    chain.mine()
    bzrxBalanceBefore = bzrx.balanceOf(account1)
    tx3 = wrapper.exit({"from": account1})
    assert bzrx.balanceOf(account1) > bzrxBalanceBefore
    assert vbzrx.balanceOf(account1) == INITIAL_LP_TOKEN_ACCOUNT_AMOUNT
    assert wrapper.balanceOf(account1) == 0

def test_deposit_more_than_have(requireMainnetFork, vbzrx, accounts, wrapper):
    account1 = accounts[4]
    vbzrx.transfer(account1, INITIAL_LP_TOKEN_ACCOUNT_AMOUNT, {"from": vbzrxMajorAddress})
    vbzrx.approve(wrapper, vbzrx.balanceOf(account1)+1, {"from": account1})
    with reverts("insufficient-balance"):
        wrapper.deposit(vbzrx.balanceOf(account1)+1, {"from": account1})

def test_deposit_more_than_approved(requireMainnetFork, vbzrx, accounts, wrapper):
    account1 = accounts[4]
    vbzrx.transfer(account1, INITIAL_LP_TOKEN_ACCOUNT_AMOUNT, {"from": vbzrxMajorAddress})
    vbzrx.approve(wrapper, vbzrx.balanceOf(account1)-1, {"from": account1})
    with reverts("insufficient-allowance"):
        wrapper.deposit(vbzrx.balanceOf(account1), {"from": account1})


#TODO events