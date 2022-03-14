from brownie import *
import pytest
from eth_abi import encode_abi
accounts = ['0xf39fd6e51aad88f6f4ce6ab8827279cfffb92266']

def test_main():
    orderbook, keeper = deploy_contracts()
    set_perms(orderbook)
    orderbook = interface.IOrderBook(orderbook.address)
    place_order_open(orderbook)
    print(orderbook.prelimCheck.call(orderbook.getActiveOrders(accounts[0])[0][1]))
    orderbook.executeOrder(orderbook.getActiveOrders(accounts[0])[0][1], {'from':accounts[0]})
    trades = interface.IBZx('0x37407F3178ffE07a6cF5C847F8f680FEcf319FAB').getUserLoans(accounts[0],0,10,0,False,False)
    print(trades)
    place_order_close(orderbook, trades[0][0], int(7.4e14))
    print(orderbook.getOrders())
    isExec, data = keeper.checkUpKeep.call(encode_abi(['uint256','uint256'],[0,orderbook.getTotalActiveOrders()]))
    keeper.checkUpKeep(encode_abi(['uint256','uint256'],[0,orderbook.getTotalActiveOrders()]), {'from':accounts[0]})
    if(isExec):
        keeper.performUpKeep(data)
    print(orderbook.getActiveOrders(accounts[0]))
    trades = interface.IBZx('0x37407F3178ffE07a6cF5C847F8f680FEcf319FAB').getUserLoans(accounts[0],0,10,0,False,False)
    print(trades)
    assert(False)

def deploy_contracts():
    orderbook = OrderBookProxy.deploy('0x37407F3178ffE07a6cF5C847F8f680FEcf319FAB', {'from':accounts[0]})
    orderbookLogic = OrderBook.deploy({'from':accounts[0]})
    orderBookData = OrderBookData.deploy({'from':accounts[0]})
    orderBookOrderPlace = OrderBookOrderPlace.deploy({'from':accounts[0]})
    orderbook.replaceContract(orderbookLogic.address, {'from':orderbook.owner()})
    orderbook.replaceContract(orderBookData.address, {'from':orderbook.owner()})
    orderbook.replaceContract(orderBookOrderPlace.address, {'from':orderbook.owner()})
    d = Deposits.deploy({'from':accounts[0]})
    d.setOrderBook(orderbook.address, {'from':accounts[0]})
    Contract.from_abi('',orderbook.address,OrderBook.abi).setVaultAddress(d.address, {'from':orderbook.owner()})
    keeper = OrderKeeper.deploy(orderbook.address, {'from':accounts[0]})
    BZX = interface.IBZx('0x37407F3178ffE07a6cF5C847F8f680FEcf319FAB')
    bzx = Contract.from_abi('',BZX.address,bZxProtocol.abi)
    LoanOpening = LoanOpenings.deploy({'from':bzx.owner()})
    bzx.replaceContract(LoanOpening.address, {'from':bzx.owner()})
    return orderbook, keeper

def set_perms(orderbook):
    Contract.from_abi('',orderbook.address,OrderBookData.abi).adjustAllowance('0xEDa7f294844808B7C93EE524F990cA7792AC2aBd',
        '0xFF970A61A04b1cA14834A43f5dE4533eBDDB5CC8', {'from':orderbook.owner()})
    interface.IERC20('0xFF970A61A04b1cA14834A43f5dE4533eBDDB5CC8').transfer(accounts[0], 200e6, {'from':'0x489ee077994b6658eafa855c308275ead8097c4a'})
    interface.IERC20('0xFF970A61A04b1cA14834A43f5dE4533eBDDB5CC8').approve(orderbook.vault.call(), 2000e6, {'from':accounts[0]})
def place_order_open(orderbook_contract):
    payload = encode_abi(['uint128','bytes[]'],[4,[b'',encode_abi(['address'], [orderbook_contract.address])]])
    orderdata = [0,0,3e14,2e18,1e6,0,(1647152473+60*60*24*30),accounts[0],
                '0xEDa7f294844808B7C93EE524F990cA7792AC2aBd','0xFF970A61A04b1cA14834A43f5dE4533eBDDB5CC8','0x82aF49447D8a07e3bd95BD0d56f35241523fBab1',
                0,False,False,payload]
    orderbook_contract.placeOrder(orderdata, {'from':accounts[0]})

def place_order_close(orderbook_contract, position, size):
    orderdata = [position,0,10,0,0,size,(1647152473+60*60*24*30),accounts[0],
                '0xEDa7f294844808B7C93EE524F990cA7792AC2aBd','0xFF970A61A04b1cA14834A43f5dE4533eBDDB5CC8','0x82aF49447D8a07e3bd95BD0d56f35241523fBab1',
                1,False,False,b'']
    orderbook_contract.placeOrder(orderdata, {'from':accounts[0]})

def amend_order():
    print()

def cancel_order(orderbook_contract, position):
    orderbook_contract.cancelOrder(position, {'from':accounts[0]})

def get_order_specs(orderID):
    return
