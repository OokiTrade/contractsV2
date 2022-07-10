import pytest
from brownie import *
from eth_abi import encode_abi

@pytest.fixture(scope="module")
def DEPOSITS(interface, ORDERBOOK):
    return interface.IDeposits(ORDERBOOK.VAULT())

@pytest.fixture(scope="module")
def TOKEN_REGISTRY(TokenRegistry):
    return Contract.from_abi("TOKEN_REGISTRY", "0x4B234781Af34E9fD756C27a47675cbba19DC8765", TokenRegistry.abi)

@pytest.fixture(scope="module")
def ORDERBOOK(interface):
    return Contract.from_abi("ORDERBOOK", "0x043582611b2d62ee084d72f0e731883653f837ce", interface.IOrderBook.abi)

@pytest.fixture(scope="module")
def USDC(TestToken):
    return Contract.from_abi("USDC","0x2791Bca1f2de4661ED88A30C99A7a9449Aa84174",TestToken.abi)

@pytest.fixture(scope="module")
def ETH(TestToken):
    return Contract.from_abi("ETH","0x7ceB23fD6bC0adD59E62ac25578270cFf1b9f619",TestToken.abi)

@pytest.fixture(scope="module")
def WMATIC(TestToken):
    return Contract.from_abi("WMATIC","0x0d500B1d8E8eF31E21C99d1Db9A6444d3ADf1270",TestToken.abi)

@pytest.fixture(scope="module")
def IUSDC(interface):
    return Contract.from_abi("IUSDC","0xC3f6816C860e7d7893508C8F8568d5AF190f6d7d",interface.IToken.abi)

@pytest.fixture(scope="module")
def IBZX(interface):
    return interface.IBZx("0x059D60a9CEfBc70b9Ea9FFBb9a041581B1dFA6a8")

#test case 1. place limit open order and execute as well as limit close
def test_case1(ORDERBOOK, DEPOSITS, USDC, IUSDC, ETH, WMATIC, IBZX):
    ob = ORDERBOOK
    deposits = DEPOSITS

    #get some USDC
    USDC.transfer(accounts[0], 10000e6, {'from':"0xf977814e90da44bfa03b6295a0616a897441acec"})
    USDC.approve(deposits, 10000e6, {'from':accounts[0]})

    #deposit gas token
    WMATIC.approve(deposits, 100e18, {"from":accounts[0]})
    ob.depositGasFeeToken(0, {'from':accounts[0], 'value':100e18})

    #place open order
    setManager = encode_abi(['address'],[ob.address])
    dex_payload = encode_abi(['address','address'],[USDC.address,ETH.address])
    dex_selector = encode_abi(['uint256','bytes'],[1,dex_payload])
    loanDataBytes = encode_abi(['uint256','bytes[]'],[6,(dex_selector,setManager)])    
    ob.placeOrder([0, 0, 1e6, 1e18, int(100e6), 0, accounts[0],
        IUSDC, USDC, ETH, 0, 0, 1000000000000, loanDataBytes], {'from': accounts[0]})
    assert(ob.getUserOrdersCount(accounts[0]) == 1)
    assert(ob.getGlobalOrdersCount() > 1)
    orderID = ob.getUserOrderIDs(accounts[0])[0]
    assert(ob.prelimCheck.call(orderID) == True)

    balanceBefore = WMATIC.balanceOf(accounts[0])
    #execute order
    ob.executeOrder(orderID, {'from':accounts[0]})
    assert(WMATIC.balanceOf(accounts[0]) > balanceBefore)
    assert(IBZX.getUserLoansCount(accounts[0], False) == 1)

    #place close order
    orderToClose = IBZX.getUserLoans(accounts[0],0,10,0,False,False)[0]
    ob.placeOrder([orderToClose[0], 0, orderToClose[4], 0, 0, orderToClose[5], accounts[0], IUSDC, USDC, ETH, 1, 0, 1000000000000, b''], {'from': accounts[0]})
    assert(ob.getUserOrdersCount(accounts[0]) == 1)
    assert(ob.getGlobalOrdersCount() > 1)
    orderID = ob.getUserOrderIDs(accounts[0])[0]
    assert(ob.prelimCheck.call(orderID) == True)

    balanceBefore = WMATIC.balanceOf(accounts[0])
    #execute order
    ob.executeOrder(orderID, {'from':accounts[0]})
    assert(WMATIC.balanceOf(accounts[0]) > balanceBefore)
    assert(IBZX.getUserLoansCount(accounts[0], False) == 0)


