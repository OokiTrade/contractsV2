#!/usr/bin/python3

import pytest
from brownie import Contract, network
from brownie.network.contract import InterfaceContainer
from brownie.network.state import _add_contract, _remove_contract

@pytest.fixture(scope="module")
def Constants():
    return {
        "ZERO_ADDRESS": "0x0000000000000000000000000000000000000000",
        "ONE_ADDRESS": "0x0000000000000000000000000000000000000001",
        "MAX_UINT": "0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff"
    }

@pytest.fixture(scope="module")
def DAI(accounts, TestToken):
    return accounts[0].deploy(TestToken, "DAI", "DAI", 18, 1e50)

@pytest.fixture(scope="module")
def LINK(accounts, TestToken):
    return accounts[0].deploy(TestToken, "LINK", "LINK", 18, 1e50)

@pytest.fixture(scope="module")
def WETH(accounts, TestToken, TestWeth):
    return accounts[0].deploy(TestWeth)

@pytest.fixture(scope="module")
def priceFeeds(accounts, WETH, DAI, LINK, PriceFeeds, PriceFeedsLocal):
    feeds = accounts[0].deploy(PriceFeedsLocal)

    feeds.setRates(
        WETH.address,
        LINK.address,
        50e18 # this value so it can be easy in manual calculations
    )
    feeds.setRates(
        WETH.address,
        DAI.address,
        150e18 # this value so it can be easy in manual calculations
    )
    feeds.setRates(
        LINK.address,
        DAI.address,
        10e18 # this value so it can be easy in manual calculations
    )
    return feeds

@pytest.fixture(scope="module")
def swapsImpl(accounts, SwapsImplKyber, SwapsImplTestnets):
    return accounts[0].deploy(SwapsImplTestnets)

@pytest.fixture(scope="module", autouse=True)
def bzx(accounts, 
    interface, 
    bZxProtocol, 
    ProtocolSettings, 
    LoanSettings, 
    LoanMaintenance, 
    LoanOpenings, 
    LoanClosings,
    LoanClosingsWithGasToken,
    swapsImpl, 
    priceFeeds):
    bzxproxy = accounts[0].deploy(bZxProtocol)
    bzx = Contract.from_abi("bzx", address=bzxproxy.address, abi=interface.IBZx.abi, owner=accounts[0])
    _add_contract(bzx)
    
    bzx.replaceContract(accounts[0].deploy(ProtocolSettings).address)
    bzx.replaceContract(accounts[0].deploy(LoanSettings).address)
    bzx.replaceContract(accounts[0].deploy(LoanMaintenance).address)
    bzx.replaceContract(accounts[0].deploy(LoanOpenings).address)
    bzx.replaceContract(accounts[0].deploy(LoanClosings).address)
    # bzx.replaceContract(accounts[0].deploy(LoanClosingsWithGasToken).address) disable for now so that coverage works

    bzx.setPriceFeedContract(
        priceFeeds.address # priceFeeds
    )

    bzx.setSwapsImplContract(
        swapsImpl.address # swapsImpl
    )
    
    return bzx

@pytest.fixture(scope="function", autouse=True)
def isolate(fn_isolation):
    pass
