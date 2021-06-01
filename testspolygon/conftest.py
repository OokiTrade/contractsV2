#!/usr/bin/python3

import pytest
from brownie import Contract, network, Wei

@pytest.fixture(scope="class")
def requireFork():
    assert (network.show_active().find("-fork")>=0)

@pytest.fixture(scope="class", autouse=True)
def MATIC(accounts, TestToken):
    return Contract.from_abi("USDT", "0x0d500B1d8E8eF31E21C99d1Db9A6444d3ADf1270", TestToken.abi)

@pytest.fixture(scope="class", autouse=True)
def ETH(accounts, TestToken):
    return Contract.from_abi("ETH", "0x7ceB23fD6bC0adD59E62ac25578270cFf1b9f619", TestToken.abi)

@pytest.fixture(scope="class", autouse=True)
def USDC(accounts, TestToken):
    return Contract.from_abi("USDC", "0x2791Bca1f2de4661ED88A30C99A7a9449Aa84174", TestToken.abi)

@pytest.fixture(scope="class", autouse=True)
def WBTC(accounts, TestToken):
    return Contract.from_abi("WMTC", "0x1BFD67037B42Cf73acF2047067bd4F2C47D9BfD6", TestToken.abi)


@pytest.fixture(scope="class", autouse=True)
def USDT(accounts, TestToken):
    return Contract.from_abi("USDT", "0xc2132D05D31c914a87C6611C10748AEb04B58e8F", TestToken.abi)


@pytest.fixture(scope="class")
def BZX(accounts, interface):
    return Contract.from_abi("bzx", address="0xfe4F0eb0A1Ad109185c9AaDE64C48ff8e928e54B",
                      abi=interface.IBZx.abi, owner=accounts[0])


@pytest.fixture(scope="class", autouse=True)
def iMATIC(accounts, BZX, LoanTokenLogicWeth, MATIC ):
    iMATICAddress = BZX.underlyingToLoanPool(MATIC)
    return Contract.from_abi("iMATIC", address=iMATICAddress, abi=LoanTokenLogicWeth.abi, owner=accounts[0])


@pytest.fixture(scope="class", autouse=True)
def iETH(accounts, BZX, LoanTokenLogicStandard, ETH):
    iETHAddress = BZX.underlyingToLoanPool(ETH)
    return Contract.from_abi("iETH", address=iETHAddress , abi=LoanTokenLogicStandard.abi, owner=accounts[0])


@pytest.fixture(scope="class", autouse=True)
def iUSDC(accounts, BZX, LoanTokenLogicStandard, USDC):
    iUSDCAddress = BZX.underlyingToLoanPool(USDC)
    return Contract.from_abi("iUSDC", address=iUSDCAddress, abi=LoanTokenLogicStandard.abi, owner=accounts[0])

@pytest.fixture(scope="class", autouse=True)
def iWBTC(accounts, BZX, LoanTokenLogicStandard, WBTC):
    iWBTCAddress = BZX.underlyingToLoanPool(WBTC)
    return Contract.from_abi("iWBTC", address=iWBTCAddress, abi=LoanTokenLogicStandard.abi, owner=accounts[0])

@pytest.fixture(scope="class", autouse=True)
def iUSDT(accounts, BZX, LoanTokenLogicStandard, USDT):
    iUSDTAddress = BZX.underlyingToLoanPool(USDT)
    return Contract.from_abi("iUSDT", address=iUSDTAddress, abi=LoanTokenLogicStandard.abi, owner=accounts[0])


@pytest.fixture(scope="class", autouse=True)
def pgovToken(accounts, GovToken):
    return Contract.from_abi("GovToken", address="0x6044a7161C8EBb7fE610Ed579944178350426B5B", abi=GovToken.abi, owner=accounts[0]);

@pytest.fixture(scope="class", autouse=True)
def masterChef(accounts, chain, MasterChef_Polygon, iMATIC, iETH, iUSDC, iWBTC, iUSDT, pgovToken, Proxy):
    devAccount = accounts[9]
    pgovPerBlock = 25*10**18
    startBlock = chain.height
    masterChefImpl = accounts[0].deploy(MasterChef_Polygon)
    masterChefProxy = accounts[0].deploy(Proxy, masterChefImpl)
    masterChef = Contract.from_abi("masterChef", address=masterChefProxy, abi=MasterChef_Polygon.abi, owner=accounts[0])
    masterChef.initialize(pgovToken, devAccount, pgovPerBlock, startBlock)
    masterChef.add(87500, iMATIC, 1)
    masterChef.add(12500, iUSDC, 1)
    return masterChef

@pytest.fixture(scope="class", autouse=True)
def tokens(accounts, chain, iMATIC, MATIC, iUSDC, USDC):
    return {
        'iMATIC': iMATIC,
        'iUSDC': iUSDC,
        'MATIC': MATIC,
        'USDC': USDC
    }


def initBalance(account, token, lpToken, addBalance):
    if(lpToken.symbol() == 'iMATIC'):
        lpToken.mintWithEther(account, {'from': account, 'value': addBalance})
    if(lpToken.symbol() == 'iUSDC'):
        USDC.approve(iUSDT, 2**256-1, {'from': account})
        iUSDC.mint(account, addBalance, {'from': account})
        iUSDC.approve(account, 2**256-1, {'from': account})