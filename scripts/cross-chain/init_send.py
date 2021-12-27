from brownie import *
from eth_abi import encode_abi, is_encodable, encode_single
from eth_abi.packed import encode_single_packed, encode_abi_packed
from hexbytes import HexBytes
def main(): #run first
    accounts.load('main3')
    logic = SendDataToPolygon.deploy({'from':accounts[0]})
    proxy = Proxy_0_8.deploy(logic.address,{'from':accounts[0]})
    send = Contract.from_abi('',proxy.address,SendDataToPolygon.abi)
    print(send.address)

def mainAddChildTunnel(): #run after deploying on mumbai
    accounts.load('main3')
    sendContract = '' #deployed root contract address
    send = Contract.from_abi('',sendContract,SendDataToPolygon.abi)
    send.setFxChildTunnel('',{'from':accounts[0]}) #input deployed child contract
def mainSendMessage(): #run to send messages
    accounts.load('main3')
    send = Contract.from_abi('','',SendDataToPolygon.abi) #input deployed root contract address
    ss = interface.IERC20('0x4fe9670ed85AC6BeaDC0cE1dec131F1e86E717C0').transfer.encode_input('0x4fe9670ed85AC6BeaDC0cE1dec131F1e86E717C0',0) #0 token transfer for random ERC20 to test if tx is executed
    msg = encode_abi(['(address[],uint[],string[],bytes[],uint)'],[(['0x06E72F187c68764d9969752Cc27E503c75Bd3657'],[0],[''],[HexBytes(ss)],1640567202)]) #formatted data
    send.sendMessageToChild(msg.hex(),{'from':accounts[0]})
