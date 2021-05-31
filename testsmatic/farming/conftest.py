#!/usr/bin/python3

import pytest
from brownie import Contract, network, Wei

@pytest.fixture(scope="class")
def requireFork():
    assert (network.show_active().find("-fork")>=0)

@pytest.fixture(scope="class", autouse=True)
def MATIC(accounts, TestToken):
    return Contract.from_abi("MATIC", "0x0d500B1d8E8eF31E21C99d1Db9A6444d3ADf1270", TestToken.abi)

@pytest.fixture(scope="class", autouse=True)
def ETH(accounts, TestToken):
    return Contract.from_abi("ETH", "0x7ceB23fD6bC0adD59E62ac25578270cFf1b9f619", TestToken.abi)

@pytest.fixture(scope="class", autouse=True)
def USDT(accounts, TestToken):
    return Contract.from_abi("USDT", "0xc2132D05D31c914a87C6611C10748AEb04B58e8F", TestToken.abi)

@pytest.fixture(scope="class", autouse=True)
def WBTC(accounts, TestToken):
    return Contract.from_abi("USDT", "0x1BFD67037B42Cf73acF2047067bd4F2C47D9BfD6", TestToken.abi)


@pytest.fixture(scope="class", autouse=True)
def USDC(accounts, TestToken):
    return Contract.from_abi("USDC", "0x2791Bca1f2de4661ED88A30C99A7a9449Aa84174", TestToken.abi)


@pytest.fixture(scope="class")
def BZX(accounts, interface):
    return Contract.from_abi("bzx", address="0xfe4F0eb0A1Ad109185c9AaDE64C48ff8e928e54B",
                      abi=interface.IBZx.abi, owner=accounts[0])


@pytest.fixture(scope="class", autouse=True)
def iWBNB(accounts, BZX, LoanTokenLogicWeth, MATIC ):
    iAddress = BZX.underlyingToLoanPool(MATIC)
    return Contract.from_abi("iMATIC", address=iAddress, abi=LoanTokenLogicWeth.abi, owner=accounts[0])


@pytest.fixture(scope="class", autouse=True)
def iETH(accounts, BZX, LoanTokenLogicStandard, ETH):
    iAddress = BZX.underlyingToLoanPool(ETH)
    return Contract.from_abi("iETH", address=iAddress , abi=LoanTokenLogicStandard.abi, owner=accounts[0])


@pytest.fixture(scope="class", autouse=True)
def iBUSD(accounts, BZX, LoanTokenLogicStandard, USDC):
    iAddress = BZX.underlyingToLoanPool(USDC)
    return Contract.from_abi("iUSDC", address=iAddress, abi=LoanTokenLogicStandard.abi, owner=accounts[0])

@pytest.fixture(scope="class", autouse=True)
def iWBTC(accounts, BZX, LoanTokenLogicStandard, WBTC):
    iAddress = BZX.underlyingToLoanPool(WBTC)
    return Contract.from_abi("iWBTC", address=iAddress, abi=LoanTokenLogicStandard.abi, owner=accounts[0])

@pytest.fixture(scope="class", autouse=True)
def iUSDT(accounts, BZX, LoanTokenLogicStandard, USDT):
    iAddress = BZX.underlyingToLoanPool(USDT)
    return Contract.from_abi("iUSDT", address=iAddress, abi=LoanTokenLogicStandard.abi, owner=accounts[0])


@pytest.fixture(scope="class", autouse=True)
def pgovToken(accounts, PGovToken):
    return accounts[0].deploy(PGovToken);

@pytest.fixture(scope="class", autouse=True)
def masterChef(accounts, chain, MasterChef_POLYGON, iMATIC, iETH, iUSDC, iWBTC, iUSDT, pgovToken, Proxy):
    devAccount = accounts[0]
    bgovPerBlock = 100*10**18
    bonusEndBlock = chain.height + 1*10**6

    startBlock = chain.height

    masterChefImpl = accounts[0].deploy(MasterChef_POLYGON)
    masterChefProxy = accounts[0].deploy(Proxy, masterChefImpl)
    masterChef = Contract.from_abi("masterChef", address=masterChefProxy, abi=MasterChef_POLYGON.abi, owner=accounts[0])

    masterChef.initialize(pgovToken, devAccount, bgovPerBlock, startBlock, bonusEndBlock)

    allocPoint = 1
    bgovToken.transferOwnership(masterChef);
    masterChef.add(allocPoint, iMATIC, 1)
    masterChef.add(allocPoint, iETH, 1)
    masterChef.add(allocPoint, iUSDC, 1)
    masterChef.add(allocPoint, iWBTC, 1)
    masterChef.add(allocPoint, iUSDT, 1)

    return masterChef;


@pytest.fixture(scope="class", autouse=True)
def tokens(accounts, chain, MasterChef, iMATIC, iUSDC, MATIC, USDT):
    return {
        'iMATIC': iMATIC,
        'iUSDC': iUSDC,
        'MATIC': MATIC,
        'USDT': USDT
    }


def initBalance(account, token, lpToken, addBalance):
    if(lpToken.symbol() == 'iBNB'):
        lpToken.mintWithEther(account, {'from': account, 'value': addBalance})
    if(lpToken.symbol() == 'iBUSD'):
        token.transfer(account, addBalance, {'from': '0x7c9e73d4c71dae564d41f78d56439bb4ba87592f'})
        token.approve(lpToken, addBalance, {'from': account})
        lpToken.mint(account, addBalance, {'from': account})