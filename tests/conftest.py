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
def FuncSigs():
    return {
        "ProtocolSettings": {
            "setCoreParams": "setCoreParams(address,address,address,uint256)",
            "setProtocolManagers": "setProtocolManagers(address[],bool[])",
            "setLoanPools": "setLoanPools(address[],address[])",
            "getloanPoolsList": "getloanPoolsList(uint256,uint256)",
        },
        "LoanSettings": {
            "setupLoanParams": "setupLoanParams((bytes32,bool,address,address,address,uint256,uint256,uint256)[])",
            "disableLoanParams": "disableLoanParams(bytes32[])",
            "getLoanParams": "getLoanParams(bytes32)",
            "getLoanParamsBatch": "getLoanParamsBatch(bytes32[])",
            "getTotalPrincipal": "getTotalPrincipal(address,address)",
            "setupOrder": "setupOrder((bytes32,bool,address,address,address,uint256,uint256,uint256),uint256,uint256,uint256,uint256,uint256,bool)",
            "setupOrderWithId": "setupOrderWithId(bytes32,uint256,uint256,uint256,uint256,uint256,bool)",
            "depositToOrder": "depositToOrder(bytes32,uint256,bool)",
            "withdrawFromOrder": "withdrawFromOrder(bytes32,uint256,bool)",
        },
        "LoanOpenings": {
            "borrow": "borrow(bytes32,bytes32,uint256,uint256,address,address,address)",
            "borrowOrTradeFromPool": "borrowOrTradeFromPool(bytes32,bytes32,bool,address[4],uint256[5],bytes)",
            "setDelegatedManager": "setDelegatedManager(bytes32,address,bool)",
            "getRequiredCollateral": "getRequiredCollateral(address,address,uint256,uint256,bool)",
            "getBorrowAmount": "getBorrowAmount(address,address,uint256,uint256)",
        },
        "LoanClosings": {
        },
        "LoanMaintenance": {
            "extendLoanByInterest": "extendLoanByInterest(bytes32,address,uint256,bool,bytes)",
            "reduceLoanByInterest": "reduceLoanByInterest(bytes32,address,address,uint256)",
            "getUserLoans": "getUserLoans(address,uint256,uint256,uint256,bool,bool)",
            "getLoan": "getLoan(bytes32)",
            "getActiveLoans": "getActiveLoans(uint256,uint256,bool)",
        },
        "SwapsExternal": {
            "swapExternal": "swapExternal(address,address,address,address,uint256,uint256,uint256,bytes)",
            "setSupportedSwapTokensBatch": "setSupportedSwapTokensBatch(address[],bool[])",
            "getExpectedSwapRate": "getExpectedSwapRate(address,address,uint256)",
        },
    }

@pytest.fixture(scope="module")
def bzxproxy(bZxProtocol, accounts):
    return accounts[0].deploy(bZxProtocol)

@pytest.fixture(scope="module")
def bzx(accounts, bzxproxy, interface):
    c = Contract.from_abi("bzx", address=bzxproxy.address, abi=interface.IBZx.abi, owner=accounts[0])
    _add_contract(c)
    return c

@pytest.fixture(scope="module")
def priceFeeds(accounts, WETH, DAI, LINK, PriceFeeds, PriceFeeds_local):
    if network.show_active() == "development":
        feeds = accounts[0].deploy(PriceFeeds_local)

        feeds.setRates(
            WETH.address,
            LINK.address,
            54.52e18
        )
        feeds.setRates(
            WETH.address,
            DAI.address,
            200e18
        )
        feeds.setRates(
            LINK.address,
            DAI.address,
            3.692e18
        )
    else:
        feeds = accounts[0].deploy(PriceFeeds)
        #feeds.setPriceFeedsBatch(...)

    return feeds

@pytest.fixture(scope="module")
def swapsImpl(accounts, SwapsImplKyber, SwapsImplLocal):
    if network.show_active() == "development":
        feeds = accounts[0].deploy(SwapsImplLocal)
    else:
        feeds = accounts[0].deploy(SwapsImplKyber)
        #feeds.setPriceFeedsBatch(...)

    return feeds

@pytest.fixture(scope="module", autouse=True)
def settings(Constants, ProtocolSettings, priceFeeds, FuncSigs, accounts, bzxproxy):

    settings = accounts[0].deploy(ProtocolSettings)

    sigs = []
    for s in FuncSigs["ProtocolSettings"].values():
        sigs.append(s)
    targets = [settings.address] * len(sigs)
    bzxproxy.setTargets(sigs, targets)

@pytest.fixture(scope="module", autouse=True)
def loanSettings(LoanSettings, FuncSigs, accounts, bzxproxy):

    loanSettings = accounts[0].deploy(LoanSettings)

    sigs = []
    for s in FuncSigs["LoanSettings"].values():
        sigs.append(s)
    targets = [loanSettings.address] * len(sigs)
    bzxproxy.setTargets(sigs, targets)

@pytest.fixture(scope="module", autouse=True)
def loanMaintenance(LoanMaintenance, FuncSigs, accounts, bzxproxy):

    loanMaintenance = accounts[0].deploy(LoanMaintenance)

    sigs = []
    for s in FuncSigs["LoanMaintenance"].values():
        sigs.append(s)
    targets = [loanMaintenance.address] * len(sigs)
    bzxproxy.setTargets(sigs, targets)

@pytest.fixture(scope="function", autouse=True)
def isolate(fn_isolation):
    pass

@pytest.fixture(scope="module", autouse=True)
def WETH(module_isolation, accounts, TestWeth):
    yield accounts[0].deploy(TestWeth) ## 0x3194cBDC3dbcd3E11a07892e7bA5c3394048Cc87
