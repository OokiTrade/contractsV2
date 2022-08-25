from brownie import *
import pytest
from eth_abi import encode_abi

@pytest.fixture(scope="module")
def BZX(interface):
    return interface.IBZx("0x059D60a9CEfBc70b9Ea9FFBb9a041581B1dFA6a8")

@pytest.fixture(scope="module")
def bStable(interface):
    return interface.IERC20("0xaF5E0B5425dE1F5a630A8cB5AA9D97B8141C908D")

@pytest.fixture(scope="module")
def stMATIC(interface):
    return interface.IERC20("0x3A58a54C066FdC0f2D55FC9C89F0415C92eBf3C4")

@pytest.fixture(scope="module")
def WMATIC(interface):
    return interface.IERC20("0x0d500B1d8E8eF31E21C99d1Db9A6444d3ADf1270")

@pytest.fixture(scope="module")
def PRICE_FEED(Contract, BZX, PriceFeeds):
    return Contract.from_abi("PRICE_FEED", BZX.priceFeeds(), PriceFeeds.abi)

@pytest.fixture(scope="module")
def B_STABLE_VAULT(accounts, bStablestMATICVault):
    vault = bStablestMATICVault.deploy({"from":accounts[0]})
    vault.setApprovals({"from":accounts[0]})
    return vault

@pytest.fixture(scope="module")
def DEX_RECORDS(Contract, DexRecords, BZX):
    return Contract.from_abi("DEX_RECORD",BZX.swapsImpl(), DexRecords.abi)

@pytest.fixture(scope="module")
def SET_SWAP_IMPL(accounts, BZX, DEX_RECORDS, SwapsImplBalancer_POLYGON, SwapsImplstMATICVault_POLYGON):
    bal = SwapsImplBalancer_POLYGON.deploy({"from":accounts[0]})
    DEX_RECORDS.setDexID(bal, {"from":DEX_RECORDS.owner()})

def test_cases():
    assert True
    #test_case1(accounts, PRICE_FEED, PriceFeedstMATIC, PriceFeedbStablestMATIC, bStable)
    #test_case2(accounts, bStablestMATICVault, bStable)

def test_case1(accounts, PRICE_FEED, PriceFeedstMATIC, PriceFeedbStablestMATIC, bStable, stMATIC, WMATIC):
    stMATICFeed = PriceFeedstMATIC.deploy({"from":accounts[0]})
    bStableFeed = PriceFeedbStablestMATIC.deploy({"from":accounts[0]})
    PRICE_FEED.setPriceFeed([stMATIC, bStable], [stMATICFeed, bStableFeed], {"from":PRICE_FEED.owner()})
    assert(PRICE_FEED.queryReturn(stMATIC, WMATIC, 1e18) > 1e18)
    assert(PRICE_FEED.queryReturn(bStable, WMATIC, 1e18) >= 1e18)

def test_case2(accounts, B_STABLE_VAULT, bStable, PRICE_FEED):
    PRICE_FEED.setPriceFeed(["0x9a71012B13CA4d3D0Cdc72A177DF3ef03b0E76A3"], ["0xd106b538f2a868c28ca1ec7e298c3325e0251d66"], {"from":PRICE_FEED.owner()})
    bStable.transfer(accounts[0], 100e18, {"from":"0x78d799be3fd3d96f0e024b9b35adb4479a9556f5"})
    bStable.approve(B_STABLE_VAULT, 100e18, {"from":accounts[0]})
    B_STABLE_VAULT.mint(50e18, accounts[0], {"from":accounts[0]})
    assert(B_STABLE_VAULT.balanceOf(accounts[0]) == 50e18)
    for i in range(10):
        chain.sleep(60000)
        chain.mine()
    B_STABLE_VAULT.deposit(50e18, accounts[0], {"from":accounts[0]})
    assert(B_STABLE_VAULT.convertToAssets(1e18) > 1e18)
    assert(B_STABLE_VAULT.balanceOf(accounts[0]) < 100e18)
    chain.sleep(600)
    chain.mine()
    assert(bStable.balanceOf(accounts[0]) == 0)
    assets = B_STABLE_VAULT.redeem(B_STABLE_VAULT.balanceOf(accounts[0]), accounts[0], accounts[0], {"from":accounts[0]}).return_value
    assert(B_STABLE_VAULT.balanceOf(accounts[0]) == 0) 
    assert(bStable.balanceOf(accounts[0]) == assets)

def test_case3(accounts, BZX, DEX_RECORDS, SET_SWAP_IMPL, stMATIC, WMATIC, PRICE_FEED):
    dexID = DEX_RECORDS.getDexCount()
    BZX.setSupportedTokens([stMATIC, WMATIC], [True, True], True, {"from":BZX.owner()})
    minAmountOut = int(PRICE_FEED.queryReturn(stMATIC, WMATIC, 1e18)*0.99)
    poolID = bytes.fromhex("af5e0b5425de1f5a630a8cb5aa9d97b8141c908d000200000000000000000366")
    poolData = (poolID,0,1,int(1e18),b'')
    dex_payload = encode_abi(['(bytes32,uint256,uint256,uint256,bytes)[]','address[]','uint256[]'],[[poolData],[stMATIC.address, WMATIC.address], [int(1e18), 0]])
    selector_payload = encode_abi(['uint256','bytes'],[dexID,dex_payload])
    loanDataBytes = encode_abi(['uint128','bytes[]'],[2,[selector_payload]]) #flag value of Base-2: 10  

    stMATIC.transfer(accounts[0], 1e18, {"from":"0x765c6d09ef9223b1becd3b92a0ec01548d53cfba"})
    stMATIC.approve(BZX, 1e18, {"from":accounts[0]})

    receivedAmount, usedAmount = BZX.swapExternal(stMATIC, WMATIC, accounts[0], accounts[0], 1e18, 1030212678534005222, loanDataBytes, {"from":accounts[0]}).return_value
    print(receivedAmount)
    assert(False)