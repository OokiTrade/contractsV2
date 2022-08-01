#!/usr/bin/python3

import pytest
from brownie import ZERO_ADDRESS, network, Contract, reverts, chain
from brownie.convert.datatypes import Wei
from eth_abi import encode_abi, is_encodable, encode_single, is_encodable_type
from eth_abi.packed import encode_single_packed, encode_abi_packed
from hexbytes import HexBytes
import json
from eth_account import Account
from eth_account.messages import encode_structured_data
from eip712.messages import EIP712Message, EIP712Type
from brownie.network.account import LocalAccount
from brownie.convert.datatypes import *
from brownie import web3
from eth_abi import encode_abi


@pytest.fixture(scope="module")
def requireFork():
    assert (network.show_active() == "fork" or "fork" in network.show_active())


@pytest.fixture(autouse=True)
def isolation(fn_isolation):
    pass


@pytest.fixture(scope="module")
def BZX(accounts, interface, TickMathV1, LoanOpenings, LoanSettings, ProtocolSettings, LoanClosingsLiquidation, LoanMaintenance, LiquidationHelper, VolumeTracker, LoanClosings):
    tickMathV1 = accounts[0].deploy(TickMathV1)
    liquidationHelper = accounts[0].deploy(LiquidationHelper)
    accounts[0].deploy(VolumeTracker)

    lo = accounts[0].deploy(LoanOpenings)
    lc = accounts[0].deploy(LoanClosings)
    ls = accounts[0].deploy(LoanSettings)
    ps = accounts[0].deploy(ProtocolSettings)
    lcs = accounts[0].deploy(LoanClosingsLiquidation)
    lm = accounts[0].deploy(LoanMaintenance)

    bzx = Contract.from_abi("bzx", address="0x37407F3178ffE07a6cF5C847F8f680FEcf319FAB", abi=interface.IBZx.abi)
    bzx.replaceContract(lo, {"from": bzx.owner()})
    bzx.replaceContract(lc, {"from": bzx.owner()})
    bzx.replaceContract(ls, {"from": bzx.owner()})
    bzx.replaceContract(ps, {"from": bzx.owner()})
    bzx.replaceContract(lcs, {"from": bzx.owner()})
    bzx.replaceContract(lm, {"from": bzx.owner()})

    return bzx


@pytest.fixture(scope="module")
def USDT(accounts, TestToken):
    return Contract.from_abi("USDT", address="0xFd086bC7CD5C481DCC9C85ebE478A1C0b69FCbb9", abi=TestToken.abi)

@pytest.fixture(scope="module")
def USDC(accounts, TestToken):
    return Contract.from_abi("USDC", address="0xFF970A61A04b1cA14834A43f5dE4533eBDDB5CC8", abi=TestToken.abi)

@pytest.fixture(scope="module")
def FRAX(accounts, TestToken):
    return Contract.from_abi("FRAX", address="0x17FC002b466eEc40DaE837Fc4bE5c67993ddBd6F", abi=TestToken.abi)

@pytest.fixture(scope="module")
def DAI(accounts, TestToken):
    return Contract.from_abi("DAI", address="0xDA10009cBd5D07dd0CeCc66161FC93D7c9000da1", abi=TestToken.abi)


# @pytest.fixture(scope="module")
# def STETH(accounts, TestToken):
#     return Contract.from_abi("STETH", address="0xae7ab96520DE3A18E5e111B5EaAb095312D7fE84", abi=TestToken.abi)

@pytest.fixture(scope="module")
def CRV(accounts, TestToken):
    return Contract.from_abi("CRV", address="0x11cDb42B0EB46D95f990BeDD4695A6e3fA034978", abi=TestToken.abi)


@pytest.fixture(scope="module")
def HELPER(accounts, HelperImpl, HelperProxy, GUARDIAN_MULTISIG):
    # helperImpl = HelperImpl.deploy({"from": accounts[0]})

    # HELPER = Contract.from_abi("HELPER", "0xB8329B5458B1E493EFd8D9DA8C3B5E6D68e67C21", HelperProxy.abi)
    # HELPER.replaceImplementation(helperImpl, {"from": GUARDIAN_MULTISIG})
    return Contract.from_abi("HELPER", "0xB8329B5458B1E493EFd8D9DA8C3B5E6D68e67C21", HelperImpl.abi)

@pytest.fixture(scope="module")
def WETH(accounts, TestToken):
    return Contract.from_abi("USDT", address="0x82aF49447D8a07e3bd95BD0d56f35241523fBab1", abi=TestToken.abi)

