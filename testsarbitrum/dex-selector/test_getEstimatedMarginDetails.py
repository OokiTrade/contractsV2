from brownie import *
from eth_abi import encode_abi, is_encodable, encode_single
from eth_abi.packed import encode_single_packed, encode_abi_packed
from hexbytes import HexBytes

def test_main():
    BZX = interface.IBZx('0x37407F3178ffE07a6cF5C847F8f680FEcf319FAB')
    ow = BZX.owner.call()
    se = LoanOpenings.deploy({'from':ow})
    BZX.replaceContract(se.address, {'from':ow})

    route = encode_abi_packed(['address','uint24','address'],["0xFF970A61A04b1cA14834A43f5dE4533eBDDB5CC8",500,"0x82aF49447D8a07e3bd95BD0d56f35241523fBab1"])
    swap_payload = encode_abi(['(bytes,address,uint256,uint256,uint256)[]'],[[(route,BZX.address,1651719039,0,100)]])
    data_provided = encode_abi(['uint256','bytes'],[2,swap_payload])
    sendOut = encode_abi(['uint128','bytes[]'],[2,[data_provided]]) #flag value of Base-2: 10
    
    iUSDCv1 = Contract.from_abi('','0xEDa7f294844808B7C93EE524F990cA7792AC2aBd',LoanTokenLogicStandard.abi)
    l = LoanTokenLogicStandard.deploy(iUSDCv1.owner.call(), {'from':iUSDCv1.owner.call()})
    iUSDC = Contract.from_abi('',iUSDCv1.address,LoanToken.abi)
    iUSDC.setTarget(l.address, {'from':iUSDC.owner.call()})
    print(iUSDCv1.getEstimatedMarginDetails.call(3000000000000000000, 0, 1500000000000000000, "0xf97f4df75117a78c1a5a0dbb814af92458539fb4", b''))
    print(iUSDCv1.getEstimatedMarginDetails.call(3000000000000000000, 50e6, 0, "0x82aF49447D8a07e3bd95BD0d56f35241523fBab1", sendOut.hex()))
    assert(False)
