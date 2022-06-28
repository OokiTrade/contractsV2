#!/usr/bin/python3

import pytest
from brownie import ZERO_ADDRESS, network, Contract, reverts, chain
from brownie.convert.datatypes import Wei
from eth_abi import encode_abi, is_encodable, encode_single
from eth_abi.packed import encode_single_packed, encode_abi_packed
from hexbytes import HexBytes
import json
from eth_account import Account
from eth_account.messages import encode_structured_data
from eip712.messages import EIP712Message, EIP712Type
from brownie.network.account import LocalAccount
from brownie.convert.datatypes import *
from brownie import web3

@pytest.fixture(scope="module")
def requireFork():
    assert (network.show_active() == "fork" or "fork" in network.show_active())


@pytest.fixture(autouse=True)
def isolation(fn_isolation):
    pass


@pytest.fixture(scope="module")
def BZX(accounts, interface, TickMathV1, LoanOpenings, LoanSettings, ProtocolSettings, LoanClosingsLiquidation, LoanMaintenance, LiquidationHelper):
    tickMathV1 = accounts[0].deploy(TickMathV1)
    liquidationHelper = accounts[0].deploy(LiquidationHelper)

    lo = accounts[0].deploy(LoanOpenings)
    ls = accounts[0].deploy(LoanSettings)
    ps = accounts[0].deploy(ProtocolSettings)
    lcs = accounts[0].deploy(LoanClosingsLiquidation)
    lm = accounts[0].deploy(LoanMaintenance)

    bzx = Contract.from_abi("bzx", address="0xD8Ee69652E4e4838f2531732a46d1f7F584F0b7f", abi=interface.IBZx.abi)
    bzx.replaceContract(lo, {"from": bzx.owner()})
    bzx.replaceContract(ls, {"from": bzx.owner()})
    bzx.replaceContract(ps, {"from": bzx.owner()})
    bzx.replaceContract(lcs, {"from": bzx.owner()})
    bzx.replaceContract(lm, {"from": bzx.owner()})

    return bzx


@pytest.fixture(scope="module")
def USDT(accounts, TestToken):
    return Contract.from_abi("USDT", address="0xdAC17F958D2ee523a2206206994597C13D831ec7", abi=TestToken.abi)

@pytest.fixture(scope="module")
def USDC(accounts, TestToken):
    return Contract.from_abi("USDC", address="0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48", abi=TestToken.abi)

@pytest.fixture(scope="module")
def FRAX(accounts, TestToken):
    return Contract.from_abi("FRAX", address="0x853d955aCEf822Db058eb8505911ED77F175b99e", abi=TestToken.abi)

@pytest.fixture(scope="module")
def AAVE(accounts, TestToken):
    return Contract.from_abi("AAVE", address="0x7Fc66500c84A76Ad7e9c93437bFc5Ac33E2DDaE9", abi=TestToken.abi)

@pytest.fixture(scope="module")
def STETH(accounts, TestToken):
    return Contract.from_abi("STETH", address="0xae7ab96520DE3A18E5e111B5EaAb095312D7fE84", abi=TestToken.abi)

@pytest.fixture(scope="module")
def ALCX(accounts, TestToken):
    return Contract.from_abi("ALCX", address="0xdBdb4d16EdA451D0503b854CF79D55697F90c8DF", abi=TestToken.abi)


@pytest.fixture(scope="module")
def WETH(accounts, TestToken):
    return Contract.from_abi("USDT", address="0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2", abi=TestToken.abi)

@pytest.fixture(scope="module")
def PRICE_FEED(accounts, BZX, PriceFeeds):

    return Contract.from_abi("PRICE_FEED", BZX.priceFeeds(), abi = PriceFeeds.abi)
    # return Contract.from_abi("USDT", address="0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2", abi=TestToken.abi)