@pytest.fixture(scope="module")
def PRICE_FEED(accounts, BZX, PriceFeeds):

    return Contract.from_abi("PRICE_FEED", BZX.priceFeeds(), abi = PriceFeeds.abi)
    # return Contract.from_abi("USDT", address="0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2", abi=TestToken.abi)


@pytest.fixture(scope="module")
def iUSDT(accounts, LoanTokenLogicStandard, interface):
    itokenImpl = accounts[0].deploy(LoanTokenLogicStandard)
    itoken = Contract.from_abi("iUSDT", address="0xd103a2D544fC02481795b0B33eb21DE430f3eD23", abi=interface.IToken.abi)
    itoken.setTarget(itokenImpl, {"from": itoken.owner()})
    itoken.initializeDomainSeparator({"from": itoken.owner()})
    return itoken


@pytest.fixture(scope="module")
def iUSDC(accounts, LoanTokenLogicStandard, interface):
    itokenImpl = accounts[0].deploy(LoanTokenLogicStandard)
    itoken = Contract.from_abi("iUSDC", address="0xEDa7f294844808B7C93EE524F990cA7792AC2aBd", abi=interface.IToken.abi)
    itoken.setTarget(itokenImpl, {"from": itoken.owner()})
    itoken.initializeDomainSeparator({"from": itoken.owner()})
    return itoken

@pytest.fixture(scope="module")
def GUARDIAN_MULTISIG():
    return "0x111F9F3e59e44e257b24C5d1De57E05c380C07D2"

@pytest.fixture(scope="module")
def REGISTRY(accounts, TokenRegistry):
    return Contract.from_abi("REGISTRY", address="0x86003099131d83944d826F8016E09CC678789A30",
                             abi=TokenRegistry.abi)

def test_cases():
    # Test Case 1: check you can setup a working iToken using guardian only power
    # Test Case 2: check you can setup a new collateral using guardian only power
    # Test Case 3: check you can liquidate with new iToken
    # Test Case 4: check migrateLoanParamsList, after the migration new loanId should be working
    # Test Case 5: check getDefaultLoanParams all possible scenarios
    # Test Case 6: make sure you can't intentionally borrowOrTradeFromPool and create undexpected loanParam
    # Test Case 7: make sure guardian can create/updates existing loan params with specific settings
    # Test Case 8: test HELPER getBorrowAmount for deposit and vice versa
    # Test Case 11: borrow with iToken
    # Test Case 12: set iToken pricefeed
    # Test Case 13: test approvals
    # Test Case 14: iToken permit borrow
    assert True

def test_case1(accounts, BZX, USDC, USDT, iUSDT, iUSDC, REGISTRY, GUARDIAN_MULTISIG, DAI, LoanTokenLogicStandard, LoanToken, CurvedInterestRate, PriceFeeds, PRICE_FEED, interface):
    underlyingSymbol = DAI.symbol()
    iTokenSymbol = "i{}".format(underlyingSymbol.upper())
    iTokenName = "Ooki {} iToken ({})".format(underlyingSymbol, iTokenSymbol)
    
    loanTokenLogicStandard = LoanTokenLogicStandard.deploy({'from': GUARDIAN_MULTISIG})
    iTokenProxy = LoanToken.deploy(GUARDIAN_MULTISIG, loanTokenLogicStandard, {"from": GUARDIAN_MULTISIG})
    iToken = Contract.from_abi("iToken", address=iTokenProxy,abi=LoanTokenLogicStandard.abi, owner=GUARDIAN_MULTISIG)
    iToken.initialize(DAI, iTokenName, iTokenSymbol, {"from": GUARDIAN_MULTISIG})
    iToken.initializeDomainSeparator({"from": GUARDIAN_MULTISIG})
    cui = CurvedInterestRate.deploy({'from': GUARDIAN_MULTISIG})
    iToken.setDemandCurve(cui, {'from': GUARDIAN_MULTISIG})

    
    # TODO migrate pricefeed to allow guardian to modify, deploy new pricefeed
    PRICE_FEED.setPriceFeed([DAI], ['0xc5C8E77B397E531B8EC06BFb0048328B30E9eCfB'], {'from': PRICE_FEED.owner()})
    BZX.setLoanPool([iToken], [iToken.loanTokenAddress()], {'from': GUARDIAN_MULTISIG})
    BZX.setSupportedTokens([iToken.loanTokenAddress()], [True], True, {'from': GUARDIAN_MULTISIG})
    BZX.setupLoanPoolTWAI(iToken, {'from': GUARDIAN_MULTISIG})

    # get some frax
    DAI.transfer(accounts[0], 100000e18, {"from": "0xc5ed2333f8a2c351fca35e5ebadb2a82f5d254c3"})
    
    # lend frax
    iDAI = Contract.from_abi("iDAI", address=iToken, abi=interface.IToken.abi)
    DAI.approve(iDAI, 2**256-1, {"from": accounts[0]})

    iDAI.mint(accounts[0], 10000e18, {"from": accounts[0]})

    # borrow frax
    iDAI.borrow("", 50e18, 0, 1e18, '0x0000000000000000000000000000000000000000', accounts[0], accounts[0], b"", {'from': accounts[0], 'value':1e18})
    
    # borrow using frax collateral
    DAI.approve(iUSDT, 2**256-1, {"from": accounts[0]})
    iUSDT.borrow("", 50e6, 0, 100e18, DAI, accounts[0], accounts[0], b"", {'from': accounts[0]})

    # margin trade frax collateral
    iUSDT.marginTrade(0, 2e18, 0, 100e18, DAI, accounts[0], b'',{'from': accounts[0]})
    
    # margin trade frax principal
    USDT.approve(iDAI, 2**256-1, {"from": accounts[0]})
    iDAI.marginTrade(0, 2e18, 0, 50e6, USDT, accounts[0], b'',{'from': accounts[0]})

    assert True