#test case 2. place limit open order and execute as well as market stop w/o oracle
def test_case2(ORDERBOOK, DEPOSITS, USDC, IUSDC, ETH, WMATIC, IBZX):
    ob = ORDERBOOK
    deposits = DEPOSITS

    #get some USDC
    USDC.transfer(accounts[0], 10000e6, {'from':"0xf977814e90da44bfa03b6295a0616a897441acec"})
    USDC.approve(deposits, 10000e6, {'from':accounts[0]})

    #deposit gas token
    WMATIC.approve(deposits, 100e18, {"from":accounts[0]})
    ob.depositGasFeeToken(0, {'from':accounts[0], 'value':100e18})

    #place open order
    setManager = encode_abi(['address'],[ob.address])
    dex_payload = encode_abi(['address','address'],[USDC.address,ETH.address])
    dex_selector = encode_abi(['uint256','bytes'],[1,dex_payload])
    loanDataBytes = encode_abi(['uint256','bytes[]'],[6,(dex_selector,setManager)])    
    ob.placeOrder([0, 0, 1e6, 1e18, int(100e6), 0, accounts[0],
        IUSDC, USDC, ETH, 0, 0, 1000000000000, loanDataBytes], {'from': accounts[0]})
    assert(ob.getUserOrdersCount(accounts[0]) == 1)
    assert(ob.getGlobalOrdersCount() > 1)
    orderID = ob.getUserOrderIDs(accounts[0])[0]
    assert(ob.prelimCheck.call(orderID) == True)

    balanceBefore = WMATIC.balanceOf(accounts[0])
    #execute order
    ob.executeOrder(orderID, {'from':accounts[0]})
    assert(WMATIC.balanceOf(accounts[0]) > balanceBefore)
    assert(IBZX.getUserLoansCount(accounts[0], False) == 1)

    #place close order
    orderToClose = IBZX.getUserLoans(accounts[0],0,10,0,False,False)[0]
    ob.placeOrder([orderToClose[0], 0, orderToClose[4]*10, 0, 0, orderToClose[5], accounts[0], IUSDC, USDC, ETH, 2, 0, 1000000000000, b''], {'from': accounts[0]})
    assert(ob.getUserOrdersCount(accounts[0]) == 1)
    assert(ob.getGlobalOrdersCount() > 1)
    orderID = ob.getUserOrderIDs(accounts[0])[0]
    assert(ob.prelimCheck.call(orderID) == True)

    balanceBefore = WMATIC.balanceOf(accounts[0])
    #execute order
    ob.executeOrder(orderID, {'from':accounts[0]})
    assert(WMATIC.balanceOf(accounts[0]) > balanceBefore)
    assert(IBZX.getUserLoansCount(accounts[0], False) == 0)

