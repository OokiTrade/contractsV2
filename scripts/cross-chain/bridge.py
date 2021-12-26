from brownie import *

def main():
    accounts.load('main3')
    logic = BridgeCollectedFees.deploy({'from':accounts[0]})
    proxy = Proxy_0_8.deploy(logic.address,{'from':accounts[0]})
    BridgeContract = Contract.from_abi('bridging',proxy.address,BridgeCollectedFees.abi)
    hopExchange = '0x5C32143C8B198F392d01f8446b754c181224ac26'
    hopAddress = '0x76b22b8C1079A44F1211D867D68b1eda76a635A7'
    chain = 100
    recv = accounts[0]
    bondFee = 26e16
    maxSlippage = 1e18
    maxFee = 5*10**5
    minBridge = 6*10**5
    minBondFee = int(0.26e6)
    BridgeContract.initialize(hopExchange,hopAddress,chain,recv,bondFee,maxSlippage,maxFee,minBridge,minBondFee,{'from':accounts[0]})
    interface.IERC20('0x2791Bca1f2de4661ED88A30C99A7a9449Aa84174').transfer(BridgeContract.address,1e6,{'from':accounts[0]})
    BridgeContract.setApprovals('0x76b22b8C1079A44F1211D867D68b1eda76a635A7',3000e6,{'from':accounts[0]})
    BridgeContract.bridgeUSDC({'from':accounts[0]})
