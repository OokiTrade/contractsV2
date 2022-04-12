from brownie import *
from eth_abi import encode_abi

def test_runs():
    set_pricefeed()
    deploy_protocol()
    trade_open()
def set_pricefeed():
    BZX = interface.IBZx('0x059D60a9CEfBc70b9Ea9FFBb9a041581B1dFA6a8')
    OOKI = '0xCd150B1F528F326f5194c012f32Eb30135C7C2c9'
    ooki_p = OOKIPriceFeed.deploy({'from':accounts[0]})
    Contract.from_abi('',BZX.priceFeeds.call(),PriceFeeds.abi).setPriceFeed(
        [OOKI],[ooki_p],{'from':BZX.owner()})

def deploy_protocol():
    BZX = interface.IBZx('0x059D60a9CEfBc70b9Ea9FFBb9a041581B1dFA6a8')
    loanMaintenance = LoanMaintenance.deploy({"from": accounts[0], "gas_price": Wei("0.5 gwei")})
    loanMaintenance_2 = LoanMaintenance_2.deploy({"from": accounts[0], "gas_price": Wei("0.5 gwei")})
    loanOpenings = LoanOpenings.deploy({"from": accounts[0], "gas_price": Wei("0.5 gwei")})
    loanClosings = LoanClosings.deploy({"from": accounts[0], "gas_price": Wei("0.5 gwei")})
    loanSettings = LoanSettings.deploy({"from": accounts[0], "gas_price": Wei("0.5 gwei")})
    BZX.replaceContract(loanMaintenance, {"from": BZX.owner()})
    BZX.replaceContract(loanMaintenance_2, {"from": BZX.owner()})
    BZX.replaceContract(loanOpenings, {"from": BZX.owner()})
    BZX.replaceContract(loanClosings, {"from": BZX.owner()})
    BZX.replaceContract(loanSettings, {"from": BZX.owner()})
def trade_open():
    BZX = interface.IBZx('0x059D60a9CEfBc70b9Ea9FFBb9a041581B1dFA6a8')
    OOKI = '0xCd150B1F528F326f5194c012f32Eb30135C7C2c9'
    interface.IERC20(OOKI).approve(BZX, 20000000e18, {'from':accounts[0]})
    interface.IERC20(OOKI).transfer(accounts[0],200000e18, {'from':"0xa9ff08af55b24bb5d064d776a078e8a292b8dfe2"})
    bb = interface.IERC20(OOKI).balanceOf.call(accounts[0])
    print(bb)
    iUSDC = interface.IToken('0xC3f6816C860e7d7893508C8F8568d5AF190f6d7d')
    data = encode_abi(['uint128'],[8])
    trades = iUSDC.marginTrade(0,2e18,1000e6,0,"0x7ceB23fD6bC0adD59E62ac25578270cFf1b9f619",accounts[0],data,{'from':accounts[0]}).return_value
    assert(bb>interface.IERC20(OOKI).balanceOf.call(accounts[0]))
    bb = interface.IERC20(OOKI).balanceOf.call(accounts[0])
    print(bb)
    BZX.closeWithSwap(trades[0],accounts[0],1e15,True,data,{'from':accounts[0]})
    assert(bb>interface.IERC20(OOKI).balanceOf.call(accounts[0]))
    bb = interface.IERC20(OOKI).balanceOf.call(accounts[0])
    print(bb)
    BZX.closeWithSwap(trades[0],accounts[0],1e15,False,data,{'from':accounts[0]})
    assert(bb>interface.IERC20(OOKI).balanceOf.call(accounts[0]))