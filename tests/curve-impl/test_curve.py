from brownie import *
from eth_abi import encode_abi
def test_t():
    
    BZX = Contract.from_abi("BZX", "0x059D60a9CEfBc70b9Ea9FFBb9a041581B1dFA6a8", interface.IBZx.abi)
    pp = ProtocolSettings.deploy({'from':BZX.owner()})
    BZX.replaceContract(pp.address, {'from':BZX.owner()})
    cc = SwapsImplCurve_ETH.deploy({'from':BZX.owner()})
    interface.IDexRecords(BZX.swapsImpl.call()).setDexID(cc.address, {'from':BZX.owner()})
    BZX.setTokenApprovals(['0x2791Bca1f2de4661ED88A30C99A7a9449Aa84174','0xc2132D05D31c914a87C6611C10748AEb04B58e8F'],'0x04aAB3e45Aa6De7783D67FCfB21Bccf2401Ca31D',{'from':BZX.owner()})
    USDC = interface.IERC20('0x2791Bca1f2de4661ED88A30C99A7a9449Aa84174')
    iUSDC = interface.IToken('0xC3f6816C860e7d7893508C8F8568d5AF190f6d7d')
    USDC.transfer('0xAb43e4Ac216056611A92f6b7eaBFeaCe0ebD06E5',2000e6, {'from':'0xba12222222228d8ba445958a75a0704d566bf2c8'})
    USDC.approve(iUSDC.address,2000e6,{'from':'0xAb43e4Ac216056611A92f6b7eaBFeaCe0ebD06E5'})
    data = encode_abi(['address','address','address','uint256'], ['0x445FE580eF8d70FF569aB36e80c647af338db351','0x2791Bca1f2de4661ED88A30C99A7a9449Aa84174','0xc2132D05D31c914a87C6611C10748AEb04B58e8F',1])
    data = encode_abi(['uint256','bytes'],[3,data])
    data = encode_abi(['uint128','bytes[]'],[2,[data]])
    iUSDC.marginTrade(0,2e18,1000e6,0,'0xc2132D05D31c914a87C6611C10748AEb04B58e8F','0xAb43e4Ac216056611A92f6b7eaBFeaCe0ebD06E5',data,{'from':'0xAb43e4Ac216056611A92f6b7eaBFeaCe0ebD06E5'})
    loan = BZX.getUserLoans.call('0xAb43e4Ac216056611A92f6b7eaBFeaCe0ebD06E5',0,10,0,False,False)[0]
    print(loan)
    data = encode_abi(['address','address','address','uint256'], ['0x445FE580eF8d70FF569aB36e80c647af338db351','0xc2132D05D31c914a87C6611C10748AEb04B58e8F','0x2791Bca1f2de4661ED88A30C99A7a9449Aa84174',1])
    data = encode_abi(['uint256','bytes'],[3,data])
    data = encode_abi(['uint128','bytes[]'],[2,[data]])
    BZX.closeWithSwap(loan[0],'0xAb43e4Ac216056611A92f6b7eaBFeaCe0ebD06E5',int(loan[5]/2.5),False,data,{'from':'0xAb43e4Ac216056611A92f6b7eaBFeaCe0ebD06E5'})
    data = encode_abi(['address','address','address','uint256'], ['0x445FE580eF8d70FF569aB36e80c647af338db351','0xc2132D05D31c914a87C6611C10748AEb04B58e8F','0x2791Bca1f2de4661ED88A30C99A7a9449Aa84174',int(loan[5]/2.3)])
    data = encode_abi(['uint256','bytes'],[3,data])
    data = encode_abi(['uint128','bytes[]'],[2,[data]])
    BZX.closeWithSwap(loan[0],'0xAb43e4Ac216056611A92f6b7eaBFeaCe0ebD06E5',int(loan[5]/2.5),True,data,{'from':'0xAb43e4Ac216056611A92f6b7eaBFeaCe0ebD06E5'})
    loan = BZX.getUserLoans.call('0xAb43e4Ac216056611A92f6b7eaBFeaCe0ebD06E5',0,10,0,False,False)[0]
    print(loan)
    assert(False)