#!/usr/bin/python3

import pytest
from brownie import ZERO_ADDRESS, network, Contract, reverts, chain
from brownie import Wei, reverts
from eth_abi import encode_abi, is_encodable, encode_single, is_encodable_type
from eth_abi.packed import encode_single_packed, encode_abi_packed
from hexbytes import HexBytes
import json
from eth_account import Account
from eth_account.messages import encode_structured_data
from eip712.messages import EIP712Message, EIP712Type
from brownie.network.account import LocalAccount
from brownie.convert.datatypes import *
from brownie import web3
from eth_abi import encode_abi


@pytest.fixture(scope="module")
def requireFork():
    assert (network.show_active() == "fork" or "fork" in network.show_active())


@pytest.fixture(autouse=True)
def isolation(fn_isolation):
    pass


@pytest.fixture(scope="module")
def BZX(accounts, interface, TickMathV1, LoanOpenings, LoanSettings, ProtocolSettings, LoanClosingsLiquidation, LoanMaintenance, LiquidationHelper, VolumeTracker, LoanClosings):
    # tickMathV1 = accounts[0].deploy(TickMathV1)
    # liquidationHelper = accounts[0].deploy(LiquidationHelper)
    # accounts[0].deploy(VolumeTracker)

    # lo = accounts[0].deploy(LoanOpenings)
    # lc = accounts[0].deploy(LoanClosings)
    # ls = accounts[0].deploy(LoanSettings)
    # ps = accounts[0].deploy(ProtocolSettings)
    # lcs = accounts[0].deploy(LoanClosingsLiquidation)
    # lm = accounts[0].deploy(LoanMaintenance)

    bzx = Contract.from_abi("bzx", address="0x37407F3178ffE07a6cF5C847F8f680FEcf319FAB", abi=interface.IBZx.abi)
    # bzx.replaceContract(lo, {"from": bzx.owner()})
    # bzx.replaceContract(lc, {"from": bzx.owner()})
    # bzx.replaceContract(ls, {"from": bzx.owner()})
    # bzx.replaceContract(ps, {"from": bzx.owner()})
    # bzx.replaceContract(lcs, {"from": bzx.owner()})
    # bzx.replaceContract(lm, {"from": bzx.owner()})

    return bzx


@pytest.fixture(scope="module")
def USDT(accounts, TestToken):
    return Contract.from_abi("USDT", address="0xFd086bC7CD5C481DCC9C85ebE478A1C0b69FCbb9", abi=TestToken.abi)

@pytest.fixture(scope="module")
def USDC(accounts, TestToken):
    return Contract.from_abi("USDC", address="0xFF970A61A04b1cA14834A43f5dE4533eBDDB5CC8", abi=TestToken.abi)

@pytest.fixture(scope="module")
def FRAX(accounts, TestToken):
    return Contract.from_abi("FRAX", address="0x17FC002b466eEc40DaE837Fc4bE5c67993ddBd6F", abi=TestToken.abi)

@pytest.fixture(scope="module")
def DAI(accounts, TestToken):
    return Contract.from_abi("DAI", address="0xDA10009cBd5D07dd0CeCc66161FC93D7c9000da1", abi=TestToken.abi)


@pytest.fixture(scope="module")
def WETH(accounts, TestToken):
    return Contract.from_abi("USDT", address="0x82aF49447D8a07e3bd95BD0d56f35241523fBab1", abi=TestToken.abi)

@pytest.fixture(scope="module")
def BTC(accounts, TestToken):
    return Contract.from_abi("USDT", address="0x2f2a2543B76A4166549F7aaB2e75Bef0aefC5B0f", abi=TestToken.abi)


@pytest.fixture(scope="module")
def iBTC(accounts, LoanTokenLogicStandard, interface, CurvedInterestRate, GUARDIAN_MULTISIG):
    return Contract.from_abi("iUSDT", address="0x4eBD7e71aFA27506EfA4a4783DFbFb0aD091701e", abi=interface.IToken.abi)