@pytest.fixture(scope="module")
def iUSDT(accounts, LoanTokenLogicStandard, interface):
    itokenImpl = accounts[0].deploy(LoanTokenLogicStandard)
    itoken = Contract.from_abi("iUSDT", address="0x7e9997a38A439b2be7ed9c9C4628391d3e055D48", abi=interface.IToken.abi)
    itoken.setTarget(itokenImpl, {"from": itoken.owner()})
    itoken.initializeDomainSeparator({"from": itoken.owner()})
    return itoken


@pytest.fixture(scope="module")
def iUSDC(accounts, interface):
    itoken = Contract.from_abi("iUSDC", address="0x32E4c68B3A4a813b710595AebA7f6B7604Ab9c15", abi=interface.IToken.abi)
    return itoken

@pytest.fixture(scope="module")
def GUARDIAN_MULTISIG():
    return "0x9B43a385E08EE3e4b402D4312dABD11296d09E93"

@pytest.fixture(scope="module")
def REGISTRY(accounts, TokenRegistry):
    return Contract.from_abi("REGISTRY", address="0xf0E474592B455579Fe580D610b846BdBb529C6F7",
                             abi=TokenRegistry.abi, owner=accounts[0])

def test_cases():
    # Test Case 1: check you can setup a working iToken using guardian only power
    # Test Case 2: check you can setup a new collateral using guardian only power
    # Test Case 3: check you can liquidate with new iToken
    # Test Case 4: check migrateLoanParamsList, after the migration new loanId should be working
    # Test Case 5: check getDefaultLoanParams all possible scenarios
    # Test Case 6: make sure you can't intentionally borrowOrTradeFromPool and create undexpected loanParam
    # Test Case 7: make sure guardian can create/updates existing loan params with specific settings
    # Test Case 8: test HELPER getBorrowAmount for deposit and vice versa
    # Test Case 9: mint/burn
    # Test Case 10: borrow with iToken
    # Test Case 11: marginTrade
    # Test Case 12: set iToken pricefeed
    assert True

def test_case1(accounts, BZX, USDC, USDT, iUSDT, iUSDC, REGISTRY, GUARDIAN_MULTISIG, FRAX, LoanTokenLogicStandard, LoanToken, CurvedInterestRate, PriceFeeds, PRICE_FEED, interface):
    underlyingSymbol = FRAX.symbol()
    iTokenSymbol = "i{}".format(underlyingSymbol.upper())
    iTokenName = "Ooki {} iToken ({})".format(underlyingSymbol, iTokenSymbol)
    
    loanTokenLogicStandard = LoanTokenLogicStandard.deploy({'from': GUARDIAN_MULTISIG})
    iTokenProxy = LoanToken.deploy(GUARDIAN_MULTISIG, loanTokenLogicStandard, {"from": GUARDIAN_MULTISIG})
    iToken = Contract.from_abi("iToken", address=iTokenProxy,abi=LoanTokenLogicStandard.abi, owner=GUARDIAN_MULTISIG)
    iToken.initialize(FRAX, iTokenName, iTokenSymbol, {"from": GUARDIAN_MULTISIG})
    iToken.initializeDomainSeparator({"from": GUARDIAN_MULTISIG})
    cui = CurvedInterestRate.deploy({'from': GUARDIAN_MULTISIG})
    iToken.setDemandCurve(cui, {'from': GUARDIAN_MULTISIG})

    
    # TODO migrate pricefeed to allow guardian to modify, deploy new pricefeed
    PRICE_FEED.setPriceFeed([FRAX], ['0x14d04Fff8D21bd62987a5cE9ce543d2F1edF5D3E'], {'from': PRICE_FEED.owner()})
    BZX.setLoanPool([iToken], [iToken.loanTokenAddress()], {'from': GUARDIAN_MULTISIG})
    BZX.setSupportedTokens([iToken.loanTokenAddress()], [True], True, {'from': GUARDIAN_MULTISIG})
    BZX.setupLoanPoolTWAI(iToken, {'from': GUARDIAN_MULTISIG})

    # get some frax
    FRAX.transfer(accounts[0], 100000e18, {"from": "0xd4937682df3c8aef4fe912a96a74121c0829e664"})

    # lend frax
    iFRAX = Contract.from_abi("iFRAX", address=iToken, abi=interface.IToken.abi)
    FRAX.approve(iFRAX, 2**256-1, {"from": accounts[0]})
    iFRAX.mint(accounts[0], 10000e18, {"from": accounts[0]})

    # borrow frax
    iFRAX.borrow("", 50e18, 0, 1e18, '0x0000000000000000000000000000000000000000', accounts[0], accounts[0], b"", {'from': accounts[0], 'value':1e18})
    
    # borrow using frax collateral
    FRAX.approve(iUSDT, 2**256-1, {"from": accounts[0]})
    iUSDT.borrow("", 50e6, 0, 100e18, FRAX, accounts[0], accounts[0], b"", {'from': accounts[0]})

    # margin trade frax collateral
    iUSDT.marginTrade(0, 2e18, 0, 100e18, FRAX, accounts[0], b'',{'from': accounts[0]})
    
    # margin trade frax principal
    USDT.approve(iFRAX, 2**256-1, {"from": accounts[0]})
    iFRAX.marginTrade(0, 2e18, 0, 50e6, USDT, accounts[0], b'',{'from': accounts[0]})

    assert True