def test_case2(accounts, BZX, USDC, USDT, iUSDT, iUSDC, REGISTRY, GUARDIAN_MULTISIG, FRAX, LoanTokenLogicStandard, LoanToken, CurvedInterestRate, PriceFeeds, PRICE_FEED, interface, CRV):
    PRICE_FEED.setPriceFeed([CRV], ['0xaebDA2c976cfd1eE1977Eac079B4382acb849325'], {'from': PRICE_FEED.owner()})
    BZX.setSupportedTokens([CRV], [True], True, {'from': GUARDIAN_MULTISIG})

    # get some CRV
    CRV.transfer(accounts[0], 1000e18, {"from": "0x4a65e76be1b4e8dd6ef618277fa55200e3f8f20a"})

    # borrow using CRV as collateral
    CRV.approve(iUSDT, 2**256-1, {"from": accounts[0]})
    iUSDT.borrow("", 10e6, 0, 100e18, CRV, accounts[0], accounts[0], b"", {'from': accounts[0]})
    loans = BZX.getUserLoans(accounts[0], 0, 10, 0, 0, 0)
    BZX.closeWithSwap(loans[0][0], accounts[0], 100e18, True, b"", {"from": accounts[0]})

    # margint trade CRV collateral
    iUSDT.marginTrade(0, 1e18, 0, 100e18, CRV, accounts[0], b'',{'from': accounts[0]})
    CRV.approve(BZX, 2**256-1, {"from": accounts[0]})
    loans = BZX.getUserLoans(accounts[0], 0, 10, 0, 0, 0)
    USDT.approve(BZX, 2*256-1, {"from": accounts[0]})
    BZX.closeWithSwap(loans[0][0], accounts[0], 1000e18, True, b"", {"from": accounts[0]})
    with reverts("loan is closed"):
        BZX.closeWithDeposit(loans[0][0], accounts[0], 1000e6, b"", {"from": accounts[0]})
    # margint trade STETH principal - you can't since no where to borrow, you can't short aave

    assert True


def test_case2_1(accounts, BZX, USDC, USDT, iUSDT, iUSDC, REGISTRY, GUARDIAN_MULTISIG, FRAX, LoanTokenLogicStandard, LoanToken, CurvedInterestRate, PriceFeeds, PRICE_FEED, interface, CRV):
    PRICE_FEED.setPriceFeed([CRV], ['0xaebDA2c976cfd1eE1977Eac079B4382acb849325'], {'from': PRICE_FEED.owner()})
    # BZX.setSupportedTokens([CRV], [True], True, {'from': GUARDIAN_MULTISIG})

    # get some CRV
    CRV.transfer(accounts[0], 10000e18, {"from": "0x4a65e76be1b4e8dd6ef618277fa55200e3f8f20a"})

    # borrow using CRV as collateral
    CRV.approve(iUSDT, 2**256-1, {"from": accounts[0]})
    with reverts("unsupported token"):
        iUSDT.borrow("", 50e6, 0, 100e18, CRV, accounts[0], accounts[0], b"", {'from': accounts[0]})
 

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
    assert loanParamsBefore[5] == 6666666666666666666
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
    assert loanParamsBefore[5] == 6666666666666666666
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
    assert loanParams[0][5] == 6666666666666666666
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