@pytest.fixture(scope="module")
def PRICE_FEED(interface, accounts, BZX, PriceFeeds, GUARDIAN_MULTISIG, WETH, REGISTRY, ITokenPriceFeedHelperV2_ARB, Crv2CryptoTokenPriceHelper_ARB, Crv3CryptoTokenPriceHelper_ARB, ATokenPriceHelper_ARB, SushiV2PriceFeedHelper_ETH, CrvwstETHCRVTokenPriceHelper_ARB):
    # TODO
    price_feed = PriceFeeds.deploy(WETH, {"from": accounts[0]})
    price_feed.changeGuardian(GUARDIAN_MULTISIG, {"from": accounts[0]})
    price_feed.transferOwnership(GUARDIAN_MULTISIG, {"from": accounts[0]})

    tokenList = []
    priceFeedList = []
    supportedTokenAssetsPairs = REGISTRY.getTokens(0, 100)
    # assert False
    old_price_feed = Contract.from_abi("PRICE_FEED", BZX.priceFeeds(), abi = PriceFeeds.abi)
    for l in supportedTokenAssetsPairs:
        tokenList.append(l[1])
        priceFeedList.append(old_price_feed.pricesFeeds(l[1]))
        
    price_feed.setPriceFeed(tokenList, priceFeedList, {"from": price_feed.owner()})

    
    # 1 set iToken price feed helpers
    ITokenPriceFeed = accounts[0].deploy(ITokenPriceFeedHelperV2_ARB);
    ITokenList = []
    priceFeedList = []
    for l in supportedTokenAssetsPairs:
        ITokenList.append(l[0])
        priceFeedList.append(ITokenPriceFeed)
    price_feed.setPriceFeedHelper(ITokenList, priceFeedList, {"from": price_feed.owner()})

    # 2 set Crv2Crypto price feed
    crv2CryptoPriceFeed = accounts[0].deploy(Crv2CryptoTokenPriceHelper_ARB);
    price_feed.setPriceFeedHelper(["0x7f90122BF0700F9E7e1F688fe926940E8839F353"], [crv2CryptoPriceFeed], {"from": price_feed.owner()})

    # 3 set Crv3Crypto price feed
    crv3CryptoPriceFeed = accounts[0].deploy(Crv3CryptoTokenPriceHelper_ARB);
    price_feed.setPriceFeedHelper(["0x8e0B8c8BB9db49a46697F3a5Bb8A308e744821D2"], [crv3CryptoPriceFeed], {"from": price_feed.owner()})

    # 4 set ATokens price feed
    ATokenPriceFeed = accounts[0].deploy(ATokenPriceHelper_ARB);
    aTokenList = ["0x82E64f49Ed5EC1bC6e43DAD4FC8Af9bb3A2312EE",
                "0x6d80113e533a2C0fe82EaBD35f1875DcEA89Ea97",
                "0x625E7708f30cA75bfd92586e17077590C60eb4cD",
                "0x6ab707Aca953eDAeFBc4fD23bA73294241490620",
                "0xf329e36C7bF6E5E86ce2150875a84Ce77f477375",
                "0x191c10Aa4AF7C30e871E70C95dB0E4eb77237530",
                "0x078f358208685046a11C85e8ad32895DED33A249",
                "0xe50fA9b3c56FfB159cB0FCA61F5c9D750e8128c8"]
    
    price_feed.setPriceFeedHelper(aTokenList, [ATokenPriceFeed] * len(aTokenList), {"from": price_feed.owner()})

    # 4 set SushiV2 price Feeds
    sushiV2PriceFeed = accounts[0].deploy(SushiV2PriceFeedHelper_ETH);
    factory = interface.IUniswapV2Factory("0xc35DADB65012eC5796536bD9864eD8773aBc74C4")
    lp_tokens = []
    for i in supportedTokenAssetsPairs:
        for j in supportedTokenAssetsPairs:
            lp_tokens.append(factory.getPair(i[1], j[1]))   
    lp_tokens = [a for a in lp_tokens if a not in ["0x0000000000000000000000000000000000000000"]]
    price_feed.setPriceFeedHelper(lp_tokens, [sushiV2PriceFeed] * len(lp_tokens), {"from": price_feed.owner()})
    BZX.setPriceFeedContract(price_feed, {"from": BZX.owner()})

    # 5 set CRV wstETHETH price Feeds
    crvwstETHCRVPriceFeed = accounts[0].deploy(CrvwstETHCRVTokenPriceHelper_ARB);
    price_feed.setPriceFeedHelper(["0xDbcD16e622c95AcB2650b38eC799f76BFC557a0b"], [crvwstETHCRVPriceFeed], {"from": price_feed.owner()})

    return Contract.from_abi("PRICE_FEED", BZX.priceFeeds(), abi = PriceFeeds.abi)


