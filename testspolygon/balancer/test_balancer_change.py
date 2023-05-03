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

@pytest.fixture(scope="module")
def USDC(interface):
    return interface.IERC20("0x2791Bca1f2de4661ED88A30C99A7a9449Aa84174")

@pytest.fixture(scope="module")
def PRICE_FEED(Contract, BZX, PriceFeeds):
    return Contract.from_abi("PRICE_FEED", BZX.priceFeeds(), PriceFeeds.abi)

@pytest.fixture(scope="module")
def iETH(accounts, interface, LoanTokenLogicWeth):
    itoken = Contract.from_abi("iETH", address="0xB8329B5458B1E493EFd8D9DA8C3B5E6D68e67C21", abi=interface.IToken.abi)
    return itoken

@pytest.fixture(scope="module")
def iMATIC(accounts, interface, LoanTokenLogicWeth):
    itoken = Contract.from_abi("iETH", address="0x81B91c9a68b94F88f3DFC4F375f101223dDd5007", abi=interface.IToken.abi)
    return itoken

def test_swaps(Contract, SwapsImplBalancer_POLYGON, DexRecords, BZX, stMATIC, WMATIC, USDC):

    bal = SwapsImplBalancer_POLYGON.deploy({"from":accounts[0]})

    DEX_RECORDS = Contract.from_abi("DEX_RECORDS",BZX.swapsImpl(),DexRecords.abi)
    DEX_RECORDS.setDexID(bal,{"from":DEX_RECORDS.owner()})

    poolID = bytes.fromhex("af5e0b5425de1f5a630a8cb5aa9d97b8141c908d000200000000000000000366")
    poolData = (poolID,0,1,int(5e17),b'')
    dex_payload = encode_abi(['(bytes32,uint256,uint256,uint256,bytes)[]','address[]','uint256[]'],[[poolData],[stMATIC.address, WMATIC.address], [0, 0]])
    selector_payload = encode_abi(['uint256','bytes'],[4,dex_payload])
    loanDataBytes = encode_abi(['uint128','bytes[]'],[2,[selector_payload]]) #flag value of Base-2: 10  

    stMATIC.transfer(accounts[0], 1e18, {"from":"0x765c6d09ef9223b1becd3b92a0ec01548d53cfba"})
    stMATIC.approve(BZX, 1e18, {"from":accounts[0]})
    BZX.swapExternal(stMATIC, WMATIC, accounts[0], accounts[0], 5e17, 5e17, loanDataBytes, {"from":accounts[0]}).return_value

    dex_payload = encode_abi(['(bytes32,uint256,uint256,uint256,bytes)[]','address[]','uint256[]'],[[poolData],[stMATIC.address, WMATIC.address], [100, 0]])
    selector_payload = encode_abi(['uint256','bytes'],[4,dex_payload])
    loanDataBytes = encode_abi(['uint128','bytes[]'],[2,[selector_payload]]) #flag value of Base-2: 10  

    with reverts("BAL#507"): #this should fail but shows that the max source token amount can be controlled by the user through the payload
        BZX.swapExternal(stMATIC, WMATIC, accounts[0], accounts[0], 5e17, 5e17, loanDataBytes, {"from":accounts[0]}).return_value

    dex_payload = encode_abi(['(bytes32,uint256,uint256,uint256,bytes)[]','address[]','uint256[]'],[[poolData],[stMATIC.address, WMATIC.address], [100, 1]])
    selector_payload = encode_abi(['uint256','bytes'],[4,dex_payload])
    loanDataBytes = encode_abi(['uint128','bytes[]'],[2,[selector_payload]]) #flag value of Base-2: 10  

    with reverts("cannot spend dest token"): #this should fail but shows that the max source token amount can be controlled by the user through the payload
        BZX.swapExternal(stMATIC, WMATIC, accounts[0], accounts[0], 5e17, 5e17, loanDataBytes, {"from":accounts[0]}).return_value

    dex_payload = encode_abi(['(bytes32,uint256,uint256,uint256,bytes)[]','address[]','uint256[]'],[[poolData],[stMATIC.address, USDC.address, WMATIC.address], [100, 1, 0]])
    selector_payload = encode_abi(['uint256','bytes'],[4,dex_payload])
    loanDataBytes = encode_abi(['uint128','bytes[]'],[2,[selector_payload]]) #flag value of Base-2: 10  

    with reverts("unsupported limit"): #this should fail but shows that the max source token amount can be controlled by the user through the payload
        BZX.swapExternal(stMATIC, WMATIC, accounts[0], accounts[0], 5e17, 5e17, loanDataBytes, {"from":accounts[0]}).return_value

