from brownie import *
from eth_abi import encode_abi, is_encodable, encode_single
from eth_abi.packed import encode_single_packed, encode_abi_packed
from hexbytes import HexBytes
import pytest
timelock = '0xfedC4dD5247B93feb41e899A09C44cFaBec29Cbc'
impersonate = '0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266'
trader = '0xE78388b4CE79068e89Bf8aA7f218eF6b9AB0e9d0'
Gas = 130e9
##def test_initialize(): #run this first and replace the contract address of PoolRegistry in SwapsImplCurve_ETH.sol then run test_main()
##    registration = CurvePoolRegistration.deploy({'from':impersonate,'gas_price':Gas})
##    registration.addPool('0xbEbc44782C7dB0a1A60Cb6fe97d0b483032FF1C7',1,{'from':impersonate,'gas_price':Gas})
##    print(registration.address) 
##    assert(False)

def test_main():
    mainState = Contract.from_abi("bZxProtocol","0xD8Ee69652E4e4838f2531732a46d1f7F584F0b7f",bZxProtocol.abi)
    dexSelector = DexRecords.deploy({'from':impersonate,'gas_price':Gas})
##    impl = SwapsImplCurve_ETH.deploy({'from':impersonate,'gas_price':Gas})
    impl2 = SwapsImplUniswapV2_ETH.deploy({'from':impersonate,'gas_price':Gas})
    impl3 = SwapsImplUniswapV3_ETH.deploy({'from':impersonate,'gas_price':Gas})
    dexSelector.setDexID(impl2.address,{'from':impersonate,'gas_price':Gas})
##    dexSelector.setDexID(impl.address,{'from':impersonate,'gas_price':Gas})
    dexSelector.setDexID(impl3.address,{'from':impersonate,'gas_price':Gas})
    web3.eth.sendTransaction({ "from": impersonate, "to": timelock, "value": str(1*10**18), "gas": "21000", 'gas_price':Gas }) #provide ETH for execs
    cc = ChangeSwapImpl.deploy({'from':impersonate,'gas_price':Gas})
    mainState.replaceContract(cc.address,{'from':timelock,'gas_price':Gas})
    changeImplProtocol = Contract.from_abi("Protocol","0xD8Ee69652E4e4838f2531732a46d1f7F584F0b7f",ChangeSwapImpl.abi)
    changeImplProtocol.changeImpl(dexSelector.address,{'from':timelock,'gas_price':Gas})
    loanClose = LoanClosings.deploy({'from':timelock,'gas_price':Gas})
    loanOpen = LoanOpenings.deploy({'from':timelock,'gas_price':Gas})
    mainState.replaceContract(loanClose.address,{'from':timelock,'gas_price':Gas})
    mainState.replaceContract(loanOpen.address,{'from':timelock,'gas_price':Gas})
    trade_univ2(mainState,dexSelector)
##    trade_curve(mainState,dexSelector)
    trade_univ3(mainState,dexSelector)
    assert(False)



def trade_curve(mainState,dexSelector):
    mainState = interface.IBZx(mainState.address)
    mainState.setTargets(["setSwapApprovals(address[])"],[dexSelector.dexes.call(2)],{'from':timelock,'gas_price':Gas})
    swaps1 = Contract.from_abi('Impl',mainState.address,SwapsImplCurve_ETH.abi)
    swaps1.setSwapApprovals(['0xbEbc44782C7dB0a1A60Cb6fe97d0b483032FF1C7','0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48','0xdac17f958d2ee523a2206206994597c13d831ec7'],{'from':timelock,'gas_price':Gas})
    swapImpl = Contract.from_abi("v3",dexSelector.retrieveDexAddress.call(2),SwapsImplCurve_ETH.abi)
    sendOut = encode_abi(['bytes4','address','uint128','uint128'],[HexBytes(swapImpl.ExchangeSig.call()),"0xbEbc44782C7dB0a1A60Cb6fe97d0b483032FF1C7",1,2])
    sendOut = encode_abi(['uint256','bytes'],[2,sendOut])
    iToken = Contract.from_abi('i','0x32E4c68B3A4a813b710595AebA7f6B7604Ab9c15',LoanTokenLogicStandard.abi)
    interface.IERC20('0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48').approve(iToken.address,1000000000000e6,{'from':trader,'gas_price':Gas})
    sendOut = encode_abi(['uint128','bytes[]'],[2,[sendOut]]) #flag value of Base-2: 10
    tradeReturn = iToken.marginTrade(0,2e18,100000e6,0,"0xdac17f958d2ee523a2206206994597c13d831ec7",trader,sendOut.hex(),{'from':trader,'gas_price':Gas}).return_value
    print(""+str(tradeReturn[1])+" "+str(tradeReturn[2])) #prints principal and collateral
    sendOut = encode_abi(['bytes4','address','uint128','uint128'],[HexBytes(swapImpl.ExchangeSig.call()),"0xbEbc44782C7dB0a1A60Cb6fe97d0b483032FF1C7",2,1])
    sendOut = encode_abi(['uint256','bytes'],[2,sendOut])
    sendOut = encode_abi(['uint128','bytes[]'],[2,[sendOut]]) #flag value of Base-2: 10
    mainState.closeWithSwap(tradeReturn[0],trader,10e6,True,sendOut.hex(),{'from':trader,'gas_price':Gas})