@pytest.fixture(scope="module")
def iUSDT(accounts, LoanTokenLogicStandard, interface, CurvedInterestRate, GUARDIAN_MULTISIG):
    return Contract.from_abi("iUSDT", address="0xd103a2D544fC02481795b0B33eb21DE430f3eD23", abi=interface.IToken.abi)

@pytest.fixture(scope="module")
def iFRAX(accounts, LoanTokenLogicStandard, interface, CurvedInterestRate, GUARDIAN_MULTISIG):
    return Contract.from_abi("iUSDT", address="0xC3f6816C860e7d7893508C8F8568d5AF190f6d7d", abi=interface.IToken.abi)


@pytest.fixture(scope="module")
def iUSDC(accounts, LoanTokenLogicStandard, interface, CurvedInterestRate, GUARDIAN_MULTISIG):
    return Contract.from_abi("iUSDC", address="0xEDa7f294844808B7C93EE524F990cA7792AC2aBd", abi=interface.IToken.abi)

@pytest.fixture(scope="module")
def iETH(accounts, LoanTokenLogicWeth, interface, CurvedInterestRate, GUARDIAN_MULTISIG):
    return Contract.from_abi("iUSDC", address="0xE602d108BCFbB7f8281Fd0835c3CF96e5c9B5486", abi=interface.IToken.abi)

@pytest.fixture(scope="module")
def GUARDIAN_MULTISIG():
    return "0x111F9F3e59e44e257b24C5d1De57E05c380C07D2"

@pytest.fixture(scope="module")
def REGISTRY(accounts, TokenRegistry):
    return Contract.from_abi("REGISTRY", address="0x86003099131d83944d826F8016E09CC678789A30",
                             abi=TokenRegistry.abi)

def test_case_itoken(accounts, PRICE_FEED, iUSDT, iUSDC, iETH, WETH, USDT, USDC, FRAX, iFRAX, BTC, iBTC, interface):
    # usdcHolder = "0x489ee077994b6658eafa855c308275ead8097c4a"
    # usdtHolder = "0xf89d7b9c864f589bbf53a82105107622b35eaa40"
    # wethHolder = "0x489ee077994b6658eafa855c308275ead8097c4a"
    # # iToken holder
    # # Crv2Crypto holder
    # # Crv3Crypto holder
    # # ATokens holder
    # # SushiV2 holder

    # USDC.transfer(accounts[0], 2000e6, {"from": usdcHolder})
    # USDT.transfer(accounts[0], 2000e6, {"from": usdtHolder})
    # WETH.transfer(accounts[0], 10e18, {"from": wethHolder})

    # USDC.approve(iUSDC, 2**256-1, {"from": accounts[0]})
    # USDT.approve(iUSDT, 2**256-1, {"from": accounts[0]})
    # WETH.approve(iETH, 2**256-1, {"from": accounts[0]})

    # iUSDC.mint(accounts[0], 1000e6, {"from": accounts[0]})
    # iUSDT.mint(accounts[0], 1000e6, {"from": accounts[0]})
    # iETH.mint(accounts[0], 5e18, {"from": accounts[0]})

    old_price_feed = interface.IPriceFeeds("0x392b7Baf9dBf56a0AcA52f0Ba8bC1D7451Ef8A4A")
    assert (old_price_feed.queryRate(USDT, iETH) == PRICE_FEED.queryRate(USDT, iETH))
    assert (old_price_feed.queryRate(USDT, iUSDT) == PRICE_FEED.queryRate(USDT, iUSDT))
    assert (old_price_feed.queryRate(USDT, iUSDC) == PRICE_FEED.queryRate(USDT, iUSDC))
    assert (old_price_feed.queryRate(USDT, iFRAX) == PRICE_FEED.queryRate(USDT, iFRAX))
    assert (old_price_feed.queryRate(USDT, iBTC) == PRICE_FEED.queryRate(USDT, iBTC))
    assert (old_price_feed.queryRate(USDT, BTC) == PRICE_FEED.queryRate(USDT, BTC))

    assert True