def test_case2(accounts, BZX, USDC, USDT, iUSDT, iUSDC, REGISTRY, GUARDIAN_MULTISIG, FRAX, LoanTokenLogicStandard, LoanToken, CurvedInterestRate, PriceFeeds, PRICE_FEED, interface, ALCX):
    PRICE_FEED.setPriceFeed([ALCX], ['0x194a9AaF2e0b67c35915cD01101585A33Fe25CAa'], {'from': PRICE_FEED.owner()})
    BZX.setSupportedTokens([ALCX], [True], True, {'from': GUARDIAN_MULTISIG})

    # get some ALCX
    ALCX.transfer(accounts[0], 10000e18, {"from": "0x6bb8bc41e668b7c8ef3850486c9455b5c86830b3"})

    # borrow using ALCX as collateral
    ALCX.approve(iUSDT, 2**256-1, {"from": accounts[0]})
    iUSDT.borrow("", 50e6, 0, 100e18, ALCX, accounts[0], accounts[0], b"", {'from': accounts[0]})
    loans = BZX.getUserLoans(accounts[0], 0, 10, 0, 0, 0)
    BZX.closeWithSwap(loans[0][0], accounts[0], 100e18, True, b"", {"from": accounts[0]})

    # margint trade ALCX collateral
    iUSDT.marginTrade(0, 2e18, 0, 100e18, ALCX, accounts[0], b'',{'from': accounts[0]})
    ALCX.approve(BZX, 2**256-1, {"from": accounts[0]})
    loans = BZX.getUserLoans(accounts[0], 0, 10, 0, 0, 0)
    USDT.approve(BZX, 2*256-1, {"from": accounts[0]})
    BZX.closeWithSwap(loans[0][0], accounts[0], 10000e18, True, b"", {"from": accounts[0]})
    BZX.closeWithDeposit(loans[0][0], accounts[0], 10000e6, {"from": accounts[0]})
    # margint trade STETH principal - you can't since no where to borrow, you can't short aave

    assert False


