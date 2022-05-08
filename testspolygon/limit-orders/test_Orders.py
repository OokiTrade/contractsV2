from brownie import *
from eth_abi import encode_abi

def test_t():
    ORDERBOOK = interface.IOrderBook('0x043582611B2d62Ee084D72f0E731883653f837CE')
    upgrade_contracts(ORDERBOOK)
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
    USDC.approve(ORDERBOOK.VAULT(), 2e10, {'from': accounts[0]})
    interface.IERC20('0x0d500B1d8E8eF31E21C99d1Db9A6444d3ADf1270').approve(ORDERBOOK.VAULT(), 2e18, {'from':accounts[0]})
    ORDERBOOK.depositGasFeeToken(0, {'from':accounts[0], 'amount':1e18})
    print(interface.IDeposits(ORDERBOOK.VAULT()).getDeposit(web3.keccak(encode_abi(['address','uint256'],[accounts[0].address,0]))))
    print(ORDERBOOK.getGasPrice())
    data = encode_abi(['address'],[ORDERBOOK.address])
    data = encode_abi(['uint256','bytes[]'],[6,(encode_abi(['uint256','bytes'],[1,encode_abi(['address','address'],[USDC.address,ETH.address])]),data)])
    print(ORDERBOOK.placeOrder([0, 0, 1e6, 1e18, int(1.1e6), 0, accounts[0],
                         iUSDC, USDC, ETH, 0, 0, 1000000000000, data], {'from': accounts[0]}).gas_used)
    print(ORDERBOOK.getOrders.call()[0])
    print(ORDERBOOK.executeOrder(ORDERBOOK.getOrders.call()[0][1],{'from':accounts[0]}).gas_used)
    print(interface.IDeposits(ORDERBOOK.VAULT()).getDeposit(web3.keccak(encode_abi(['address','uint256'],[accounts[0].address,0]))))
    protocolRank = interface.IBZx(ORDERBOOK.PROTOCOL.call())
    ll = protocolRank.getUserLoans.call(accounts[0],0,10,0,False,False)
    print(ll)
    print(ORDERBOOK.placeOrder([ll[0][0],0,1e18,0,0,ll[0][5],accounts[0],
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
    print(keeper.checkUpkeep(encode_abi(['uint256','uint256'],[0,1]),{'from':accounts[0]}).gas_used)
    (needed, data) = keeper.checkUpkeep.call(encode_abi(['uint256','uint256'],[0,1]))
    if(needed):
        keeper.performUpkeep(data, {'from':accounts[0]})
    print(ORDERBOOK.getOrders.call())
    ll = protocolRank.getUserLoans.call(accounts[0],0,10,0,False,False)
    print(ll)
    assert(False)

def upgrade_contracts(ORDERBOOK):
    main = OrderBook.deploy({'from':accounts[0]})
    data = OrderBookData.deploy({'from':accounts[0]})
    placement = OrderBookOrderPlace.deploy({'from':accounts[0]})
    ORDERBOOK = Contract.from_abi('',ORDERBOOK.address,OrderBookProxy.abi)
    ORDERBOOK.replaceContract(main,{'from':ORDERBOOK.owner()})
    ORDERBOOK.replaceContract(data,{'from':ORDERBOOK.owner()})
    ORDERBOOK.replaceContract(placement,{'from':ORDERBOOK.owner()})
    interface.IOrderBook(ORDERBOOK).setPriceFeed('0x600F8E7B10CF6DA18871Ff79e4A61B13caCEd9BC',{'from':ORDERBOOK.owner()})

def deploy_keeper(ORDERBOOK):
    keeper = OrderKeeper.deploy({'from':accounts[0]})
    proxy = Proxy_0_8.deploy(keeper, {'from':accounts[0]})
    keeper = Contract.from_abi('',proxy.address,OrderKeeper.abi)
    keeper.setOrderBook(ORDERBOOK,{'from':accounts[0]})
    return keeper