def test_case_crv2crypto(accounts, PRICE_FEED, iUSDT, iUSDC, iETH, WETH, USDT, USDC, FRAX, iFRAX, BTC, iBTC, interface, BZX):
    crv2cryptoHolder = "0xce5f24b7a95e9cba7df4b54e911b4a3dc8cdaf6f"
    CRV2CRYPTO = interface.ERC20("0x7f90122BF0700F9E7e1F688fe926940E8839F353")
    CRV2CRYPTO.transfer(accounts[0], 2000e18, {"from": crv2cryptoHolder})

    pf = interface.IPriceFeedHelper(PRICE_FEED.pricesHelpers(CRV2CRYPTO))
    USDT_PRICE_FEED = interface.IPriceFeedsExt("0x3f3f5dF88dC9F13eac63DF89EC16ef6e7E25DdE7")
    USDC_PRICE_FEED = interface.IPriceFeedsExt("0x50834F3163758fcC1Df9973b6e91f0F0F0434aD3")
    balanceUSD = USDT.balanceOf(CRV2CRYPTO) * USDT_PRICE_FEED.latestAnswer()/1e8
    balanceUSD += USDC.balanceOf(CRV2CRYPTO) * USDC_PRICE_FEED.latestAnswer()/1e8

    priceOfOneLP = balanceUSD * 1e18 *1e2 / CRV2CRYPTO.totalSupply()
    
    assert (int(priceOfOneLP) == pf.latestAnswer(CRV2CRYPTO))

    BZX.setSupportedTokens([CRV2CRYPTO], [True], False, {"from": BZX.owner()})
    CRV2CRYPTO.approve(iUSDT, 2**256-1, {"from": accounts[0]})

    iUSDT.borrow("", 50e6, 0, 60e18, CRV2CRYPTO, accounts[0], accounts[0], b"", {"from": accounts[0]})

    assert USDT.balanceOf(accounts[0]) == 50e6
    assert True


def test_case_crv3crypto(accounts, PRICE_FEED, iUSDT, iUSDC, iETH, WETH, USDT, USDC, FRAX, iFRAX, BTC, iBTC, interface, BZX):
    crv3cryptoHolder = "0xb67620E8C9E19592b616942F895153e2dcF9CcB6"
    CRV3CRYPTO = interface.ERC20("0x8e0B8c8BB9db49a46697F3a5Bb8A308e744821D2")
    CRV3CRYPTO.transfer(accounts[0], 45e18, {"from": crv3cryptoHolder})

    pf = interface.IPriceFeedHelper(PRICE_FEED.pricesHelpers(CRV3CRYPTO))
    
    USDT_PRICE_FEED = interface.IPriceFeedsExt("0x3f3f5dF88dC9F13eac63DF89EC16ef6e7E25DdE7")
    WETH_PRICE_FEED = interface.IPriceFeedsExt("0x639Fe6ab55C921f74e7fac1ee960C0B6293ba612")
    WBTC_PRICE_FEED = interface.IPriceFeedsExt("0x6ce185860a4963106506C203335A2910413708e9")
    
    CURVE_USD_BTC_ETH_POOL = "0x960ea3e3C7FB317332d990873d354E18d7645590";

    balanceUSD = USDT.balanceOf(CURVE_USD_BTC_ETH_POOL) * USDT_PRICE_FEED.latestAnswer()/1e8
    balanceUSD += WETH.balanceOf(CURVE_USD_BTC_ETH_POOL) * WETH_PRICE_FEED.latestAnswer()/1e20
    balanceUSD += BTC.balanceOf(CURVE_USD_BTC_ETH_POOL) * WBTC_PRICE_FEED.latestAnswer()/1e10

    priceOfOneLP = balanceUSD * 1e18 *1e2 / CRV3CRYPTO.totalSupply()
    
    assert (int(priceOfOneLP) == pf.latestAnswer(CRV3CRYPTO))

    BZX.setSupportedTokens([CRV3CRYPTO], [True], False, {"from": BZX.owner()})
    CRV3CRYPTO.approve(iUSDT, 2**256-1, {"from": accounts[0]})

    iUSDT.borrow("", 1000e6, 0, 1.1e18, CRV3CRYPTO, accounts[0], accounts[0], b"", {"from": accounts[0]})

    assert USDT.balanceOf(accounts[0]) == 1000e6
    assert True

