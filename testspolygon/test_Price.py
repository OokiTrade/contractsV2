from brownie import *
from eth_abi import encode_abi, is_encodable, encode_single
from eth_abi.packed import encode_single_packed, encode_abi_packed
from hexbytes import HexBytes
import pytest

deployer = '0xf39fd6e51aad88f6f4ce6ab8827279cfffb92266'
GasPrice = 30e9
token0 = '0x2791Bca1f2de4661ED88A30C99A7a9449Aa84174'
token1 = '0x83000597e8420ad7e9edd410b2883df1b83823cf'
pool = '0x0d1375f18E23099AE6a151E818cfE491B4FefF31'
USDCAmount = 1e8
def test_price():
    logic = BuyBackAndBurn.deploy({'from':deployer,'gas_price':GasPrice})
    proxy = Proxy_0_8.deploy(logic.address,{'from':deployer,'gas_price':GasPrice})
    BuyBack = Contract.from_abi('',proxy.address,BuyBackAndBurn.abi)
    interface.IERC20(token0).transfer(BuyBack.address,USDCAmount,{'from':'0x06959153B974D0D5fDfd87D561db6d8d4FA0bb0B','gas_price':GasPrice})
    Price = PriceGetterP125.deploy({'from':deployer,'gas_price':GasPrice})
    route = encode_abi_packed(['address','uint24','address'],[token0,3000,token1])
    chain.mine(500)
    params = [token0,token1,pool,1e6,300,route]
    BuyBack.setTWAPSpecs(params,{'from':deployer,'gas_price':GasPrice})
    BuyBack.setPriceGetter(Price.address,{'from':deployer,'gas_price':GasPrice})
    BuyBack.setMaxPriceDisagreement(9*10**19,{'from':deployer,'gas_price':GasPrice})
    print(Price.worstExecPrice(params))
    print(BuyBack.worstExecPrice())
    print(BuyBack.getDebtTokenAmountOut.call(USDCAmount))
    BuyBack.setTreasuryWallet(deployer,{'from':deployer,'gas_price':GasPrice})
    BuyBack.setApproval({'from':deployer,'gas_price':GasPrice})
    BuyBack.buyBack(1e20,{'from':deployer,'gas_price':GasPrice})
    BuyBack.sendToTreasury({'from':deployer,'gas_price':GasPrice})
    assert(interface.IERC20(token1).balanceOf(BuyBack.treasuryWallet.call()) > 0)
    assert(False)
