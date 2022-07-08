import pytest
from brownie import *
from eth_abi import encode_abi, is_encodable, encode_single

@pytest.fixture(scope="module")
def BZX(accounts, interface, TickMathV1, LoanOpenings, LoanSettings, ProtocolSettings, LoanClosingsLiquidation, LoanMaintenance, LiquidationHelper, VolumeTracker, VolumeDelta):
    accounts[0].deploy(TickMathV1)
    accounts[0].deploy(LiquidationHelper)
    accounts[0].deploy(VolumeTracker)
    lo = accounts[0].deploy(LoanOpenings)
    ls = accounts[0].deploy(LoanSettings)
    ps = accounts[0].deploy(ProtocolSettings)
    lcs = accounts[0].deploy(LoanClosingsLiquidation)
    lm = accounts[0].deploy(LoanMaintenance)
    vd = accounts[0].deploy(VolumeDelta)
    bzx = Contract.from_abi("bzx", address="0x059D60a9CEfBc70b9Ea9FFBb9a041581B1dFA6a8", abi=interface.IBZx.abi)
    bzx.replaceContract(lo, {"from": bzx.owner()})
    bzx.replaceContract(ls, {"from": bzx.owner()})
    bzx.replaceContract(ps, {"from": bzx.owner()})
    bzx.replaceContract(lcs, {"from": bzx.owner()})
    bzx.replaceContract(lm, {"from": bzx.owner()})
    bzx.replaceContract(vd, {"from": bzx.owner()})
    return bzx

@pytest.fixture(scope="module")
def GUARDIAN_MULTISIG():
    return "0x01F569df8A270eCA78597aFe97D30c65D8a8ca80"

@pytest.fixture(scope="module")
def REGISTRY(TokenRegistry):
    return Contract.from_abi("REGISTRY", address="0x4B234781Af34E9fD756C27a47675cbba19DC8765",
                             abi=TokenRegistry.abi)

@pytest.fixture(scope="module")
def migrate_params(BZX, REGISTRY, GUARDIAN_MULTISIG):
    supportedTokenAssetsPairs = REGISTRY.getTokens(0, 100)
    for assetPair in supportedTokenAssetsPairs:
        BZX.migrateLoanParamsList(assetPair[0], 0, 100, {"from": GUARDIAN_MULTISIG})

@pytest.fixture(scope="module")
def USDC(TestToken):
    return Contract.from_abi("USDC", address="0x2791Bca1f2de4661ED88A30C99A7a9449Aa84174", abi=TestToken.abi)

@pytest.fixture(scope="module")
def ETH(TestToken):
    return Contract.from_abi("USDC", address="0x7ceB23fD6bC0adD59E62ac25578270cFf1b9f619", abi=TestToken.abi)


@pytest.fixture(scope="module")
def IUSDC(accounts, LoanTokenLogicStandard, interface):
    itokenImpl = accounts[0].deploy(LoanTokenLogicStandard)
    itoken = Contract.from_abi("IUSDC", address="0xC3f6816C860e7d7893508C8F8568d5AF190f6d7d", abi=interface.IToken.abi)
    itoken.setTarget(itokenImpl, {"from": itoken.owner()})
    itoken.initializeDomainSeparator({"from": itoken.owner()})
    return itoken

def test_main(BZX, migrate_params, USDC, IUSDC, ETH):
    USDC.transfer(accounts[0],1000e6,{'from':'0xf977814e90da44bfa03b6295a0616a897441acec'})
    USDC.approve('0x059D60a9CEfBc70b9Ea9FFBb9a041581B1dFA6a8',1000e6,{'from':accounts[0]})
    USDC.approve('0xC3f6816C860e7d7893508C8F8568d5AF190f6d7d',1000e6,{'from':accounts[0]})
    mainPayloadNormal = [0,[]]
    selector_payload = encode_abi(['uint256','bytes'],[1,encode_abi(['address','address'],[USDC.address,ETH.address])])
    mainPayloadNormal[0] += 2
    mainPayloadNormal[1].append(selector_payload)
    mainPayloadNormal[0] += 32
    mainPayload = encode_abi(['uint128','bytes[]'],mainPayloadNormal)
    IUSDC.marginTrade(0,1e18,1e6,0,ETH.address,accounts[0],mainPayload,{'from':accounts[0]})
    chain.sleep(10)
    chain.mine()
    assert(2e6*0.9985==BZX.retrieveTradedVolume(accounts[0],chain.time()-30,chain.time())) #compares trade volume. volume traded is fee exclusive
    chain.sleep(600)
    chain.mine()
    IUSDC.marginTrade(0,1e18,1e6,0,ETH.address,accounts[0],mainPayload,{'from':accounts[0]})
    chain.sleep(10)
    chain.mine()
    assert(0==BZX.retrieveTradedVolume(accounts[0],chain.time()-30,chain.time())) #no volume should be attributed as it is stored based on the day as it sacrifices granularity for more data
    assert(4e6*0.9985==BZX.retrieveTradedVolume(accounts[0],chain.time()-800,chain.time())) #compares trade volume. volume traded is fee exclusive