def test_case2_1(accounts, BZX, USDC, USDT, iUSDT, iUSDC, REGISTRY, GUARDIAN_MULTISIG, FRAX, LoanTokenLogicStandard, LoanToken, CurvedInterestRate, PriceFeeds, PRICE_FEED, interface, ALCX):
    PRICE_FEED.setPriceFeed([ALCX], ['0x194a9AaF2e0b67c35915cD01101585A33Fe25CAa'], {'from': PRICE_FEED.owner()})
    # BZX.setSupportedTokens([ALCX], [True], True, {'from': GUARDIAN_MULTISIG})

    # get some ALCX
    ALCX.transfer(accounts[0], 10000e18, {"from": "0x6bb8bc41e668b7c8ef3850486c9455b5c86830b3"})

    # borrow using ALCX as collateral
    ALCX.approve(iUSDT, 2**256-1, {"from": accounts[0]})
    with reverts("unsupported token"):
        iUSDT.borrow("", 50e6, 0, 100e18, ALCX, accounts[0], accounts[0], b"", {'from': accounts[0]})
 

    assert True

# this checks that migrateLoanParamsList works for all
def test_case4_1(BZX, USDC, USDT, iUSDT, iUSDC, REGISTRY, GUARDIAN_MULTISIG):
    supportedTokenAssetsPairs = REGISTRY.getTokens(0, 100)
    for assetPair in supportedTokenAssetsPairs:
        BZX.migrateLoanParamsList(assetPair[0], 0, 100, {"from": GUARDIAN_MULTISIG})

    assert True

def test_case4(BZX, USDC, USDT, iUSDT, iUSDC):
    loanParamsId = BZX.generateLoanParamId(USDC ,USDT, True)
    loanParamsBefore = BZX.loanParams(loanParamsId)
    assert loanParamsBefore[0] == "0x0000000000000000000000000000000000000000000000000000000000000000"
    assert loanParamsBefore[1] == False
    assert loanParamsBefore[2] == ZERO_ADDRESS
    assert loanParamsBefore[3] == ZERO_ADDRESS
    assert loanParamsBefore[4] == ZERO_ADDRESS
    assert loanParamsBefore[5] == 0
    assert loanParamsBefore[6] == 0
    assert loanParamsBefore[7] == 0

    BZX.migrateLoanParamsList(iUSDC, 0, 100, {"from": BZX.owner()})
    loanParamsBefore = BZX.loanParams(loanParamsId)
    assert loanParamsBefore[0] == loanParamsId
    assert loanParamsBefore[1] == True
    assert loanParamsBefore[2] == iUSDC
    assert loanParamsBefore[3] == USDC
    assert loanParamsBefore[4] == USDT
    assert loanParamsBefore[5] == 5500000000000000000
    assert loanParamsBefore[6] == 5000000000000000000
    assert loanParamsBefore[7] == 0



    loanParamsId = BZX.generateLoanParamId(USDT ,USDC, True)
    loanParamsBefore = BZX.loanParams(loanParamsId)
    assert loanParamsBefore[0] == "0x0000000000000000000000000000000000000000000000000000000000000000"
    assert loanParamsBefore[1] == False
    assert loanParamsBefore[2] == ZERO_ADDRESS
    assert loanParamsBefore[3] == ZERO_ADDRESS
    assert loanParamsBefore[4] == ZERO_ADDRESS
    assert loanParamsBefore[5] == 0
    assert loanParamsBefore[6] == 0
    assert loanParamsBefore[7] == 0

    BZX.migrateLoanParamsList(iUSDT, 0, 100, {"from": BZX.owner()})
    loanParamsBefore = BZX.loanParams(loanParamsId)
    assert loanParamsBefore[0] == loanParamsId
    assert loanParamsBefore[1] == True
    assert loanParamsBefore[2] == iUSDT
    assert loanParamsBefore[3] == USDT
    assert loanParamsBefore[4] == USDC
    assert loanParamsBefore[5] == 5500000000000000000
    assert loanParamsBefore[6] == 5000000000000000000
    assert loanParamsBefore[7] == 0

    assert True

