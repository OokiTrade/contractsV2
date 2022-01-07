from brownie import *
import pytest

deployer = '0xf39fd6e51aad88f6f4ce6ab8827279cfffb92266'
GasPrice = 600e9
USDC = '0x2791Bca1f2de4661ED88A30C99A7a9449Aa84174'
assets = ['0x2791Bca1f2de4661ED88A30C99A7a9449Aa84174','0x0d500B1d8E8eF31E21C99d1Db9A6444d3ADf1270','0x7ceb23fd6bc0add59e62ac25578270cff1b9f619',
          '0xc2132d05d31c914a87c6611c10748aeb04b58e8f','0x1BFD67037B42Cf73acF2047067bd4F2C47D9BfD6','0x53e0bca35ec356bd5dddfebbd1fc0fd03fabad39']
treasury = '0x70997970c51812dc3a010c7d01b50e0d17dc79c8'
protocol = '0x059D60a9CEfBc70b9Ea9FFBb9a041581B1dFA6a8'
def test_SweepFees():
    distribute = FeeExtractAndDistribute_Polygon.deploy({'from':deployer,'gas_price':GasPrice})
    FeeControl = Proxy_0_8.deploy(distribute.address, {'from':deployer,'gas_price':GasPrice})
    FeeControl = Contract.from_abi('fees', FeeControl.address, FeeExtractAndDistribute_Polygon.abi)
    FeeControl.setTreasuryWallet(treasury, {'from':deployer,'gas_price':GasPrice})
    FeeControl.setFeeTokens(assets, {'from':deployer,'gas_price':GasPrice})
    bZx = interface.IBZx(protocol)
    accounts.at(treasury, force=True).transfer(bZx.owner.call(), 100e18, required_confs=0, gas_price=100e9)
    bZx.setFeesController(FeeControl.address, {'from':bZx.owner.call(),'gas_price':GasPrice})
    FeeControl.sweepFees({'from':deployer,'gas_price':GasPrice})
    assert(interface.IERC20(USDC).balanceOf(FeeControl.treasuryWallet.call()) > 0) #ensures balance has
    assert(sum(bZx.queryFees.call(assets,0)[0]) == 0) #ensures all fees for all assets are 0 as if sum of query > 0 then all were not withdrawn
    for tokens in assets: 
        assert(interface.IERC20(tokens).balanceOf(FeeControl.address) == 0) #checks to make sure extract contract is emptied for all tokens