def test_case_atoken(accounts, PRICE_FEED, iUSDT, iUSDC, iETH, WETH, USDT, USDC, FRAX, iFRAX, BTC, iBTC, interface, BZX):

    aDAIHolder = "0x42a49DcF7902C6B7938A00Cdbe62a112A2b539E8"
    aDAI =  interface.ERC20("0x82E64f49Ed5EC1bC6e43DAD4FC8Af9bb3A2312EE")
    DAI = interface.ERC20("0xDA10009cBd5D07dd0CeCc66161FC93D7c9000da1")
    
    aDAI.transfer(accounts[0], 2000e18, {"from": aDAIHolder})

    DAI_PRICE_FEED = interface.IPriceFeedsExt("0xc5C8E77B397E531B8EC06BFb0048328B30E9eCfB")

    # balanceUSD = DAI.balanceOf(aDAI) * DAI_PRICE_FEED.latestAnswer()/1e8
    # priceOfOneLP = (balanceUSD/1e18) / (aDAI.totalSupply()/1e18)

    # pool = interface.IPool("0x794a61358D6845594F94dc1DB02A252b5b4814aD")
    
    pf = interface.IPriceFeedHelper(PRICE_FEED.pricesHelpers(aDAI))
    assert pf.latestAnswer(aDAI) >= 101220487 # rate right now

    BZX.setSupportedTokens([aDAI], [True], False, {"from": BZX.owner()})
    aDAI.approve(iUSDT, 2**256-1, {"from": accounts[0]})
    iUSDT.borrow("", 1000e6, 0, 1200e18, aDAI, accounts[0], accounts[0], b"", {"from": accounts[0]})

    assert True