# TODO getDefaultLoanParams doesn't sanitize all inputs properly outside protocol context
def test_case5(BZX, USDC, USDT, iUSDT, iUSDC):
    loanParams = BZX.getDefaultLoanParams(USDC, USDT, True)
    loanParamsId = BZX.generateLoanParamId(USDC ,USDT, True)
    assert loanParams[0][0] == loanParamsId
    assert loanParams[0][1] == True
    assert loanParams[0][2] == ZERO_ADDRESS
    assert loanParams[0][3] == USDC
    assert loanParams[0][4] == USDT
    assert loanParams[0][5] == 20000000000000000000
    assert loanParams[0][6] == 15000000000000000000
    assert loanParams[0][7] == 0

    loanParams = BZX.getDefaultLoanParams(USDC, iUSDT, True)
    loanParamsId = BZX.generateLoanParamId(USDC ,iUSDT, True)
    assert loanParams[0][0] == loanParamsId
    assert loanParams[0][1] == True
    assert loanParams[0][2] == ZERO_ADDRESS
    assert loanParams[0][3] == USDC
    assert loanParams[0][4] == iUSDT
    assert loanParams[0][5] == 20000000000000000000
    assert loanParams[0][6] == 15000000000000000000
    assert loanParams[0][7] == 0

    # now migrating. iUSDT is holding loanToken(USDT)
    BZX.migrateLoanParamsList(iUSDT, 0, 100, {"from": BZX.owner()})
    BZX.migrateLoanParamsList(iUSDC, 0, 100, {"from": BZX.owner()})

    # now we get USDC/USDT 15x while usdc/iUSDT still 5x
    loanParams = BZX.getDefaultLoanParams(USDC, USDT, True)
    loanParamsId = BZX.generateLoanParamId(USDC ,USDT, True)
    assert loanParams[0][0] == loanParamsId
    assert loanParams[0][1] == True
    assert loanParams[0][2] == iUSDC # since the loan is USDC
    assert loanParams[0][3] == USDC
    assert loanParams[0][4] == USDT
    assert loanParams[0][5] == 5500000000000000000
    assert loanParams[0][6] == 5000000000000000000
    assert loanParams[0][7] == 0

    loanParams = BZX.getDefaultLoanParams(USDC, iUSDT, True)
    loanParamsId = BZX.generateLoanParamId(USDC ,iUSDT, True)
    assert loanParams[0][0] == loanParamsId
    assert loanParams[0][1] == True
    assert loanParams[0][2] == ZERO_ADDRESS
    assert loanParams[0][3] == USDC
    assert loanParams[0][4] == iUSDT
    assert loanParams[0][5] == 20000000000000000000
    assert loanParams[0][6] == 15000000000000000000
    assert loanParams[0][7] == 0

    assert True


def test_case11(accounts, BZX, USDC, USDT, iUSDT, iUSDC, REGISTRY, GUARDIAN_MULTISIG, FRAX, LoanTokenLogicStandard, LoanToken, CurvedInterestRate, PriceFeeds, PRICE_FEED, interface, PriceFeedIToken):
    USDC.transfer(accounts[0], 100000e6, {"from": "0xcffad3200574698b78f32232aa9d63eabd290703"})
    USDT.transfer(accounts[0], 100000e6, {"from": "0x5a52e96bacdabb82fd05763e25335261b270efcb"})

    # setting pricefeed for iToken
    USDCPriceFeed = PRICE_FEED.pricesFeeds(USDC)
    USDCPriceFeed = Contract.from_abi("pricefeed", USDCPriceFeed, abi = interface.IPriceFeedsExt.abi)
    
    USDTPriceFeed = PRICE_FEED.pricesFeeds(USDT)
    USDTPriceFeed = Contract.from_abi("pricefeed", USDTPriceFeed, abi = interface.IPriceFeedsExt.abi)

    price_feed = PriceFeeds.deploy({"from": accounts[0]})
    BZX.setPriceFeedContract(price_feed, {"from": BZX.owner()})
    price_feed.changeGuardian(GUARDIAN_MULTISIG, {"from": accounts[0]})
    price_feed.setPriceFeed([USDC, USDT], [USDCPriceFeed, USDTPriceFeed], {"from": GUARDIAN_MULTISIG})

    USDC.approve(iUSDC, 2**256-1, {"from": accounts[0]})
    iUSDC.mint(accounts[0], 10000e6, {"from": accounts[0]})

    iUSDC.approve(iUSDT, 2**256-1, {"from": accounts[0]})
    with reverts("unsupported token"):
        iUSDT.borrow("", 50e6, 0, 100e6, iUSDC, accounts[0], accounts[0], b"", {'from': accounts[0]})

    BZX.setSupportedTokens([iUSDC], [True], True, {'from': GUARDIAN_MULTISIG})
    iUSDT.borrow("", 50e6, 0, 100e6, iUSDC, accounts[0], accounts[0], b"", {'from': accounts[0]})

    loans = BZX.getUserLoans(accounts[0], 0, 10, 0, 0, 0)
    BZX.closeWithSwap(loans[0][0], accounts[0], 10000e18, True, b"", {"from": accounts[0]})
    assert False

