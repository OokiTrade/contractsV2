import pytest
from brownie import *
from eth_abi import encode_abi

@pytest.fixture(scope="module")
def BZX(accounts, interface, TickMathV1, LoanOpenings, LoanClosings, LoanSettings, Receiver, ProtocolSettings, LoanClosingsLiquidation, LoanMaintenance, LiquidationHelper, VolumeTracker):
    tickMathV1 = accounts[0].deploy(TickMathV1)
    liquidationHelper = accounts[0].deploy(LiquidationHelper)

    volumeTracker = accounts[0].deploy(VolumeTracker)
    lo = accounts[0].deploy(LoanOpenings)
    lc = accounts[0].deploy(LoanClosings)
    ls = accounts[0].deploy(LoanSettings)
    ps = accounts[0].deploy(ProtocolSettings)
    lcs = accounts[0].deploy(LoanClosingsLiquidation)
    lm = accounts[0].deploy(LoanMaintenance)

    bzx = Contract.from_abi("bzx", address="0xD8Ee69652E4e4838f2531732a46d1f7F584F0b7f", abi=interface.IBZx.abi)
    bzx.replaceContract(lo, {"from": bzx.owner()})
    bzx.replaceContract(ls, {"from": bzx.owner()})
    bzx.replaceContract(ps, {"from": bzx.owner()})
    bzx.replaceContract(lc, {"from": bzx.owner()})
    bzx.replaceContract(lcs, {"from": bzx.owner()})
    bzx.replaceContract(lm, {"from": bzx.owner()})
    bzx.replaceContract(accounts[0].deploy(Receiver), {"from":bzx.owner()})

    return bzx

@pytest.fixture(scope="module")
def WETH(TestToken):
    return Contract.from_abi("WETH", address="0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2", abi=TestToken.abi)

@pytest.fixture(scope="module")
def WSTETH(TestToken):
    return Contract.from_abi("WSTETH", address="0x7f39C581F595B53c5cb19bD0b3f8dA6c935E2Ca0", abi=TestToken.abi)

@pytest.fixture(scope="module")
def USDC(TestToken):
    return Contract.from_abi("USDC", address="0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48", abi=TestToken.abi)

@pytest.fixture(scope="module")
def iUSDC(accounts, interface, LoanTokenLogicStandard):
    itoken = Contract.from_abi("iUSDC", address="0x32E4c68B3A4a813b710595AebA7f6B7604Ab9c15", abi=interface.IToken.abi)
    itoken.setTarget(accounts[0].deploy(LoanTokenLogicStandard), {'from':itoken.owner()})
    return itoken

@pytest.fixture(scope="module")
def iETH(accounts, interface, LoanTokenLogicWeth):
    itoken = Contract.from_abi("iETH", address="0xB983E01458529665007fF7E0CDdeCDB74B967Eb6", abi=interface.IToken.abi)
    itoken.setTarget(accounts[0].deploy(LoanTokenLogicWeth), {'from':itoken.owner()})
    return itoken

@pytest.fixture(scope="module")
def PRICE_FEED(BZX, PriceFeeds):
    
    return Contract.from_abi("PRICE_FEED", BZX.priceFeeds(), abi = PriceFeeds.abi)

@pytest.fixture(scope="module")
def WSTETH_PRICE_FEED(PriceFeedwstETH):
    return accounts[0].deploy(PriceFeedwstETH)

@pytest.fixture(scope="module")
def GUARDIAN_MULTISIG():
    return "0x9B43a385E08EE3e4b402D4312dABD11296d09E93"

@pytest.fixture(scope="module")
def DEX_RECORDS(DexRecords):
    return Contract.from_abi('DEX_RECORDS','0x0D2caD590e0C2bEb141aC872aFd94fE17bEc3bFb',DexRecords.abi)

@pytest.fixture(scope="module")
def WSTETH_SWAP_IMPL(SwapsImplstETH_ETH):
    return accounts[0].deploy(SwapsImplstETH_ETH)

