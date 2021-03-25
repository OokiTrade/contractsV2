#!/usr/bin/python3

import pytest
from brownie import Contract, network, Wei

@pytest.fixture(scope="class")
def requireBscFork():
    assert (network.show_active().find("binance-fork")>=0)

@pytest.fixture(scope="class", autouse=True)
def WBNB(accounts, TestToken):
    return Contract.from_abi("USDT", "0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c", TestToken.abi)

@pytest.fixture(scope="class", autouse=True)
def ETH(accounts, TestToken):
    return Contract.from_abi("USDT", "0x2170ed0880ac9a755fd29b2688956bd959f933f8", TestToken.abi)

@pytest.fixture(scope="class", autouse=True)
def BUSD(accounts, TestToken):
    return Contract.from_abi("BUSD", "0xe9e7cea3dedca5984780bafc599bd69add087d56", TestToken.abi)

@pytest.fixture(scope="class", autouse=True)
def WBTC(accounts, TestToken):
    return Contract.from_abi("USDT", "0x7130d2a12b9bcbfae4f2634d864a1ee1ce3ead9c", TestToken.abi)


@pytest.fixture(scope="class", autouse=True)
def USDT(accounts, TestToken):
    return Contract.from_abi("USDT", "0x55d398326f99059ff775485246999027b3197955", TestToken.abi)


@pytest.fixture(scope="class")
def BZX(accounts, interface):
    return Contract.from_abi("bzx", address="0xc47812857a74425e2039b57891a3dfcf51602d5d",
                      abi=interface.IBZx.abi, owner=accounts[0])


@pytest.fixture(scope="class", autouse=True)
def iWBNB(accounts, BZX, LoanTokenLogicWeth, WBNB ):
    iWBNBAddress = BZX.underlyingToLoanPool(WBNB)
    return Contract.from_abi("iWBNB", address=iWBNBAddress, abi=LoanTokenLogicWeth.abi, owner=accounts[0])


@pytest.fixture(scope="class", autouse=True)
def iETH(accounts, BZX, LoanTokenLogicStandard, ETH):
    iETHAddress = BZX.underlyingToLoanPool(ETH)
    return Contract.from_abi("iETH", address=iETHAddress , abi=LoanTokenLogicStandard.abi, owner=accounts[0])


@pytest.fixture(scope="class", autouse=True)
def iBUSD(accounts, BZX, LoanTokenLogicStandard, BUSD):
    iBUSDAddress = BZX.underlyingToLoanPool(BUSD)
    return Contract.from_abi("iBUSD", address=iBUSDAddress, abi=LoanTokenLogicStandard.abi, owner=accounts[0])

@pytest.fixture(scope="class", autouse=True)
def iWBTC(accounts, BZX, LoanTokenLogicStandard, WBTC):
    iWBTCAddress = BZX.underlyingToLoanPool(WBTC)
    return Contract.from_abi("iWBTC", address=iWBTCAddress, abi=LoanTokenLogicStandard.abi, owner=accounts[0])

@pytest.fixture(scope="class", autouse=True)
def iUSDT(accounts, BZX, LoanTokenLogicStandard, USDT):
    iUSDTAddress = BZX.underlyingToLoanPool(USDT)
    return Contract.from_abi("iUSDT", address=iUSDTAddress, abi=LoanTokenLogicStandard.abi, owner=accounts[0])


@pytest.fixture(scope="class", autouse=True)
def bgovToken(accounts, BGovToken):
    return accounts[0].deploy(BGovToken);

@pytest.fixture(scope="class", autouse=True)
def masterChef(accounts, chain, MasterChef, iWBNB, iETH, iBUSD, iWBTC, iUSDT, bgovToken):
    devAccount = accounts[0]
    bgovPerBlock = 100*10**18
    bonusEndBlock = chain.height + 1*10**6

    startBlock = chain.height

    masterChef = accounts[0].deploy(MasterChef, bgovToken, devAccount, bgovPerBlock, startBlock, bonusEndBlock)
    allocPoint = 1
    bgovToken.transferOwnership(masterChef);
    masterChef.add(allocPoint, iWBNB, 1)
    masterChef.add(allocPoint, iETH, 1)
    masterChef.add(allocPoint, iBUSD, 1)
    masterChef.add(allocPoint, iWBTC, 1)
    masterChef.add(allocPoint, iUSDT, 1)

    return masterChef;


@pytest.fixture(scope="class", autouse=True)
def tokens(accounts, chain, MasterChef, iWBNB, WBNB, iBUSD, BUSD):
    return {
        'iWBNB': iWBNB,
        'iBUSD': iBUSD,
        'WBNB': WBNB,
        'BUSD': BUSD
    }