def test_case_shushiv2(accounts, PRICE_FEED, iUSDT, iUSDC, iETH, WETH, USDT, USDC, FRAX, iFRAX, BTC, iBTC, interface, BZX):
    ERUS = interface.ERC20("0xD22a58f79e9481D1a88e00c343885A588b34b68B")
    # AAVE = interface.IERC20("0xba5DdD1f9d7F570dc94a51479a000E3BCE967196")
    LINK = interface.ERC20("0xf97f4df75117a78c1A5a0DBb814Af92458539FB4")

    sushiLpHolder_USDT_WBTC = "0x42a49DcF7902C6B7938A00Cdbe62a112A2b539E8"
    sushiLpHolder_WETH_WBTC = "0xA5Ae03278e0533300779936293087FE8196BEe6A"
    sushiLpHolder_USDC_WETH = "0x2a2f17DB6F5A9dFf54CA0594046635978c4bD396"
    sushiLpHolder_USDC_LINK = "0x6f7875F5d325c6D9f9A1F04DE1B686fe36CFBc04"

    factory = interface.IUniswapV2Factory("0xc35DADB65012eC5796536bD9864eD8773aBc74C4")
    sushiLp_USDT_WBTC = interface.ERC20(factory.getPair(USDT, BTC))
    sushiLp_WETH_WBTC = interface.ERC20(factory.getPair(WETH, BTC))
    sushiLp_USDC_WETH = interface.ERC20(factory.getPair(USDC, WETH))
    sushiLp_USDC_LINK = interface.ERC20(factory.getPair(USDC, LINK))

    pf_USDT_WBTC = interface.IPriceFeedHelper(PRICE_FEED.pricesHelpers(sushiLp_USDT_WBTC))
    pf_WETH_WBTC = interface.IPriceFeedHelper(PRICE_FEED.pricesHelpers(sushiLp_WETH_WBTC))
    pf_USDC_WETH = interface.IPriceFeedHelper(PRICE_FEED.pricesHelpers(sushiLp_USDC_WETH))
    pf_USDC_LINK = interface.IPriceFeedHelper(PRICE_FEED.pricesHelpers(sushiLp_USDC_LINK))

    DAI_PRICE_FEED = interface.IPriceFeedsExt("0xc5C8E77B397E531B8EC06BFb0048328B30E9eCfB")
    ERUS_PRICE_FEED = interface.IPriceFeedsExt("0xA14d53bC1F1c0F31B4aA3BD109344E5009051a84") 
    USDC_PRICE_FEED = interface.IPriceFeedsExt("0x50834F3163758fcC1Df9973b6e91f0F0F0434aD3")
    USDT_PRICE_FEED = interface.IPriceFeedsExt("0x3f3f5dF88dC9F13eac63DF89EC16ef6e7E25DdE7")
    AAVE_PRICE_FEED = interface.IPriceFeedsExt("0xaD1d5344AaDE45F43E596773Bcc4c423EAbdD034")
    LINK_PRICE_FEED = interface.IPriceFeedsExt("0x86E53CF1B870786351Da77A57575e79CB55812CB")
    WBTC_PRICE_FEED = interface.IPriceFeedsExt("0xd0C7101eACbB49F3deCcCc166d238410D6D46d57") 
    WETH_PRICE_FEED = interface.IPriceFeedsExt("0x639Fe6ab55C921f74e7fac1ee960C0B6293ba612")

    # # priceOfOneLP_USDT_WBTC = pf_USDT_WBTC.latestAnswer(sushiLp_USDT_WBTC)
    # unipair = interface.IUniswapV2Pair(sushiLp_USDT_WBTC)
    # reserves = unipair.getReserves()
    # balanceUSD = reserves[1] * USDT_PRICE_FEED.latestAnswer()/1e6
    # balanceUSD += reserves[0] * WBTC_PRICE_FEED.latestAnswer()/1e8
    # priceOfOneLP = balanceUSD * 1e18 / sushiLp_USDT_WBTC.totalSupply()

    # assert abs(int(priceOfOneLP/1e8) -pf_USDT_WBTC.latestAnswer(sushiLp_USDT_WBTC)/1e8)< 1000

    priceOfOneLP_USDT_WBTC = calc_price(sushiLp_USDT_WBTC, USDT_PRICE_FEED, WBTC_PRICE_FEED, USDT, BTC, pf_USDT_WBTC)
    priceOfOneLP_WETH_WBTC = calc_price(sushiLp_WETH_WBTC, WETH_PRICE_FEED, WBTC_PRICE_FEED, WETH, BTC, pf_WETH_WBTC)
    priceOfOneLP_USDC_WETH = calc_price(sushiLp_USDC_WETH, USDC_PRICE_FEED, WETH_PRICE_FEED, USDC, WETH, pf_USDC_WETH)
    priceOfOneLP_USDC_LINK = calc_price(sushiLp_USDC_LINK, USDC_PRICE_FEED, LINK_PRICE_FEED, USDC, LINK, pf_USDC_LINK)

    assert abs(int(priceOfOneLP_USDT_WBTC/1e8) - int(pf_USDT_WBTC.latestAnswer(sushiLp_USDT_WBTC)/1e8))<= 2000
    assert abs(int(priceOfOneLP_WETH_WBTC/1e8) - int(pf_WETH_WBTC.latestAnswer(sushiLp_WETH_WBTC)/1e8))<= 0
    assert abs(int(priceOfOneLP_USDC_WETH/1e8) - int(pf_USDC_WETH.latestAnswer(sushiLp_USDC_WETH)/1e8))<= 0
    assert abs(int(priceOfOneLP_USDC_LINK/1e8) - int(pf_USDC_LINK.latestAnswer(sushiLp_USDC_LINK)/1e8))<= 0
    
    print(int(priceOfOneLP_USDT_WBTC/1e8), pf_USDT_WBTC.latestAnswer(sushiLp_USDT_WBTC)/1e8)
    print(int(priceOfOneLP_WETH_WBTC/1e8), pf_WETH_WBTC.latestAnswer(sushiLp_WETH_WBTC)/1e8)
    print(int(priceOfOneLP_USDC_WETH/1e8), pf_USDC_WETH.latestAnswer(sushiLp_USDC_WETH)/1e8)
    print(int(priceOfOneLP_USDC_LINK/1e8), pf_USDC_LINK.latestAnswer(sushiLp_USDC_LINK)/1e8)

    BZX.setSupportedTokens([sushiLp_USDT_WBTC, sushiLp_WETH_WBTC], [True, True], False, {"from": BZX.owner()})

    sushiLp_WETH_WBTC.transfer(accounts[0], sushiLp_WETH_WBTC.balanceOf(sushiLpHolder_WETH_WBTC), {"from": sushiLpHolder_WETH_WBTC})
    sushiLp_WETH_WBTC.approve(iUSDT, 2**256-1, {"from": accounts[0]})
    iUSDT.borrow("", 1000e6, 0, sushiLp_WETH_WBTC.balanceOf(accounts[0]), sushiLp_WETH_WBTC, accounts[0], accounts[0], b"", {"from": accounts[0]})

    assert True