def test_case7(accounts, BZX, USDC, USDT, iUSDT, iUSDC, REGISTRY, GUARDIAN_MULTISIG, FRAX, LoanTokenLogicStandard, LoanToken, CurvedInterestRate, PriceFeeds, PRICE_FEED, interface, PriceFeedIToken):
    BZX.migrateLoanParamsList(iUSDC, 0, 100, {"from": BZX.owner()})
    loanParamId = BZX.generateLoanParamId(USDC, USDT, True)
    loanParam = BZX.loanParams(loanParamId)
    BZX.modifyLoanParams([loanParam], {"from": GUARDIAN_MULTISIG})
    assert True

def test_case8(BZX, USDC, USDT, iUSDT, iUSDC, HELPER, accounts, HelperProxy, HelperImpl, GUARDIAN_MULTISIG, LoanTokenLogicStandard, interface):
    
    helperImpl = HelperImpl.deploy({"from": accounts[0]})

    HELPER = Contract.from_abi("HELPER", "0xB8329B5458B1E493EFd8D9DA8C3B5E6D68e67C21", HelperProxy.abi)
    HELPER.replaceImplementation(helperImpl, {"from": GUARDIAN_MULTISIG})
    HELPER = Contract.from_abi("HELPER", "0xB8329B5458B1E493EFd8D9DA8C3B5E6D68e67C21", HelperImpl.abi)
    borrowAmountForDeposit = iUSDC.getBorrowAmountForDeposit(1e6, 0, USDT)
    
    itokenImpl = accounts[0].deploy(LoanTokenLogicStandard)
    itoken = Contract.from_abi("iUSDC", address=iUSDC, abi=interface.IToken.abi)
    itoken.setTarget(itokenImpl, {"from": itoken.owner()})
    itoken.initializeDomainSeparator({"from": itoken.owner()})

    BZX.migrateLoanParamsList(iUSDC, 0, 100, {"from": BZX.owner()})
    borrowAmountForDepositAfter = HELPER.getBorrowAmountForDeposit(1e6, USDC, USDT)
    assert borrowAmountForDeposit == borrowAmountForDepositAfter

def test_case11(accounts, BZX, USDC, USDT, iUSDT, iUSDC, REGISTRY, GUARDIAN_MULTISIG, FRAX, LoanTokenLogicStandard, LoanToken, CurvedInterestRate, PriceFeeds, PRICE_FEED, interface, PriceFeedIToken):
    USDC.transfer(accounts[0], 100000e6, {"from": "0x1714400ff23db4af24f9fd64e7039e6597f18c2b"})
    USDT.transfer(accounts[0], 100000e6, {"from": "0xb6cfcf89a7b22988bfc96632ac2a9d6dab60d641"})

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
    USDT.approve(BZX, 1000e6, {"from": accounts[0]})
    BZX.closeWithDeposit(loans[0][0], accounts[0], 1000e6, b'', {"from": accounts[0]})
    assert True

def test_case12(accounts, BZX, USDC, USDT, iUSDT, iUSDC, REGISTRY, GUARDIAN_MULTISIG, FRAX, LoanTokenLogicStandard, LoanToken, CurvedInterestRate, PriceFeeds, PRICE_FEED, interface, PriceFeedIToken):
    USDC.transfer(accounts[0], 100000e6, {"from": "0x1714400ff23db4af24f9fd64e7039e6597f18c2b"})
    USDT.transfer(accounts[0], 100000e6, {"from": "0xb6cfcf89a7b22988bfc96632ac2a9d6dab60d641"})

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
    assert abs(1/(price_feed.getPrice(iUSDC)/iUSDC.tokenPrice()) - 1/(price_feed.getPrice(USDC)/1e18)) < 50
    assert abs(1/(price_feed.getPrice(iUSDC)/iUSDC.tokenPrice()) - 1/(USDCPriceFeed.latestAnswer()/1e18)) < 50
    assert True

def test_case13(BZX, USDC, GUARDIAN_MULTISIG):
    allowance_before = USDC.allowance(BZX, "0x1b02dA8Cb0d097eB8D57A175b88c7D8b47997506")
    BZX.setApprovals([USDC], [1,2], {"from":GUARDIAN_MULTISIG})
    allowance_after = USDC.allowance(BZX, "0x1b02dA8Cb0d097eB8D57A175b88c7D8b47997506")
    assert(allowance_after > allowance_before)