def test_case12(accounts, BZX, USDC, USDT, iUSDT, iUSDC, REGISTRY, GUARDIAN_MULTISIG, FRAX, LoanTokenLogicStandard, LoanToken, CurvedInterestRate, PriceFeeds, PRICE_FEED, interface, PriceFeedIToken):
    USDC.transfer(accounts[0], 100000e6, {"from": "0xcffad3200574698b78f32232aa9d63eabd290703"})
    USDT.transfer(accounts[0], 100000e6, {"from": "0x5a52e96bacdabb82fd05763e25335261b270efcb"})

    USDC.approve(iUSDC, 2**256-1, {"from": accounts[0]})
    iUSDC.mint(accounts[0], 10000e6, {"from": accounts[0]})

    USDT.approve(iUSDT, 2**256-1, {"from": accounts[0]})
    iUSDT.mint(accounts[0], 10000e6, {"from": accounts[0]})

    USDC.approve(iUSDT, 2**256-1, {"from": accounts[0]})
    iUSDT.marginTrade(0, 2e18, 0, 100e6, USDC, accounts[0], b'',{'from': accounts[0]})

    # setting pricefeed for iToken
    USDCPriceFeed = PRICE_FEED.pricesFeeds(USDC)
    USDCPriceFeed = Contract.from_abi("pricefeed", USDCPriceFeed, abi = interface.IPriceFeedsExt.abi)
    price_feed = PriceFeeds.deploy({"from": accounts[0]})
    BZX.setPriceFeedContract(price_feed, {"from": BZX.owner()})
    price_feed.changeGuardian(GUARDIAN_MULTISIG, {"from": accounts[0]})
    price_feed.setPriceFeed([USDC], [USDCPriceFeed], {"from": GUARDIAN_MULTISIG})

    # priceFeed = PriceFeedIToken.deploy(USDCPriceFeed, iUSDC, {"from": accounts[0]})
    # PRICE_FEED.setPriceFeed([iUSDC], [priceFeed], {'from': PRICE_FEED.owner()})

    # USDTPriceFeed = PRICE_FEED.pricesFeeds(USDT)
    # priceFeed = PriceFeedIToken.deploy(USDTPriceFeed, iUSDT, {"from": accounts[0]})
    # PRICE_FEED.setPriceFeed([iUSDT], [priceFeed], {'from': PRICE_FEED.owner()})
    # priceFeedExt = 
    assert abs(1/(price_feed.getPrice(iUSDC)/iUSDC.tokenPrice()) - 1/(price_feed.getPrice(USDC)/1e18)) < 10
    assert abs(1/(price_feed.getPrice(iUSDC)/iUSDC.tokenPrice()) - 1/(USDCPriceFeed.latestAnswer()/1e18)) < 10
    assert True