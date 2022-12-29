from brownie import *
from brownie import reverts
import pytest
from eth_abi import encode_abi

@pytest.fixture(scope="module")
def BZX(interface):
    return interface.IBZx("0x059D60a9CEfBc70b9Ea9FFBb9a041581B1dFA6a8")

@pytest.fixture(scope="module")
def stMATIC(interface):
    return interface.IERC20("0x3A58a54C066FdC0f2D55FC9C89F0415C92eBf3C4")

@pytest.fixture(scope="module")
def WMATIC(interface):
    return interface.IERC20("0x0d500B1d8E8eF31E21C99d1Db9A6444d3ADf1270")

def test_swaps(Contract, SwapsImplBalancer_POLYGON, DexRecords, BZX, stMATIC, WMATIC):

    bal = SwapsImplBalancer_POLYGON.deploy({"from":accounts[0]})

    DEX_RECORDS = Contract.from_abi("DEX_RECORDS",BZX.swapsImpl(),DexRecords.abi)
    DEX_RECORDS.setDexID(3,bal,{"from":DEX_RECORDS.owner()})

    poolID = bytes.fromhex("af5e0b5425de1f5a630a8cb5aa9d97b8141c908d000200000000000000000366")
    poolData = (poolID,0,1,int(5e17),b'')
    dex_payload = encode_abi(['(bytes32,uint256,uint256,uint256,bytes)[]','address[]','uint256[]'],[[poolData],[stMATIC.address, WMATIC.address], [0, 0]])
    selector_payload = encode_abi(['uint256','bytes'],[3,dex_payload])
    loanDataBytes = encode_abi(['uint128','bytes[]'],[2,[selector_payload]]) #flag value of Base-2: 10  

    stMATIC.transfer(accounts[0], 1e18, {"from":"0x765c6d09ef9223b1becd3b92a0ec01548d53cfba"})
    stMATIC.approve(BZX, 1e18, {"from":accounts[0]})
    BZX.swapExternal(stMATIC, WMATIC, accounts[0], accounts[0], 5e17, 5e17, loanDataBytes, {"from":accounts[0]}).return_value

    dex_payload = encode_abi(['(bytes32,uint256,uint256,uint256,bytes)[]','address[]','uint256[]'],[[poolData],[stMATIC.address, WMATIC.address], [100, 0]])
    selector_payload = encode_abi(['uint256','bytes'],[3,dex_payload])
    loanDataBytes = encode_abi(['uint128','bytes[]'],[2,[selector_payload]]) #flag value of Base-2: 10  

    with reverts("BAL#507"): #this should fail but shows that the max source token amount can be controlled by the user through the payload
        BZX.swapExternal(stMATIC, WMATIC, accounts[0], accounts[0], 5e17, 5e17, loanDataBytes, {"from":accounts[0]}).return_value