def trade_univ3(mainState,dexSelector):
    mainState = interface.IBZx(mainState.address)
    mainState.setTargets(["setSwapApprovals(address[])"],[dexSelector.dexes.call(2)],{'from':timelock,'gas_price':Gas})
    swaps1 = Contract.from_abi('Impl',mainState.address,SwapsImplUniswapV3_ETH.abi)
    swaps1.setSwapApprovals(['0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48','0xdac17f958d2ee523a2206206994597c13d831ec7'],{'from':timelock,'gas_price':Gas})
    route = encode_abi_packed(['address','uint24','address'],["0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48",500,"0xdAC17F958D2ee523a2206206994597C13D831ec7"])
    totalPassage = encode_abi(['(bytes,address,uint256,uint256,uint256)[]'],[[(route,mainState.address,1643224769,100,100)]])
    sendOut = encode_abi(['uint256','bytes'],[2,totalPassage])
    sendOut = encode_abi(['uint128','bytes[]'],[2,[sendOut]]) #flag value of Base-2: 10
    iToken = Contract.from_abi('i','0x32E4c68B3A4a813b710595AebA7f6B7604Ab9c15',LoanTokenLogicStandard.abi)
    
    tradeReturn = iToken.marginTrade(0,2e18,100000e6,0,"0xdAC17F958D2ee523a2206206994597C13D831ec7",trader,sendOut.hex(),{'from':trader,'gas_price':Gas}).return_value
    print(""+str(tradeReturn[1])+" "+str(tradeReturn[2])) #prints principal and collateral
    route = encode_abi_packed(['address','uint24','address'],["0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48",500,"0xdAC17F958D2ee523a2206206994597C13D831ec7"])
    totalPassage = encode_abi(['(bytes,address,uint256,uint256,uint256)[]'],[[(route,mainState.address,1643224769,100,100)]])
    sendOut = encode_abi(['uint256','bytes'],[2,totalPassage])
    sendOut = encode_abi(['uint128','bytes[]'],[2,[sendOut]]) #flag value of Base-2: 10
    mainState.closeWithSwap(tradeReturn[0],trader,10e6,True,sendOut.hex(),{'from':trader,'gas_price':Gas})

def trade_univ2(mainState,dexSelector):
    mainState = interface.IBZx(mainState.address)
    mainState.setTargets(["setSwapApprovals(address[])"],[dexSelector.dexes.call(1)],{'from':timelock,'gas_price':Gas})
    swaps1 = Contract.from_abi('Impl',mainState.address,SwapsImplUniswapV2_ETH.abi)
    swaps1.setSwapApprovals(['0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48','0xdac17f958d2ee523a2206206994597c13d831ec7'],{'from':timelock,'gas_price':Gas})
    iToken = Contract.from_abi('i','0x32E4c68B3A4a813b710595AebA7f6B7604Ab9c15',LoanTokenLogicStandard.abi)
    interface.IERC20('0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48').approve(iToken.address,1000000000000e6,{'from':trader,'gas_price':50e9})
    tradeReturn = iToken.marginTrade(0,2e18,100000e6,0,"0xdac17f958d2ee523a2206206994597c13d831ec7",trader,HexBytes(''),{'from':trader,'gas_price':Gas}).return_value
    print(""+str(tradeReturn[1])+" "+str(tradeReturn[2])) #prints principal and collateral
    mainState.closeWithSwap(tradeReturn[0],trader,10e6,True,HexBytes(''),{'from':trader,'gas_price':Gas})

        


    
    
