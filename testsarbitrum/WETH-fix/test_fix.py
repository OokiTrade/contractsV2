from brownie import *

def test_t():
    BZX = interface.IBZx('0x37407F3178ffE07a6cF5C847F8f680FEcf319FAB')
    RECV = receiver.deploy({'from':BZX.owner()})
    BZX.replaceContract(RECV, {'from':BZX.owner()})
    closings = LoanClosings.deploy({'from':accounts[0]})
    openings = LoanOpenings.deploy({'from':accounts[0]})
    maintenance= LoanMaintenance.deploy({'from':accounts[0]})
    BZX.replaceContract(closings,{'from':BZX.owner()})
    BZX.replaceContract(openings,{'from':BZX.owner()})
    BZX.replaceContract(maintenance,{'from':BZX.owner()})
    iUSDC = interface.IToken('0xEDa7f294844808B7C93EE524F990cA7792AC2aBd')
    ETH = '0x82aF49447D8a07e3bd95BD0d56f35241523fBab1'
    interface.IERC20(ETH).transfer(accounts[0],2e18,{'from':'0x0c1cf6883efa1b496b01f654e247b9b419873054'})
    interface.IERC20(ETH).approve(iUSDC,2e18,{'from':accounts[0]})
    datas = iUSDC.marginTrade(0,1e18,0,1e18,ETH,accounts[0],b'',{'from':accounts[0]}).return_value
    BZX.closeWithSwap(datas[0],accounts[0],1e18,True,b'',{'from':accounts[0]})