#test case 2. trade test case where it uses Balancer to open and close
def test_case2(Contract, SwapsImplBalancer_POLYGON, DexRecords, BZX, stMATIC, WMATIC, USDC, PRICE_FEED, iMATIC):
    
    STMATIC_SWAP_IMPL = SwapsImplBalancer_POLYGON.deploy({"from":accounts[0]})
    STMATIC_SWAP_IMPL_ID = 4
    DEX_RECORDS = Contract.from_abi("DEX_RECORDS",BZX.swapsImpl(),DexRecords.abi)
    DEX_RECORDS.setDexID(STMATIC_SWAP_IMPL_ID, STMATIC_SWAP_IMPL, {'from':DEX_RECORDS.owner()})
    # PRICE_FEED.setPriceFeed([stMATIC], [WSTETH_PRICE_FEED], {'from': PRICE_FEED.owner()})
    # BZX.setSupportedTokens([WETH, WSTETH], [True, True], True, {'from': BZX.owner()})
    # BZX.modifyLoanParams([[BZX.generateLoanParamId(WETH,WSTETH,False),True,iETH,WETH,WSTETH,int(6.6667*1e18), int(5*1e18), 1]],{'from':BZX.owner()}) #set params for margin trading
    
    amountOfMATICToTrade = 1*10**18
    FLAGS_DEX_SELECTOR_FLAG = 2
    LEAVERAGE = 4
    FEE = 0.1
    
    # minAmountOfStEthToReceive = WSTETH_SWAP_IMPL.dexAmountOutFormatted.call(encode_abi(['uint256',"address", "address"],[amountOfMATICToTrade * LEAVERAGE, WETH.address, WSTETH.address]), amountOfMATICToTrade * LEAVERAGE)
    from enum import Enum
    # in every pool assets have a fixed index. index for an asset is changed from pool to pool
    class Assets(Enum):
        WMATIC = 0
        stMATIC = 1
        bstMATIC = 2
    
    poolId = bytes.fromhex("8159462d255c1d24915cb51ec361f700174cd99400000000000000000000075d")
    assetInIndex = Assets.WMATIC.value
    assetOutIndex = Assets.stMATIC.value
    amount = amountOfMATICToTrade
    userData = b''
    batchSwapStep = [(poolId, assetInIndex, assetOutIndex, amount, userData)]
    swapPath = [WMATIC.address, stMATIC.address]
    limits = [0, 0]
    dex_payload = encode_abi(['(bytes32,uint256,uint256,uint256,bytes)[]','address[]','uint256[]'],[batchSwapStep, swapPath, limits])
    selector_payload = encode_abi(['uint256','bytes'],[STMATIC_SWAP_IMPL_ID, dex_payload])
    loanDataBytes = encode_abi(['uint128','bytes[]'],[FLAGS_DEX_SELECTOR_FLAG, [selector_payload]]) #flag value of Base-2: 10, -> Flags_DEX_SELECTOR_FLAG

    minAmountOfStEthToReceive = BZX.getSwapExpectedReturn.call(accounts[0], WMATIC.address, stMATIC.address, amountOfMATICToTrade * LEAVERAGE, loanDataBytes, True, {"from": accounts[0]})


    #prep data


    balanceBefore = stMATIC.balanceOf(BZX)
    #margin trade
    iMATIC.marginTrade(0, (LEAVERAGE-1)*1e18, amountOfMATICToTrade, 0, stMATIC,accounts[0],loanDataBytes,{'from':accounts[0],'value':amountOfMATICToTrade}) #15x position

    loanToAnalyze = BZX.getUserLoans(accounts[0],0,10,0,False,False)[0]

    assert(loanToAnalyze[4] == (LEAVERAGE-1)*1e18)
    assert(loanToAnalyze[5] == minAmountOfStEthToReceive)
    assert(stMATIC.balanceOf(BZX)-balanceBefore==loanToAnalyze[5])



    poolId = bytes.fromhex("8159462d255c1d24915cb51ec361f700174cd99400000000000000000000075d")
    assetInIndex = Assets.stMATIC.value
    assetOutIndex = Assets.WMATIC.value
    amount = loanToAnalyze[5]
    userData = b''
    batchSwapStep = [(poolId, assetInIndex, assetOutIndex, amount, userData)]
    swapPath = [stMATIC.address, WMATIC.address]
    limits = [0, 0]
    dex_payload = encode_abi(['(bytes32,uint256,uint256,uint256,bytes)[]','address[]','uint256[]'],[batchSwapStep, swapPath, limits])
    selector_payload = encode_abi(['uint256','bytes'],[STMATIC_SWAP_IMPL_ID, dex_payload])
    loanDataBytes = encode_abi(['uint128','bytes[]'],[FLAGS_DEX_SELECTOR_FLAG, [selector_payload]]) #flag value of Base-2: 10, -> Flags_DEX_SELECTOR_FLAG


    BZX.closeWithSwap(loanToAnalyze[0], accounts[0], loanToAnalyze[5], False, loanDataBytes, {'from':accounts[0]})

    # assert(BZX.getUserLoans(accounts[0],0,10,0,False,False)[0][0] != loanToAnalyze[0]) # loan already closed
    assert(BZX.getUserLoans(accounts[0],0,10,0,False,False) == ())
    print(stMATIC.balanceOf(BZX))
    print(stMATIC.balanceOf(BZX)-loanToAnalyze[5]*0.0015)
    assert(stMATIC.balanceOf(BZX)-loanToAnalyze[5]*0.0015-balanceBefore <= 10)
    assert(stMATIC.balanceOf(BZX)-loanToAnalyze[5]*0.0015-balanceBefore >= -10)
    assert False