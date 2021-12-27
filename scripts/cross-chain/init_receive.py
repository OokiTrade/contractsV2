from brownie import *

def main():
    accounts.load('main3')
    logic = ReceiveDataPolygon.deploy({'from':accounts[0]})
    proxy = Proxy_0_8.deploy(logic.address,{'from':accounts[0]})
    recv = Contract.from_abi('',proxy.address,ReceiveDataPolygon.abi)
    recv.setFxRootTunnel('',{'from':accounts[0]}) #set to deployed root contract address
