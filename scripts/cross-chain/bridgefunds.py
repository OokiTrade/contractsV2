from brownie import *

accounts.load('main3')

def main():
    ff = FeeExtractAndDistribute_Testnet.deploy({'from':accounts[0]})
    proxy = Proxy_0_8.deploy(ff.address,{'from':accounts[0]})
    proxy = Contract.from_abi('',proxy.address,FeeExtractAndDistribute_Testnet.abi)
    proxy.setTreasuryWallet(accounts[0],{'from':accounts[0]})
    proxy.setBridge('0x817cE38620eD33125Db3efBFd43d82E0d491d41e',{'from':accounts[0]})
    interface.IERC20('0xCe7F7c709E8c74D8ad069Ed28abF25ddC43b32a9').transfer(proxy.address,1e6,{'from':accounts[0]})
    proxy.setApprovals('0x817cE38620eD33125Db3efBFd43d82E0d491d41e','0xCe7F7c709E8c74D8ad069Ed28abF25ddC43b32a9',{'from':accounts[0]})
    print(proxy.bridge.call())
    print(proxy.treasuryWallet.call())
    print(interface.IERC20('0xCe7F7c709E8c74D8ad069Ed28abF25ddC43b32a9').balanceOf.call(proxy.address))
    proxy._bridgeFeesAndDistribute({'from':accounts[0]})
