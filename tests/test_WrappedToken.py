from brownie import *

def test_initTokens():
    GasPrice = 10000
    deployAddress = '0x6555e1CC97d3cbA6eAddebBCD7Ca51d75771e0B8'
    logicUSDC = WrappedIUSDC.deploy({'from':deployAddress,'gas_price':GasPrice})
    logicUSDT = WrappedIUSDT.deploy({'from':deployAddress,'gas_price':GasPrice})
    wIUSDC = Proxy_0_8.deploy(logicUSDC.address,{'from':deployAddress,'gas_price':GasPrice})
    wIUSDT = Proxy_0_8.deploy(logicUSDT.address,{'from':deployAddress,'gas_price':GasPrice})
    wIUSDC.initialize({'from':deployAddress,'gas_price':GasPrice})
    wIUSDT.initialize({'from':deployAddress,'gas_price':GasPrice})
    print(wIUSDC.address)
    print(wIUSDT.address)
    assert(False)

def token():
    GasPrice = 10000
    wIUSDC = Contract.from_abi('WIUSDC','',WrappedIUSDC.abi) #provide address
    wIUSDT = Contract.from_abi('WIUSDT','',WrappedIUSDT.abi) #provide address 
    CurveContract = "0xB9fC157394Af804a3578134A6585C0dc9cc990d4"
    #deploy Curve Pool for tokens beforehand
    cc = interface.ICurve(CurveContract)
    iUSDC = interface.IERC20('0x32E4c68B3A4a813b710595AebA7f6B7604Ab9c15')
    iUSDT = interface.IERC20('0x7e9997a38A439b2be7ed9c9C4628391d3e055D48')
    impersonate = "0x5963a43002F74B5bDe0a44F7AC5bb59015b66118"
    impersonateIUSDT = "0x936805cf02Ba243D11aF7C68959cbDa0b99e83Dd"
    interface.IERC20('0x32E4c68B3A4a813b710595AebA7f6B7604Ab9c15').approve(wIUSDC.address,1e30,{'from':impersonate,'gas_price':GasPrice})
    wIUSDC.mintFromIToken(impersonate,1e9,{'from':impersonate,'gas_price':GasPrice})
    interface.IERC20('0x7e9997a38A439b2be7ed9c9C4628391d3e055D48').approve(wIUSDT.address,1e30,{'from':impersonateIUSDT,'gas_price':GasPrice})
    wIUSDT.mintFromIToken(impersonate,1e9,{'from':impersonateIUSDT,'gas_price':GasPrice})
    cc = interface.ICurve(cc.find_pool_for_coins.call(wIUSDC.address,wIUSDT.address,0))
    print(wIUSDC.balanceOf.call(impersonate))
    print(wIUSDT.balanceOf.call(impersonate))
    interface.IERC20(wIUSDC.address).approve(cc.address,1e30,{'from':impersonate,'gas_price':GasPrice})
    interface.IERC20(wIUSDT.address).approve(cc.address,1e30,{'from':impersonate,'gas_price':GasPrice})
    cc.add_liquidity([1e8,1e8],0,impersonate,{'from':impersonate,'gas_price':GasPrice})
    print(iUSDC.balanceOf.call(impersonate))
    wIUSDC.burnToIToken(impersonate,1e6,{'from':impersonate,'gas_price':GasPrice})
    print(iUSDC.balanceOf.call(impersonate))
    oldBalanceOfUnderlying = wIUSDT.balanceOfUnderlying.call(impersonate)
    print(oldBalanceOfUnderlying)
    tValue = cc.exchange(0,1,1e6,0,{'from':impersonate,'gas_price':GasPrice}).return_value
    print(tValue)
    print(wIUSDT.balanceOfUnderlying.call(impersonate))
    randomReceiver = '0xFc0556090C98a1D3045ff3aCA2cb4aD26C3445Ce'
    wIUSDT.burnToIToken(randomReceiver,wIUSDT.balanceOfUnderlying.call(impersonate)-oldBalanceOfUnderlying,{'from':impersonate,'gas_price':GasPrice})
    print(interface.IERC20(wIUSDT.iTokenAddress.call()).balanceOf.call(randomReceiver))
    print(wIUSDC.tokenPrice.call())
    print(wIUSDT.tokenPrice.call())
    assert(False)
