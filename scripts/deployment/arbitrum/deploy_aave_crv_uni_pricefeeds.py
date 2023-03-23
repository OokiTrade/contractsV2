from brownie import *

exec(open("./scripts/env/set-arbitrum.py").read())
deployer = accounts[0]

price_feed_old = PRICE_FEED

price_feed = PriceFeeds.deploy(WETH, {"from": accounts[0]})
price_feed.changeGuardian(GUARDIAN_MULTISIG, {"from": accounts[0]})
price_feed.transferOwnership(GUARDIAN_MULTISIG, {"from": accounts[0]})

tokenList = []
priceFeedList = []
supportedTokenAssetsPairs = TOKEN_REGISTRY.getTokens(0, 100)


for l in supportedTokenAssetsPairs:
    tokenList.append(l[1])
    priceFeedList.append(price_feed_old.pricesFeeds(l[1]))
    
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


supportedTokens = []
supportedTokens.append("0x7f90122BF0700F9E7e1F688fe926940E8839F353")
supportedTokens.append("0x8e0B8c8BB9db49a46697F3a5Bb8A308e744821D2")
supportedTokens = supportedTokens + aTokenList
supportedTokens = supportedTokens + lp_tokens
supportedTokens.append("0xDbcD16e622c95AcB2650b38eC799f76BFC557a0b")

BZX.setPriceFeedContract(price_feed, {"from": GUARDIAN_MULTISIG})

BZX.setSupportedTokens(supportedTokens, [True] * len(supportedTokens), False, {"from": BZX.owner()})