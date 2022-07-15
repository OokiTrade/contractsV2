import pytest
from brownie import *
from brownie import reverts

@pytest.fixture(scope="module")
def buyback(BuyBackAndBurn, Proxy_0_8):
    bb = Contract.from_abi("BuyBack", "0x12EBd8263A54751Aaf9d8C2c74740A8e62C0AfBe", Proxy_0_8.abi)
    bb.replaceImplementation(accounts[0].deploy(BuyBackAndBurn), {"from":bb.owner()})
    return Contract.from_abi("BuyBack", "0x12EBd8263A54751Aaf9d8C2c74740A8e62C0AfBe", BuyBackAndBurn.abi)

def test_case1(buyback):
    #sets the settings
    buyback.settingsForTimeAllowance(600, 50e6, {"from":buyback.owner()})
    buyback.setApproval({"from":buyback.owner()})
    with reverts("too much spent"):
        buyback.buyBack(20e18, {"from":accounts[0]})

    buyback.buyBack(5e18, {"from":accounts[0]})