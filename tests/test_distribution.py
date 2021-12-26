from brownie import *

def test_distribute():
    deployingAddress = '0x55FE002aefF02F77364de339a1292923A15844B8' #large ETH Balance source
    USDCsource = '0x55fe002aeff02f77364de339a1292923a15844b8' #large USDC balance source
    gas = 150e9
    USDC = '0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48'
    logic = ConvertAndAdminister.deploy({'from':deployingAddress,'gas_price':gas})
    proxy = Proxy_0_8.deploy(logic.address,{'from':deployingAddress,'gas_price':gas})
    Distribution = Contract.from_abi('Distribution',proxy.address,ConvertAndAdminister.abi)
    Distribution.initialize('0xe95Ebce2B02Ee07dEF5Ed6B53289801F7Fc137A4',{'from':deployingAddress,'gas_price':gas})
    interface.IERC20(USDC).transfer(Distribution.address,100000e6,{'from':USDCsource,'gas_price':gas}) #100k USDC
    Distribution.setApprovals(USDC,Distribution.pool3.call(),100000000e6,{'from':deployingAddress,'gas_price':gas})
    Distribution.setApprovals(Distribution.crv3.call(),'0xe95Ebce2B02Ee07dEF5Ed6B53289801F7Fc137A4',10000000000e18,{'from':deployingAddress,'gas_price':gas})
    initBalance = interface.IStaking(Distribution.Staking.call()).earned.call('0x7a1d27e928ccfeaa2c5182031aeb6f2ecb07ea13')[1]
    Distribution.distributeFees({'from':deployingAddress,'gas_price':gas})
    newBalance = interface.IStaking(Distribution.Staking.call()).earned.call('0x7a1d27e928ccfeaa2c5182031aeb6f2ecb07ea13')[1]
    assert(newBalance>=initBalance) #checks if new stablecoin balance > old stablecoin balance
