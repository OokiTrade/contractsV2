from brownie import *
import pytest
from eth_abi import encode_abi
def test_main():
    acc = '0xce2cc46682e9c6d5f174af598fb4931a9c0be68e'
    BZX = interface.IBZx('0x37407F3178ffE07a6cF5C847F8f680FEcf319FAB')
    bzx = Contract.from_abi('',BZX.address,bZxProtocol.abi)
    LoanOpening = LoanOpenings.deploy({'from':bzx.owner()})
    bzx.replaceContract(LoanOpening.address, {'from':bzx.owner()})
    delegateAddress = '0x539bdE0d7Dbd336b79148AA742883198BBF60342'
    payload = encode_abi(['uint128','bytes[]'],[4,[b'',encode_abi(['address'], [delegateAddress])]])
    USDC = '0xFF970A61A04b1cA14834A43f5dE4533eBDDB5CC8'
    iUSDC = interface.IToken('0xEDa7f294844808B7C93EE524F990cA7792AC2aBd')
    ETH = '0x82aF49447D8a07e3bd95BD0d56f35241523fBab1'
    interface.IERC20(USDC).approve(iUSDC.address, 1e6, {'from':acc})
    data = iUSDC.marginTrade(0,2e18,1e6,0,ETH,acc,payload, {'from':acc}).return_value
    print(data)
    assert(BZX.delegatedManagers(data[0], delegateAddress))