#test case 1. Add wstETH as collateral type then borrow against it
def test_case1(accounts, BZX, WSTETH_PRICE_FEED, WETH, iUSDC, USDC, WSTETH, PRICE_FEED, GUARDIAN_MULTISIG):
    #get some wstETH
    WSTETH.transfer(accounts[0], 10e18, {'from':'0x10cd5fbe1b404b7e19ef964b63939907bdaf42e2'})

    #add wstETH as collateral and add to price feed
    PRICE_FEED.setPriceFeed([WSTETH], [WSTETH_PRICE_FEED], {'from': PRICE_FEED.owner()})
    BZX.setSupportedTokens([WETH, WSTETH], [True, True], False, {'from': BZX.owner()})
    #set approval
    WSTETH.approve(iUSDC, 10e18, {'from':accounts[0]})

    #borrow
    iUSDC.borrow(0, 1000e6, 0, 10e18, WSTETH, accounts[0], accounts[0], b'', {'from':accounts[0]})

    assert(USDC.balanceOf(accounts[0]) == 1000e6)
    assert(WSTETH.balanceOf(accounts[0]) == 0)

#test case 2. trade test case where it uses Curve to open and close
def test_case2(accounts, BZX, DEX_RECORDS, WSTETH_PRICE_FEED, WSTETH_SWAP_IMPL, WETH, iETH, WSTETH, PRICE_FEED, GUARDIAN_MULTISIG):
    #add wstETH as collateral and add to price feed
    WSTETH_SWAP_IMPL_ID = 3
    DEX_RECORDS.setDexID(WSTETH_SWAP_IMPL_ID, WSTETH_SWAP_IMPL, {'from':DEX_RECORDS.owner()})
    PRICE_FEED.setPriceFeed([WSTETH], [WSTETH_PRICE_FEED], {'from': PRICE_FEED.owner()})
    BZX.setSupportedTokens([WETH, WSTETH], [True, True], True, {'from': BZX.owner()})
    BZX.modifyLoanParams([[BZX.generateLoanParamId(WETH,WSTETH,False),True,iETH,WETH,WSTETH,int(6.6667*1e18), int(5*1e18), 1]],{'from':BZX.owner()}) #set params for margin trading
    
    amountOfEthToTrade = 1*10**18
    FLAGS_DEX_SELECTOR_FLAG = 2
    LEAVERAGE = 15
    FEE = 0.1
    
    # minAmountOfStEthToReceive = WSTETH_SWAP_IMPL.dexAmountOutFormatted.call(encode_abi(['uint256',"address", "address"],[amountOfEthToTrade * LEAVERAGE, WETH.address, WSTETH.address]), amountOfEthToTrade * LEAVERAGE)
    dex_payload = encode_abi(['uint256',"address", "address"],[amountOfEthToTrade * LEAVERAGE, WETH.address, WSTETH.address])
    selector_payload = encode_abi(['uint256','bytes'],[WSTETH_SWAP_IMPL_ID, dex_payload]) # 
    loanDataBytes = encode_abi(['uint128','bytes[]'],[FLAGS_DEX_SELECTOR_FLAG, [selector_payload]]) #flag value of Base-2: 10, -> Flags_DEX_SELECTOR_FLAG
    minAmountOfStEthToReceive = BZX.getSwapExpectedReturn.call(accounts[0], WETH.address, WSTETH.address, amountOfEthToTrade * LEAVERAGE, loanDataBytes, True, {"from": accounts[0]})


    #prep data
    dex_payload = encode_abi(['uint256'],[minAmountOfStEthToReceive])
    selector_payload = encode_abi(['uint256','bytes'],[WSTETH_SWAP_IMPL_ID, dex_payload]) # 
    loanDataBytes = encode_abi(['uint128','bytes[]'],[FLAGS_DEX_SELECTOR_FLAG, [selector_payload]]) #flag value of Base-2: 10, -> Flags_DEX_SELECTOR_FLAG

    balanceBefore = WSTETH.balanceOf(BZX)
    #margin trade
    iETH.marginTrade(0, (LEAVERAGE-1)*1e18, amountOfEthToTrade, 0, WSTETH,accounts[0],loanDataBytes,{'from':accounts[0],'value':amountOfEthToTrade}) #15x position

    loanToAnalyze = BZX.getUserLoans(accounts[0],0,10,0,False,False)[0]

    assert(loanToAnalyze[4] == 14e18)
    assert(loanToAnalyze[5] >= 13e18)
    assert(WSTETH.balanceOf(BZX)-balanceBefore==loanToAnalyze[5])

    dex_payload = encode_abi(['uint256'],[loanToAnalyze[4]]) # in theory we need ot do getExpectedSwap return from loanToAnalyze[5] again and place it in here
    selector_payload = encode_abi(['uint256','bytes'],[3,dex_payload])
    loanDataBytes = encode_abi(['uint128','bytes[]'],[2,[selector_payload]]) #flag value of Base-2: 10    
    BZX.closeWithSwap(loanToAnalyze[0], accounts[0], loanToAnalyze[5], False, loanDataBytes, {'from':accounts[0]})

    # assert(BZX.getUserLoans(accounts[0],0,10,0,False,False)[0][0] != loanToAnalyze[0]) # loan already closed
    assert(BZX.getUserLoans(accounts[0],0,10,0,False,False) == ())
    print(WSTETH.balanceOf(BZX))
    print(WSTETH.balanceOf(BZX)-loanToAnalyze[5]*0.0015)
    assert(WSTETH.balanceOf(BZX)-loanToAnalyze[5]*0.0015-balanceBefore <= 10)
    assert(WSTETH.balanceOf(BZX)-loanToAnalyze[5]*0.0015-balanceBefore >= -10)

