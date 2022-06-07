#!/usr/bin/python3
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
def BZX(accounts, interface, TickMathV1, LoanOpenings, LoanSettings):
    tickMathV1 = accounts[0].deploy(TickMathV1)
    lo = accounts[0].deploy(LoanOpenings)
    ls = accounts[0].deploy(LoanSettings)
    bzx = Contract.from_abi("bzx", address="0xD8Ee69652E4e4838f2531732a46d1f7F584F0b7f", abi=interface.IBZx.abi)
    bzx.replaceContract(lo, {"from": bzx.owner()})
    bzx.replaceContract(ls, {"from": bzx.owner()})
    return bzx


@pytest.fixture(scope="module")
def USDT(accounts, TestToken):
    return Contract.from_abi("USDT", address="0xdAC17F958D2ee523a2206206994597C13D831ec7", abi=TestToken.abi)

@pytest.fixture(scope="module")
def USDC(accounts, TestToken):
    return Contract.from_abi("USDC", address="0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48", abi=TestToken.abi)


@pytest.fixture(scope="module")
def WETH(accounts, TestToken):
    return Contract.from_abi("USDT", address="0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2", abi=TestToken.abi)


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

    assert False