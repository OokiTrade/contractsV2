from brownie import *
from eth_abi import encode_abi, is_encodable, encode_single

def test_t():
    WETH = "0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2"
    wstETH = "0x7f39C581F595B53c5cb19bD0b3f8dA6c935E2Ca0"
    stETH = SwapsImplstETH_ETH.deploy({'from':accounts[0]})
    stETH = Contract.from_abi('', Proxy_0_5.deploy(stETH, {'from':accounts[0]}), SwapsImplstETH_ETH.abi)
    stETH.setSwapApprovals([], {'from':accounts[0]})
    interface.IWeth(WETH).deposit({'from':accounts[0],'value': 1e18})
    interface.IERC20(WETH).transfer(stETH, 1e18, {'from':accounts[0]})
    print(interface.IERC20(WETH).balanceOf(stETH))
    stETH.dexSwap(WETH, wstETH, accounts[0], accounts[0], 1e18, 0, 0, b'', {'from':accounts[0]})
    assert(interface.IERC20(wstETH).balanceOf(accounts[0]) > 0)
    interface.IERC20(wstETH).transfer(stETH, interface.IERC20(wstETH).balanceOf(accounts[0]), {'from':accounts[0]})
    stETH.dexSwap(wstETH, WETH, accounts[0], accounts[0], interface.IERC20(wstETH).balanceOf(stETH), 0, 0, encode_abi(['uint256','address','address'],[int(1e17),wstETH,WETH]), {'from':accounts[0]})
    assert(interface.IERC20(WETH).balanceOf(accounts[0]) > 0)