#test case 3. trade test case where it uses Lido to open and Curve to close. Is supposed to fail because of stETH not trading at 1 ETH
def fails_test_case3(accounts, BZX, DEX_RECORDS, WSTETH_PRICE_FEED, WSTETH_SWAP_IMPL, WETH, iETH, WSTETH, PRICE_FEED, GUARDIAN_MULTISIG):
    #add wstETH as collateral and add to price feed
    DEX_RECORDS.setDexID(WSTETH_SWAP_IMPL, {'from':DEX_RECORDS.owner()})
    PRICE_FEED.setPriceFeed([WSTETH], [WSTETH_PRICE_FEED], {'from': PRICE_FEED.owner()})
    BZX.setSupportedTokens([WETH, WSTETH], [True, True], True, {'from': GUARDIAN_MULTISIG})
    BZX.modifyLoanParams([[BZX.generateLoanParamId(WETH,WSTETH,False),True,iETH,WETH,WSTETH,int(6.6667*1e18), int(5*1e18), 1]],{'from':GUARDIAN_MULTISIG}) #set params for margin trading
    #prep data
    dex_payload = encode_abi(['uint256'],[0])
    selector_payload = encode_abi(['uint256','bytes'],[3,dex_payload])
    loanDataBytes = encode_abi(['uint128','bytes[]'],[2,[selector_payload]]) #flag value of Base-2: 10

    balanceBefore = WSTETH.balanceOf(BZX)
    #margin trade
    iETH.marginTrade(0,14e18,1e17,0,WSTETH,accounts[0],loanDataBytes,{'from':accounts[0],'value':1e17}) #15x position
    loanToAnalyze = BZX.getUserLoans(accounts[0],0,10,0,False,False)[0]

    assert(loanToAnalyze[4] == 14e17)
    assert(loanToAnalyze[5] >= 13e17)
    assert(WSTETH.balanceOf(BZX)-balanceBefore==loanToAnalyze[5])

    dex_payload = encode_abi(['uint256'],[int(loanToAnalyze[4])])
    selector_payload = encode_abi(['uint256','bytes'],[3,dex_payload])
    loanDataBytes = encode_abi(['uint128','bytes[]'],[2,[selector_payload]]) #flag value of Base-2: 10    
    BZX.closeWithSwap(loanToAnalyze[0], accounts[0], loanToAnalyze[5], False, loanDataBytes, {'from':accounts[0]})

    assert(BZX.getUserLoans(accounts[0],0,10,0,False,False)[0][0] != loanToAnalyze[0])
    assert(WSTETH.balanceOf(BZX)-loanToAnalyze[5]*0.9985 == balanceBefore)