#test case 3. place limit open order and execute as well as market stop w/ oracle
def test_case3(ORDERBOOK, DEPOSITS, USDC, IUSDC, ETH, WMATIC, IBZX):
    ob = ORDERBOOK
    deposits = DEPOSITS

    #get some USDC
    USDC.transfer(accounts[0], 10000e6, {'from':"0xf977814e90da44bfa03b6295a0616a897441acec"})
    USDC.approve(deposits, 10000e6, {'from':accounts[0]})

    #deposit gas token
    WMATIC.approve(deposits, 100e18, {"from":accounts[0]})
    ob.depositGasFeeToken(0, {'from':accounts[0], 'value':100e18})

    #place open order
    setManager = encode_abi(['address'],[ob.address])
    dex_payload = encode_abi(['address','address'],[USDC.address,ETH.address])
    dex_selector = encode_abi(['uint256','bytes'],[1,dex_payload])
    loanDataBytes = encode_abi(['uint256','bytes[]'],[6,(dex_selector,setManager)])    
    ob.placeOrder([0, 0, 1e6, 1e18, int(100e6), 0, accounts[0],
        IUSDC, USDC, ETH, 0, 0, 1000000000000, loanDataBytes], {'from': accounts[0]})
    assert(ob.getUserOrdersCount(accounts[0]) == 1)
    assert(ob.getGlobalOrdersCount() > 1)
    orderID = ob.getUserOrderIDs(accounts[0])[0]
    assert(ob.prelimCheck.call(orderID) == True)

    balanceBefore = WMATIC.balanceOf(accounts[0])
    #execute order
    ob.executeOrder(orderID, {'from':accounts[0]})
    assert(WMATIC.balanceOf(accounts[0]) > balanceBefore)
    assert(IBZX.getUserLoansCount(accounts[0], False) == 1)

    #change stop type
    ob.changeStopType(True, {'from':accounts[0]})

    #place close order
    orderToClose = IBZX.getUserLoans(accounts[0],0,10,0,False,False)[0]
    ob.placeOrder([orderToClose[0], 0, orderToClose[4]*10, 0, 0, orderToClose[5], accounts[0], IUSDC, USDC, ETH, 2, 0, 1000000000000, b''], {'from': accounts[0]})
    assert(ob.getUserOrdersCount(accounts[0]) == 1)
    assert(ob.getGlobalOrdersCount() > 1)
    orderID = ob.getUserOrderIDs(accounts[0])[0]
    assert(ob.prelimCheck.call(orderID) == True)

    balanceBefore = WMATIC.balanceOf(accounts[0])
    #execute order
    ob.executeOrder(orderID, {'from':accounts[0]})
    assert(WMATIC.balanceOf(accounts[0]) > balanceBefore)
    assert(IBZX.getUserLoansCount(accounts[0], False) == 0)

#test case 4. place limit open order and execute as well as market stop w/ oracle and min amount out
def test_case4(ORDERBOOK, DEPOSITS, USDC, IUSDC, ETH, WMATIC, IBZX):
    ob = ORDERBOOK
    deposits = DEPOSITS

    #get some USDC
    USDC.transfer(accounts[0], 10000e6, {'from':"0xf977814e90da44bfa03b6295a0616a897441acec"})
    USDC.approve(deposits, 10000e6, {'from':accounts[0]})

    #deposit gas token
    WMATIC.approve(deposits, 100e18, {"from":accounts[0]})
    ob.depositGasFeeToken(0, {'from':accounts[0], 'value':100e18})

    #place open order
    setManager = encode_abi(['address'],[ob.address])
    dex_payload = encode_abi(['address','address'],[USDC.address,ETH.address])
    dex_selector = encode_abi(['uint256','bytes'],[1,dex_payload])
    loanDataBytes = encode_abi(['uint256','bytes[]'],[6,(dex_selector,setManager)])    
    ob.placeOrder([0, 0, 1e6, 1e18, int(100e6), 0, accounts[0],
        IUSDC, USDC, ETH, 0, 0, 1000000000000, loanDataBytes], {'from': accounts[0]})
    assert(ob.getUserOrdersCount(accounts[0]) == 1)
    assert(ob.getGlobalOrdersCount() > 1)
    orderID = ob.getUserOrderIDs(accounts[0])[0]
    assert(ob.prelimCheck.call(orderID) == True)

    balanceBefore = WMATIC.balanceOf(accounts[0])
    #execute order
    ob.executeOrder(orderID, {'from':accounts[0]})
    assert(WMATIC.balanceOf(accounts[0]) > balanceBefore)
    assert(IBZX.getUserLoansCount(accounts[0], False) == 1)

    #change stop type
    ob.changeStopType(True, {'from':accounts[0]})

    #place close order
    orderToClose = IBZX.getUserLoans(accounts[0],0,10,0,False,False)[0]
    ob.placeOrder([orderToClose[0], 0, orderToClose[4]*10, orderToClose[4], 0, orderToClose[5], accounts[0], IUSDC, USDC, ETH, 2, 0, 1000000000000, b''], {'from': accounts[0]})
    assert(ob.getUserOrdersCount(accounts[0]) == 1)
    assert(ob.getGlobalOrdersCount() > 1)
    orderID = ob.getUserOrderIDs(accounts[0])[0]
    assert(ob.prelimCheck.call(orderID) == True)

    balanceBefore = WMATIC.balanceOf(accounts[0])
    #execute order
    ob.executeOrder(orderID, {'from':accounts[0]})
    assert(WMATIC.balanceOf(accounts[0]) > balanceBefore)
    assert(IBZX.getUserLoansCount(accounts[0], False) == 0)