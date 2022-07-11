import pytest
from brownie import *

@pytest.fixture(scope="module")
def BZX(interface):
    return interface.IBZx("0x059D60a9CEfBc70b9Ea9FFBb9a041581B1dFA6a8")

@pytest.fixture(scope="module")
def USDC(TestToken):
    return Contract.from_abi("USDC","0x2791Bca1f2de4661ED88A30C99A7a9449Aa84174",TestToken.abi)

@pytest.fixture(scope="module")
def WETH(TestToken):
    return Contract.from_abi("WETH","0x7ceB23fD6bC0adD59E62ac25578270cFf1b9f619",TestToken.abi)

@pytest.fixture(scope="module")
def upgradeBZX(BZX, SwapsExternal):
    BZX.replaceContract(accounts[0].deploy(SwapsExternal), {'from':BZX.owner()})
    
#test case 1. Tests return amount when specifying amount in or amount out
def test_case1(BZX, upgradeBZX, USDC,WETH):
    #data for getting amount out
    tokenIn = USDC
    tokenOut = WETH
    sourceAmount = 1e6
    isAmountIn = True

    #get return amount
    receivedAmount = BZX.getSwapExpectedReturn.call(accounts[0], tokenIn, tokenOut, sourceAmount, b'', isAmountIn)
    print(receivedAmount)
    assert(receivedAmount >= 8e14)

    #data for getting amount in
    tokenIn = USDC
    tokenOut = WETH
    outAmount = 1e18
    isAmountIn = False

    #get return amount
    receivedAmount = BZX.getSwapExpectedReturn.call(accounts[0], tokenIn, tokenOut, outAmount, b'', isAmountIn)
    print(receivedAmount)
    assert(receivedAmount >= 200e6)
    assert(receivedAmount <= 20000e6)    