def calc_price(sushiLp_USDT_WBTC, USDT_PRICE_FEED, WBTC_PRICE_FEED, USDT, BTC, pf_USDT_WBTC):

    # unipair = interface.IUniswapV2Pair(sushiLp_USDT_WBTC)
    # reserves = unipair.getReserves()
    balanceUSD = USDT.balanceOf(sushiLp_USDT_WBTC) * USDT_PRICE_FEED.latestAnswer()/10**(USDT.decimals())
    balanceUSD += BTC.balanceOf(sushiLp_USDT_WBTC) * WBTC_PRICE_FEED.latestAnswer()/10**(BTC.decimals())
    priceOfOneLP = balanceUSD * 1e18 / sushiLp_USDT_WBTC.totalSupply()

    # assert abs(int(priceOfOneLP/1e8) -pf_USDT_WBTC.latestAnswer(sushiLp_USDT_WBTC)/1e8)< 1000
    return priceOfOneLP


def test_case_crvwstETHCrypto(accounts, PRICE_FEED, iUSDT, iUSDC, iETH, WETH, USDT, USDC, FRAX, iFRAX, BTC, iBTC, interface, BZX):
    crvwstETHcryptoHolder = "0x51dA134F3d0F7A1D6C69b8d6F67205A7f889b5C0"
    WSTETHETHCRYPTO = interface.ERC20("0xDbcD16e622c95AcB2650b38eC799f76BFC557a0b")
    WSTETH = interface.ERC20("0x5979D7b546E38E414F7E9822514be443A4800529")
    WSTETHETHCRYPTO.transfer(accounts[0], 19e18, {"from": crvwstETHcryptoHolder})

    pf = interface.IPriceFeedHelper(PRICE_FEED.pricesHelpers(WSTETHETHCRYPTO))
    
    WETH_PRICE_FEED = interface.IPriceFeedsExt("0x639Fe6ab55C921f74e7fac1ee960C0B6293ba612")
    WSTETH_PRICE_FEED = interface.IPriceFeedsExt("0x07C5b924399cc23c24a95c8743DE4006a32b7f2a")
    
    CURVE_WSTETH_ETH_POOL = "0x6eB2dc694eB516B16Dc9FBc678C60052BbdD7d80"

    balanceUSD = web3.eth.getBalance(CURVE_WSTETH_ETH_POOL) * WETH_PRICE_FEED.latestAnswer()/1e20
    balanceUSD += WSTETH.balanceOf(CURVE_WSTETH_ETH_POOL) * WSTETH_PRICE_FEED.latestAnswer()/1e20

    priceOfOneLP = balanceUSD * 1e18 *1e2 / WSTETHETHCRYPTO.totalSupply()
    
    assert (int(priceOfOneLP) == pf.latestAnswer(WSTETHETHCRYPTO))

    BZX.setSupportedTokens([WSTETHETHCRYPTO], [True], False, {"from": BZX.owner()})
    WSTETHETHCRYPTO.approve(iUSDT, 2**256-1, {"from": accounts[0]})

    iUSDT.borrow("", 1400e6, 0, 1e18, WSTETHETHCRYPTO, accounts[0], accounts[0], b"", {"from": accounts[0]})

    assert USDT.balanceOf(accounts[0]) == 1400e6
    assert True