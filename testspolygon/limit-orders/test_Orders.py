from brownie import *
from eth_abi import encode_abi

def test_t():
    ORDERBOOK = interface.IOrderBook('0x9A3B9d4379Ec31aA527cB226890412Ef40A3C1c8')
    print(ORDERBOOK.getDexRate.call(
        "0x7ceB23fD6bC0adD59E62ac25578270cFf1b9f619", "0x2791Bca1f2de4661ED88A30C99A7a9449Aa84174", b'', 1e18))
    print(ORDERBOOK.queryRateReturn.call(
        "0x7ceB23fD6bC0adD59E62ac25578270cFf1b9f619", "0x2791Bca1f2de4661ED88A30C99A7a9449Aa84174", 1e18))

    print(ORDERBOOK.priceCheck.call(
        "0x7ceB23fD6bC0adD59E62ac25578270cFf1b9f619", "0x2791Bca1f2de4661ED88A30C99A7a9449Aa84174", b''))
    USDC = interface.IERC20('0x2791Bca1f2de4661ED88A30C99A7a9449Aa84174')
    iUSDC = interface.IERC20('0xC3f6816C860e7d7893508C8F8568d5AF190f6d7d')
    ETH = interface.IERC20('0x7ceB23fD6bC0adD59E62ac25578270cFf1b9f619')
    USDC.transfer(accounts[0], 20e6, {
                  'from': '0xf977814e90da44bfa03b6295a0616a897441acec'})
    USDC.approve(ORDERBOOK.vault(), 2e10, {'from': accounts[0]})
    data = encode_abi(['address'],[ORDERBOOK.address])
    data = encode_abi(['uint256','bytes[]'],[6,(encode_abi(['uint256','bytes'],[1,encode_abi(['address','address'],[USDC.address,ETH.address])]),data)])
    print(ORDERBOOK.placeOrder([0, 0, 1e6, 1e18, int(1.1e6), 0, accounts[0],
                         iUSDC, USDC, ETH, 0, 0, 1000000000000, data], {'from': accounts[0]}).gas_used)
    print(ORDERBOOK.getOrders.call()[0])
    print(ORDERBOOK.executeOrder(ORDERBOOK.getOrders.call()[0][1],{'from':accounts[0]}).gas_used)
    protocolRank = interface.IBZx(ORDERBOOK.protocol.call())
    ll = protocolRank.getUserLoans.call(accounts[0],0,10,0,False,False)
    print(ll)
    print(ORDERBOOK.placeOrder([ll[0][0],0,1e18,0,0,374183490999849,accounts[0],
                         iUSDC, USDC, ETH, 2, 0, 1000000000000, b''], {'from': accounts[0]}).gas_used)
    ORDERBOOK.changeStopType(True, {'from':accounts[0]})
    print(ORDERBOOK.getActiveOrders.call(accounts[0]))
    print(ORDERBOOK.getActiveOrdersLimited.call(accounts[0],0,ORDERBOOK.getTotalOrders.call(accounts[0])))
    print(ORDERBOOK.getActiveOrderIDs.call(accounts[0]))
    print(ORDERBOOK.getTotalOrderIDs.call())
    print(ORDERBOOK.getOrderIDs.call())
    print(ORDERBOOK.getOrderIDsLimited.call(0,ORDERBOOK.getTotalOrderIDs.call()))
    print(ORDERBOOK.getOrdersLimited.call(0,ORDERBOOK.getTotalOrderIDs.call()))
    print(ORDERBOOK.clearOrder.call(ORDERBOOK.getOrderIDs.call()[0]))
    keeper = deploy_keeper(ORDERBOOK)
    print(keeper.checkUpKeep(encode_abi(['uint256','uint256'],[0,1]),{'from':accounts[0]}).gas_used)
    (needed, data) = keeper.checkUpKeep.call(encode_abi(['uint256','uint256'],[0,1]))
    if(needed):
        keeper.performUpKeep(data, {'from':accounts[0]})
    print(ORDERBOOK.getOrders.call())
    ll = protocolRank.getUserLoans.call(accounts[0],0,10,0,False,False)
    print(ll)
    assert(False)

def deploy_keeper(ORDERBOOK):
    keeper = OrderKeeper.deploy({'from':accounts[0]})
    proxy = Proxy_0_8.deploy(keeper, {'from':accounts[0]})
    keeper = Contract.from_abi('',proxy.address,OrderKeeper.abi)
    keeper.setOrderBook(ORDERBOOK,{'from':accounts[0]})
    return keeper