class Permit():
    def __init__(self, name, chainId, verifyingContract, owner, spender, value, nonce, deadline, domain_separator):
        self.name = name
        self.chainId = chainId
        self.verifyingContract = str(verifyingContract)
        self.owner = str(owner)
        self.spender = str(spender)
        self.value = int(value)
        self.nonce = nonce
        self.deadline = deadline
        self.permit_typehash = HexString("0x6e71edae12b1b97f4d1f60370fef10105fa2faae0126114a169c64845d6126c9", "bytes32")
        self.domain_separator = domain_separator

    def sign_message(self, local: LocalAccount):
        domainData = web3.sha3(encode_abi(["bytes32", "address", "address", "uint256", "uint256", "uint256"],
                                          [self.permit_typehash, str(local), self.verifyingContract, self.value, self.nonce, self.deadline]))
        digest = web3.solidityKeccak(['bytes1', 'bytes1', 'bytes32', 'bytes32'], [b'\x19', b'\x01', self.domain_separator, domainData])
        signed_permit = web3.eth.account.signHash(digest, local.private_key)
        return signed_permit


def test_case14(accounts, BZX, USDC, USDT, iUSDT, iUSDC, REGISTRY, GUARDIAN_MULTISIG, FRAX, LoanTokenLogicStandard, LoanToken, CurvedInterestRate, PriceFeeds, PRICE_FEED, interface, PriceFeedIToken):

    local = accounts.add(private_key="0x416b8a7d9290502f5661da81f0cf43893e3d19cb9aea3c426cfb36e8186e9c09")
    accounts[0].transfer(to=local, amount=Wei("10 ether"))


    p = Permit(iUSDC.name(), chain.id, iUSDT, local, iUSDT, int(100e6), local.nonce, chain.time()+1000, iUSDC.DOMAIN_SEPARATOR())
    signed_permit = p.sign_message(local)
    payload = encode_abi(['address', 'address', 'uint', 'uint', 'uint8', 'bytes32', 'bytes32'],[p.owner, p.spender, p.value, p.deadline, signed_permit.v, HexBytes(signed_permit.r), HexBytes(signed_permit.s)])
    loanDataBytes = encode_abi(['uint128','bytes[]'], [16, [payload]]) #flag value WITH_PERMIT = 16
    
    # iUSDT.permit(p.owner, p.spender, p.value, p.deadline, signed_permit.v, signed_permit.r, signed_permit.s, {"from": local})


    USDC.transfer(local, 100000e6, {"from": "0x1714400ff23db4af24f9fd64e7039e6597f18c2b"})
    USDT.transfer(local, 100000e6, {"from": "0xb6cfcf89a7b22988bfc96632ac2a9d6dab60d641"})

    # setting pricefeed for iToken
    USDCPriceFeed = PRICE_FEED.pricesFeeds(USDC)
    USDCPriceFeed = Contract.from_abi("pricefeed", USDCPriceFeed, abi = interface.IPriceFeedsExt.abi)
    
    USDTPriceFeed = PRICE_FEED.pricesFeeds(USDT)
    USDTPriceFeed = Contract.from_abi("pricefeed", USDTPriceFeed, abi = interface.IPriceFeedsExt.abi)

    price_feed = PriceFeeds.deploy({"from": local})
    BZX.setPriceFeedContract(price_feed, {"from": BZX.owner()})
    price_feed.changeGuardian(GUARDIAN_MULTISIG, {"from": local})
    price_feed.setPriceFeed([USDC, USDT], [USDCPriceFeed, USDTPriceFeed], {"from": GUARDIAN_MULTISIG})

    USDC.approve(iUSDC, 2**256-1, {"from": local})
    iUSDC.mint(local, 10000e6, {"from": local})

    # iUSDC.approve(iUSDT, 2**256-1, {"from": accounts[0]}) loanDataBytes(permit) is handling this
    
    # with reverts("OOKI: INVALID_SIGNATURE"):
    #     iUSDT.borrow("", 50e6, 0, 100e6, iUSDC, local, local, loanDataBytes, {'from': local})

    BZX.setSupportedTokens([iUSDC], [True], True, {'from': GUARDIAN_MULTISIG})
    iUSDT.borrow("", 50e6, 0, 100e6, iUSDC, local, local, loanDataBytes, {'from': local})

    loans = BZX.getUserLoans(local, 0, 10, 0, 0, 0)
    USDT.approve(BZX, 1000e6, {"from": local})
    BZX.closeWithDeposit(loans[0][0], local, 1000e6, b'', {"from": local})
    assert True